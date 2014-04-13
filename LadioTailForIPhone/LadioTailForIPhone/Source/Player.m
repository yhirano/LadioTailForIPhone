/*
 * Copyright (c) 2012-2014 Yuichi Hirano
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "LadioTailConfig.h"
#import "Player.h"

/// 停止する理由
typedef NS_ENUM(NSInteger, StopReason)
{
    StopReasonUser,
    StopReasonAnotherUrlPlay,
    StopReasonPlayTimeOut,
    StopReasonDidPlayToEndTime,
    StopReasonFailedToPlayToEndTime,
    StopReasonStatusFailed,
    StopReasonInterruption,
};

@interface Player () <AVAudioSessionDelegate>

@end

@implementation Player
{
    // Player
    AVPlayer *player_;
    // 再生状態
    PlayerState state_;
    // 再生中のURL
    NSURL *playUrl_;
    // 再生中の番組
    Channel *playChannel_;
    // 再生開始タイムアウト監視タイマー
    NSTimer *playTimeOutTimer_;
}

+ (Player *)sharedInstance
{
    static Player *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[Player alloc] init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        @synchronized (self) {
            state_ = PlayerStateIdle;
        }

        // オーディオセッションを生成
        // バックグラウンド再生用
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [[AVAudioSession sharedInstance] setDelegate:self];
        NSError *setCategoryError = nil;
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
        if (setCategoryError) {
            NSLog(@"Audio session setCategory error.");
        }

        // 再生が終端ないしエラーで終了した際に通知を受け取り、状態を変更する
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stoppedDidPlayToEndTime:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stoppedFailedToPlayToEndTime:)
                                                     name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [self stop];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                  object:nil];
}

- (void)play
{
    @synchronized (self) {
        switch (state_) {
            case PlayerStateIdle:
                if (playUrl_ != nil) {
                    [self playProc:playUrl_ channel:playChannel_];
                }
                break;
            case PlayerStatePrepare:
            case PlayerStatePlay:
            default:
                break;
        }
    }
}

- (void)play:(NSURL *)url
{
    @synchronized (self) {
        // 既に再生中のURLとおなじ場合は何もしない
        if ([self isPlaying:url]) {
            return;
        }

        switch (state_) {
            case PlayerStatePlay:
                // 再生中は停止
                [self stopProcWithReason:StopReasonAnotherUrlPlay];
                // 再生を開始するためここは下にスルー
            case PlayerStateIdle:
                // 再生開始
                [self playProc:url];
                break;
            case PlayerStatePrepare:
            default:
                break;
        }
    }
}

- (void)playChannel:(Channel *)channel
{
    @synchronized (self) {
        // 既に再生中のURLとおなじ場合は何もしない
        NSURL *url;
#if defined(LADIO_TAIL)
        url = channel.playUrl;
#elif defined(RADIO_EDGE)
        url = channel.listenUrl;
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif
        if ([self isPlaying:url]) {
            return;
        }

        switch (state_) {
            case PlayerStatePlay:
                // 再生中は停止
                [self stopProcWithReason:StopReasonAnotherUrlPlay];
                // 再生を開始するためここは下にスルー
            case PlayerStateIdle:
                // 再生開始
                [self playProc:url channel:channel];
                break;
            case PlayerStatePrepare:
            default:
                break;
        }
    }
}

- (void)stop
{
    @synchronized (self) {
        switch (state_) {
            case PlayerStatePrepare:
            case PlayerStatePlay:
                [self stopProcWithReason:StopReasonUser];
                break;
            case PlayerStateIdle:
            default:
                break;
        }
    }
}

- (void)switchPlayStop
{
    switch ([self state]) {
        case PlayerStateIdle:
            [self play];
            break;
        case PlayerStatePlay:
            [self stop];
            break;
        case PlayerStatePrepare: // 再生準備中の場合は何もしない
        default:
            break;
    }
}

- (BOOL)isPlaying:(NSURL *)url
{
    NSURL *playingUrl;
    @synchronized (self) {
        playingUrl = [self playingUrl];
    }

    if (playingUrl != nil) {
        return [[playingUrl absoluteString] isEqualToString:[url absoluteString]];
    } else {
        return NO;
    }
}

- (BOOL)isPreparing:(NSURL *)url
{
    NSURL *preparingUrl;
    @synchronized (self) {
        preparingUrl = [self preparingUrl];
    }
    
    if (preparingUrl != nil) {
        return [[preparingUrl absoluteString] isEqualToString:[url absoluteString]];
    } else {
        return NO;
    }
}

- (PlayerState)state
{
    @synchronized (self) {
        return state_;
    }
}

- (NSURL *)playingUrl
{
    @synchronized (self) {
        switch (state_) {
            case PlayerStatePlay:
                return playUrl_;
            case PlayerStateIdle:
            case PlayerStatePrepare:
            default:
                return nil;
        }
    }
}

- (Channel *)playingChannel
{
    @synchronized (self) {
        switch (state_) {
            case PlayerStatePlay:
                return playChannel_;
            case PlayerStateIdle:
            case PlayerStatePrepare:
            default:
                return nil;
        }
    }
}

- (NSURL *)preparingUrl
{
    @synchronized (self) {
        switch (state_) {
            case PlayerStatePrepare:
                return playUrl_;
            case PlayerStateIdle:
            case PlayerStatePlay:
            default:
                return nil;
        }
    }
}

- (Channel *)preparingChannel
{
    @synchronized (self) {
        switch (state_) {
            case PlayerStatePrepare:
                return playChannel_;
            case PlayerStateIdle:
            case PlayerStatePlay:
            default:
                return nil;
        }
    }
}

#pragma mark - Private methods

/// AudioSessionを有効化する
- (void)acviveAudioSession
{
    NSLog(@"Active audio session.");
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *setActiveError = nil;
    [audioSession setActive:YES error:&setActiveError];
    if (setActiveError) {
        NSLog(@"Audio session setActive error.");
    }
}

/// AudioSessionを無効化する
- (void)deacviveAudioSession
{
    NSLog(@"Deactive audio session.");
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *setActiveError = nil;
    [audioSession setActive:NO error:&setActiveError];
    if (setActiveError) {
        NSLog(@"Audio session setActive error.");
    }
}

/// 再生処理
- (void)playProc:(NSURL *)url
{
    [self playProc:url channel:nil];
}

- (void)playProc:(NSURL *)url channel:(Channel *)channel
{
    // URLが空の場合は何もしない
    if (url == nil) {
        return;
    }

    state_ = PlayerStatePrepare;
    playUrl_ = url;
    playChannel_ = channel;
    NSLog(@"Play start %@", [playUrl_ absoluteString]);
    [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailPlayerPrepareNotification object:self];
    [self acviveAudioSession];
    player_ = [AVPlayer playerWithURL:url];
    player_.allowsExternalPlayback = NO; // VideoをAirPlayしない場合はNOにしてしまった方がいいらしい
    [player_ addObserver:self forKeyPath:@"status" options:0 context:nil];
    [player_ play];
    
    // 再生タイムアウトを監視する
    if (playTimeOutTimer_ != nil) {
        // 再生タイムアウトタイマーが走っている場合は止める
        [playTimeOutTimer_ invalidate];
#if DEBUG
        NSLog(@"Play time out timer invalidate.");
#endif /* #if DEBUG */
    }
    playTimeOutTimer_ = [NSTimer scheduledTimerWithTimeInterval:PLAY_TIMEOUT_SEC
                                                         target:self
                                                       selector:@selector(playTimeOut:)
                                                       userInfo:nil
                                                        repeats:NO];
