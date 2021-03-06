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

#import <Foundation/Foundation.h>

@interface ApnsStorage : NSObject

+ (ApnsStorage *)sharedInstance;

/// お気に入りの変化の開始を監視し、変化時にプロバイダへの送信をする
- (void)registApnsService;

/// お気に入りの変化の開始を止める
- (void)unregistApnsService;

/// デバイストークンを記憶する
- (void)setDeviceToken:(NSData *)devToken;

/// デバイストークンを削除する
- (void)removeDeviceToken;

/// お気に入りをプロバイダに送信する
///
/// お気に入りの変化時に、自動でお気に入りをプロバイダに送信するが、手動で送信したい場合は本館数を使用する
- (void)sendFavoriteToProvider;

@end
