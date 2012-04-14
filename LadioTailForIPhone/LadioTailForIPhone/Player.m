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
    int state;
    NSURL *playUrl;
}

@end

@implementation Player

+ (Player *)getPlayer
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
        state = PLARER_STATE_IDLE;

        // 再生が終端ないしエラーで終了した際に通知を受け取り、状態を変更する
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopped:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopped:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
}

- (void)play:(NSURL *)url
{
    switch (state) {
        case PLARER_STATE_IDLE:
            state = PLARER_STATE_PLAY;
            playUrl = url;
            NSLog(@"Play started %@", [playUrl absoluteString]);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
            player = [AVPlayer playerWithURL:url];
            [player play];
            break;
        case PLARER_STATE_PLAY:
            if ([self isPlayUrl:url] == NO) {
                [player pause];
                playUrl = url;
                NSLog(@"Play started %@", [playUrl absoluteString]);
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
                player = [AVPlayer playerWithURL:url];
                [player play];
            }
            break;
        default:
            break;
    }
}

- (void)stop
{
    [player pause];
    playUrl = nil;
    state = PLARER_STATE_IDLE;
    NSLog(@"Play stopped by user operation.");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
}

- (BOOL)isPlayUrl:(NSURL *)url
{
    if ([self getPlayUrl] == nil) {
        return NO;
    } else {
        return ([[playUrl absoluteString] isEqualToString:[url absoluteString]]);
    }
}

- (NSURL*)getPlayUrl
{
    switch (state) {
        case PLARER_STATE_PLAY:
            return playUrl;
        case PLARER_STATE_IDLE:
        default:
            return nil;
    }
}

- (void)stopped:(NSNotification *)notification
{
    playUrl = nil;
    state = PLARER_STATE_IDLE;
    NSLog(@"Play stopped.");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:self];
}

- (int)getState
{
    return state;
}

@end