#if DEBUG
    NSLog(@"Play time out timer started.");
#endif /* #if DEBUG */
}

/// 再生開始後処理
- (void)playStartedProc
{
    state_ = PlayerStatePlay;
    NSLog(@"Play started.");
    
    // 再生タイムアウトのタイマーが走っている場合は止める
    if (playTimeOutTimer_ != nil) {
        [playTimeOutTimer_ invalidate];
        playTimeOutTimer_ = nil;
#if DEBUG
        NSLog(@"Play time out timer invalidate.");
#endif /* #if DEBUG */
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailPlayerDidPlayNotification
                                                        object:self];
}

/// 停止処理
- (void)stopProcWithReason:(StopReason)reason
{
    [player_ pause];
    [player_ removeObserver:self forKeyPath:@"status"];
    // ユーザーが停止した場合以外はURLと番組を残さない
    if (reason != StopReasonUser) {
        playUrl_ = nil;
        playChannel_ = nil;
    }

    state_ = PlayerStateIdle;
    switch (reason) {
        case StopReasonUser:
            NSLog(@"Play stopped by user.");
            break;
        case StopReasonAnotherUrlPlay:
            NSLog(@"Play stopped because another url playing.");
            break;
        case StopReasonPlayTimeOut:
            NSLog(@"Play stopped because play timeout.");
            break;
        case StopReasonDidPlayToEndTime:
            NSLog(@"Play stopped because play finished.");
            break;
        case StopReasonFailedToPlayToEndTime:
            NSLog(@"Play stopped because failed play.");
            break;
        case StopReasonStatusFailed:
            NSLog(@"Play stopped because status faild.");
            break;
        case StopReasonInterruption:
            NSLog(@"Play stopped by interruption.");
            break;
        default:
            NSLog(@"Play stopped.");
            break;
    }

    // 他のURLを再生する場合には再生開始側で通知を出すため、ここでは通知を出さない
    if (reason != StopReasonAnotherUrlPlay) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailPlayerDidStopNotification
                                                            object:self];
    }

    // 他のURLを再生する場合には、オーディオのセッションを無効化しない
    if (reason != StopReasonAnotherUrlPlay) {
        [self deacviveAudioSession];
    }

    // 再生タイムアウトのタイマーが走っている場合は止める（走っていることはないはずだが一応）
    if (playTimeOutTimer_ != nil) {
        [playTimeOutTimer_ invalidate];
        playTimeOutTimer_ = nil;
#if DEBUG
        NSLog(@"Play time out timer invalidate.");
#endif /* #if DEBUG */
    }
}

