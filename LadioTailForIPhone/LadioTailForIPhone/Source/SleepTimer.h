/*
 * Copyright (c) 2013 Yuichi Hirano
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
#import <Foundation/Foundation.h>

/// スリープタイマーの状態変化通知
#define LadioTailSleepTimerUpdate @"LadioTailSleepTimerUpdate"

/// スリープタイマーの発火通知
#define LadioTailSleepTimerFired @"LadioTailSleepTimerFired"

/// スリープタイマークラス。
/// このクラスで指定した時刻に再生の停止をする
@interface SleepTimer : NSObject

+ (SleepTimer *)sharedInstance;

/** スリープタイマーの発火時間を設定する
 *
 * @param スリープタイマーの発火までの時間[sec]。0未満の場合はスリープタイマーが停止する。
 */
- (void)setSleepTimerWithInterval:(NSTimeInterval)seconds;

/** スリープタイマーを停止する
 */
- (void)stop;

/** スリープタイマーの発火日時を取得する
 *
 * @return スリープタイマーの発火日時。スリープタイマーが指定されていない場合はnil。
 */
- (NSDate *)fireDate;

@end
