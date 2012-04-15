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

static Player *instance = nil;

@interface Player ()
{
    AVPlayer *player;
    PlayerState state;
    NSURL *playUrl;
}

@end

@implementation Player

+ (Player *)sharedInstance
{
    if (instance == nil) {
        instance = [[Player alloc] init];

        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [[AVAudioSession sharedInstance] setDelegate:self];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        @synchronized(self) {
            state = PlayerStateIdle;
        }

        // 再生が終端ないしエラーで終了した際に通知を受け取り、状態を変更する
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(stopped:)
         name:AVPlayerItemDidPlayToEndTimeNotification
         object:nil];
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(stopped:)
         name:AVPlayerItemFailedToPlayToEndTimeNotification
         object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:AVPlayerItemDidPlayToEndTimeNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:AVPlayerItemFailedToPlayToEndTimeNotification
     object:nil];
}

- (void)play:(NSURL *)url
{
    @synchronized(self) {
        // 既に再生中のURLとおなじ場合は何もしない
        if ([self isPlaying:url]) {
            return;
        }
        
        switch (state) {
            case PlayerStatePlay:
                // 再生中中は停止
                [player pause];
                // スルー
            case PlayerStateIdle:
                state = PlayerStatePrepare;
                playUrl = url;
                NSLog(@"Play start %@", [playUrl absoluteString]);
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
                player = [AVPlayer playerWithURL:url];
                [player addObserver:self forKeyPath:@"status" options:0 context:nil];
                [player play];
                break;
            case PlayerStatePrepare:
            default:
                break;
        }
    }    
}

- (void)stop
{
    @synchronized(self) {
        [player pause];
        state = PlayerStateIdle;
        NSLog(@"Play stopped by user operation.");
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
    }
}

- (BOOL)isPlaying:(NSURL *)url
{
    @synchronized(self) {
        NSURL *playingUrl = [self getPlayUrl];
        if (playingUrl == nil) {
            return NO;
        } else {
            return ([[playingUrl absoluteString] isEqualToString:[url absoluteString]]);
        }
    }
}

- (NSURL*)getPlayUrl
{
    @synchronized(self) {
        switch (state) {
            case PlayerStatePlay:
                return playUrl;
            case PlayerStateIdle:
            case PlayerStatePrepare:
            default:
                return nil;
        }
    }
}

- (PlayerState)getState
{
    @synchronized(self) {
        return state;
    }
}

- (void)stopped:(NSNotification *)notification
{
    @synchronized(self) {
        playUrl = nil;
        state = PlayerStateIdle;
        NSLog(@"Play stopped.");
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (object == player && [keyPath isEqualToString:@"status"]) {
        if (player.status == AVPlayerStatusReadyToPlay) {
            @synchronized(self) {
                state = PlayerStatePlay;
                NSLog(@"Play started.");
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
            }
        } else if (player.status == AVPlayerStatusFailed) {
            @synchronized(self) {
                state = PlayerStateIdle;
                NSLog(@"Play failed.");
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
            }
        }
    }
}

@end