- (void)playTimeOut:(NSTimer *)timer
{
    @synchronized (self) {
        switch (state_) {
            case PlayerStatePrepare:
                [self stopProcWithReason:StopReasonPlayTimeOut];
                NSLog(@"Player time outed.");
                break;
            case PlayerStateIdle:
            case PlayerStatePlay:
            default:
                break;
        }
    }
}

- (void)stoppedDidPlayToEndTime:(NSNotification *)notification
{
    @synchronized (self) {
        switch (state_) {
            case PlayerStatePrepare:
            case PlayerStatePlay:
                [self stopProcWithReason:StopReasonDidPlayToEndTime];
                break;
            case PlayerStateIdle:
            default:
                break;
        }
    }
}

- (void)stoppedFailedToPlayToEndTime:(NSNotification *)notification
{
    @synchronized (self) {
        switch (state_) {
            case PlayerStatePrepare:
            case PlayerStatePlay:
                [self stopProcWithReason:StopReasonFailedToPlayToEndTime];
                break;
            case PlayerStateIdle:
            default:
                break;
        }
    }
}

#pragma mark - AVPlayer notifications

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == player_ && [keyPath isEqualToString:@"status"]) {
        if (player_.status == AVPlayerStatusReadyToPlay) {
            @synchronized (self) {
                switch (state_) {
                    case PlayerStatePrepare:
                        [self playStartedProc];
                        break;
                    case PlayerStateIdle:
                    case PlayerStatePlay:
                    default:
                        break;
                }
            }
        } else if (player_.status == AVPlayerStatusFailed) {
            @synchronized (self) {
                switch (state_) {
                    case PlayerStatePrepare:
                    case PlayerStatePlay:
                        [self stopProcWithReason:StopReasonStatusFailed];
                        break;
                    case PlayerStateIdle:
                    default:
                        break;
                }
            }
        }
    }
}

#pragma mark - AVAudioSessionDelegate methods

- (void)beginInterruption
{
	NSLog(@"audio settion begin interruption.");
    @synchronized (self) {
        switch (state_) {
            case PlayerStatePrepare:
            case PlayerStatePlay:
                [self stopProcWithReason:StopReasonInterruption];
                break;
            case PlayerStateIdle:
            default:
                break;
        }
    }
}

- (void)endInterruption
{
	NSLog(@"audio settion end interruption.");
}

- (void)endInterruptionWithFlags:(NSUInteger)flags
{
	NSLog(@"audio settion end interruption with flags %lu", (unsigned long)flags);
}

- (void)inputIsAvailableChanged:(BOOL)isInputAvailable
{
#if DEBUG
	NSLog(@"audio settion inputIsAvailableChanged %d", isInputAvailable);
#endif /* #if DEBUG */
}

@end
