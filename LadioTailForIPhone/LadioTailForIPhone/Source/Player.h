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

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "RadioLib/RadioLib.h"

/// 再生準備開始のNotification
#define LadioTailPlayerPrepareNotification @"LadioTailPlayerPrepareNotification"
/// 再生開始のNotification
#define LadioTailPlayerDidPlayNotification @"LadioTailPlayerDidPlayNotification"
/// 再生停止のNotification
#define LadioTailPlayerDidStopNotification @"LadioTailPlayerDidStopNotification"

typedef enum
{
    PlayerStateIdle,
    PlayerStatePrepare,
    PlayerStatePlay,
} PlayerState;

@interface Player : NSObject

+ (Player *)sharedInstance;

/**
 * 前回停止したコンテンツを再生する
 */
- (void)play;

/**
 * 指定のURLのコンテンツを再生する
 *
 * @param url 再生するURL
 */
- (void)play:(NSURL *)url;

/**
 * 指定の番組のコンテンツを再生する
 *
 * @param url 再生する番組
 */
- (void)playChannel:(Channel *)channel;

/**
 * 再生を停止する
 */
- (void)stop;

/**
 * 再生・停止を切り替える
 */
- (void)switchPlayStop;

/**
 * 指定したURLが再生中かを取得する
 *
 * @return 再生中の場合はYES、それ以外はNO。
 */
- (BOOL)isPlaying:(NSURL *)url;

/**
 * 指定したURLが再生準備中かを取得する
 *
 * @return 再生準備中の場合はYES、それ以外はNO。
 */
- (BOOL)isPreparing:(NSURL *)url;

/**
 * 再生状態を取得する
 *
 * @return 再生状態
 */
- (PlayerState)state;

/**
 * 再生中のURLを取得する
 * 
 * @return 再生中のURL。再生していない場合はnil。
 */
- (NSURL *)playingUrl;

/**
 * 再生中の番組を取得する
 * 
 * @return 再生中の番組。再生していない場合はnil。playChannelで番組を再生した場合にのみ有効。
 */
- (Channel *)playingChannel;

/**
 * 再生準備中のURLを取得する
 *
 * @return 再生準備中のURL。再生準備中でない場合はnil。
 */
- (NSURL *)preparingUrl;

/**
 * 再生準備中の番組を取得する
 *
 * @return 再生準備中の番組。再生準備中でない場合はnil。playChannelで番組を再生した場合にのみ有効。
 */
- (Channel *)preparingChannel;

@end
