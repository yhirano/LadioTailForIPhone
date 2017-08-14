/*
 * Copyright (c) 2012-2017 Yuichi Hirano
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

#import <AVFoundation/AVFoundation.h>
#import <StreamingKit/STKAudioPlayer.h>
#import "LadioTailConfig.h"
#import "PlayerDidStopNotificationObject.h"
#import "Player.h"

@interface Player () <STKAudioPlayerDelegate>

@end

@implementation Player
{
    // Player
    STKAudioPlayer *player_;
    // 再生状態
    PlayerState state_;
    // 再生中のURL
    NSURL *playUrl_;
    // 再生中の番組
    Channel *playChannel_;
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDidInterrupt:) name:AVAudioSessionInterruptionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRouteDidChange:) name:AVAudioSessionRouteChangeNotification object:nil];
        NSError *setCategoryError = nil;
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
        if (setCategoryError) {
            NSLog(@"Audio session setCategory error.");
        }
    }
    return self;
}

- (void)dealloc
{
    [self stop];
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
                [self stopProcWithReason:PlayerStopReasonAnotherUrlPlay];
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
                [self stopProcWithReason:PlayerStopReasonAnotherUrlPlay];
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
                [self stopProcWithReason:PlayerStopReasonUser];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailPlayerPrepareNotification object:playChannel_];
    [self acviveAudioSession];
    player_ = [[STKAudioPlayer alloc] init];
    player_.delegate = self;
    [player_ playURL:url];
}

/// 停止処理
- (void)stopProcWithReason:(PlayerStopReason)reason
{
    // 通知のためローカルでいったん保持
    Channel *playChannel = playChannel_;
    
    [player_ stop];
    // ユーザーが停止した場合以外はURLと番組を残さない。
    // ユーザーが停止した場合は、リモコンから再度再生できるようにする（switchPlayStop method）ためにこれらを残しておく
    if (reason != PlayerStopReasonUser) {
        playUrl_ = nil;
        playChannel_ = nil;
    }

    state_ = PlayerStateIdle;
    switch (reason) {
        case PlayerStopReasonUser:
            NSLog(@"Play stopped by user.");
            break;
        case PlayerStopReasonAnotherUrlPlay:
            NSLog(@"Play stopped because another url playing.");
            break;
        case PlayerStopReasonPlayTimeOut:
            NSLog(@"Play stopped because play timeout.");
            break;
        case PlayerStopReasonDidPlayToEndTime:
            NSLog(@"Play stopped because play finished.");
            break;
        case PlayerStopReasonStatusFailed:
            NSLog(@"Play stopped because status faild.");
            break;
        case PlayerStopReasonInterruption:
            NSLog(@"Play stopped by interruption.");
            break;
        default:
            NSLog(@"Play stopped.");
            break;
    }

    PlayerDidStopNotificationObject *notificationObject = [[PlayerDidStopNotificationObject alloc]
                                                           initWithChannel:playChannel reason:reason];
    [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailPlayerDidStopNotification
                                                        object:notificationObject];

    // 他のURLを再生する場合には、オーディオのセッションを無効化しない
    if (reason != PlayerStopReasonAnotherUrlPlay) {
        [self deacviveAudioSession];
    }
}

#pragma mark - STKAudioPlayerDelegate method

-(void)audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId
{
}

-(void)audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId
{
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer
       stateChanged:(STKAudioPlayerState)state
      previousState:(STKAudioPlayerState)previousState
{
    switch (state) {
        case STKAudioPlayerStateReady:
            break;
        case STKAudioPlayerStateRunning:
        case STKAudioPlayerStatePlaying: {
            state_ = PlayerStatePlay;
            NSLog(@"Play started.");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailPlayerDidPlayNotification
                                                                object:playChannel_];
            break;
        }
        case STKAudioPlayerStateBuffering:
        case STKAudioPlayerStatePaused:
            break;
        case STKAudioPlayerStateStopped:
            if (player_.stopReason == STKAudioPlayerStopReasonEof) {
                [self stopProcWithReason:PlayerStopReasonDidPlayToEndTime];
            }
            break;
        case STKAudioPlayerStateError:
        case STKAudioPlayerStateDisposed:
            [self stopProcWithReason:PlayerStopReasonStatusFailed];
            break;
    }
}

-(void)         audioPlayer:(STKAudioPlayer*)audioPlayer
didFinishPlayingQueueItemId:(NSObject*)queueItemId
                 withReason:(STKAudioPlayerStopReason)stopReason
                andProgress:(double)progress
                andDuration:(double)duration
{
}

-(void)audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
    NSLog(@"Occurred unexpectedError. errorCode=%ld.", (long)errorCode);
}

#pragma mark - AVAudioSession notification

- (void)sessionDidInterrupt:(NSNotification *)notification
{
    switch ([notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue]) {
        case AVAudioSessionInterruptionTypeBegan:
            NSLog(@"audio settion began interruption.");
            @synchronized (self) {
                switch (state_) {
                    case PlayerStatePrepare:
                    case PlayerStatePlay:
                        [self stopProcWithReason:PlayerStopReasonInterruption];
                        break;
                    case PlayerStateIdle:
                    default:
                        break;
                }
            }
            break;
        case AVAudioSessionInterruptionTypeEnded:
            NSLog(@"audio settion ended interruption.");
            break;
        default:
            NSLog(@"audio settion interrupted.");
            break;
    }
}

- (void)sessionRouteDidChange:(NSNotification *)notification
{
#if DEBUG
    NSLog(@"audio settion route did change.");
#endif /* #if DEBUG */
}

@end
