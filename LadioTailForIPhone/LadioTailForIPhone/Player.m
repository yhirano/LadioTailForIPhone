/*
 * Copyright (c) 2012 Y.Hirano
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

#import "Player.h"

/// 再生開始後のタイムアウト処理までの時間
#define PLAY_TIMEOUT_SEC 15.0

static Player *instance = nil;

@implementation Player
{
@private
    AVPlayer *player_;
    NSURL *playUrl_;
    NSTimer *playTimeOutTimer_;
}

@synthesize state = state_;

+ (Player *)sharedInstance
{
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
        NSError *setActiveError = nil;
        [audioSession setActive:YES error:&setActiveError];
        if (setActiveError) {
            NSLog(@"Audio session setActive error.");
        }

        // 再生が終端ないしエラーで終了した際に通知を受け取り、状態を変更する
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stopped:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stopped:)
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

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *setActiveError = nil;
    [audioSession setActive:NO error:&setActiveError];
    if (setActiveError) {
        NSLog(@"Audio session setActive error.");
    }
}

- (void)play
{
    @synchronized (self) {
        switch (state_) {
            case PlayerStateIdle:
                if (playUrl_ != nil) {
                    [self playProc:playUrl_];
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
                [self stopProc:NO byError:NO];
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

- (void)stop
{
    @synchronized (self) {
        switch (state_) {
            case PlayerStatePrepare:
            case PlayerStatePlay:
                [self stopProc:YES byError:NO];
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

- (PlayerState)state
{
    @synchronized (self) {
        return state_;
    }
}

- (NSURL*)playingUrl
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

/// 再生処理
- (void)playProc:(NSURL *)url
{
    // URLが空の場合は何もしない
    if (url == nil) {
        return;
    }
    
    state_ = PlayerStatePrepare;
    playUrl_ = url;
    NSLog(@"Play start %@", [playUrl_ absoluteString]);
    [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailPlayerPrepareNotification object:self];
    player_ = [AVPlayer playerWithURL:url];
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
    NSLog(@"Play time out timer fired.");
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
- (void)stopProc:(BOOL)notification byError:(BOOL)error
{
    [player_ pause];
    [player_ removeObserver:self forKeyPath:@"status"];
    // エラーで停止した場合は再生中のURLを残さない
    if (error) {
        playUrl_ = nil;
    }
    state_ = PlayerStateIdle;
    NSLog(@"Play stopped.");
    if (notification) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailPlayerDidStopNotification
                                                            object:self];
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
                [self stopProc:YES byError:YES];
                NSLog(@"Player time outed.");
                break;
            case PlayerStateIdle:
            case PlayerStatePlay:
            default:
                break;
        }
    }
}

- (void)stopped:(NSNotification *)notification
{
    @synchronized (self) {
        switch (state_) {
            case PlayerStatePrepare:
            case PlayerStatePlay:
                [self stopProc:YES byError:YES];
                break;
            case PlayerStateIdle:
            default:
                break;
        }
    }
}

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
                [self playStartedProc];
            }
        } else if (player_.status == AVPlayerStatusFailed) {
            [self stopped:nil];
        }
    }
}

#pragma mark AVAudioSessionDelegate methods

- (void)beginInterruption
{
	NSLog(@"audio settion begin interruption.");
    [self stop];
}

- (void)endInterruption
{
	NSLog(@"audio settion end interruption.");
}

- (void)endInterruptionWithFlags:(NSUInteger)flags
{
	NSLog(@"audio settion end interruption with flags %d", flags);
}

- (void)inputIsAvailableChanged:(BOOL)isInputAvailable
{
#if DEBUG
	NSLog(@"audio settion inputIsAvailableChanged %d", isInputAvailable);
#endif /* #if DEBUG */
}

#pragma mark -

@end
