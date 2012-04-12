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

#import <Foundation/Foundation.h>

/// リスナ数が不明
#define CHANNEL_UNKNOWN_LISTENER_NUM -1

/// ビットレートが不明
#define CHANNEL_UNKNOWN_BITRATE_NUM -1

/// サンプリングレートが不明
#define CHANNEL_UNKNOWN_SAMPLING_RATE_NUM -1

/// チャンネル数が不明
#define CHANNEL_UNKNOWN_CHANNEL_NUM -1


/**
 * 番組
 */
@interface Channel : NSObject
{
}

/// 番組の詳細内容を表示するサイトのURL
@property (strong) NSURL *surl;

/// 放送開始時刻
@property (strong) NSDate *tims;

/// 配信サーバホスト名
@property (strong) NSString *srv;

/// 配信サーバポート番号
@property int prt;

/// 配信サーバマウント
@property (strong) NSString *mnt;

/// 配信フォーマットの種類
@property (strong) NSString *type;

/// タイトル
@property (strong) NSString *nam;

/// ジャンル
@property (strong) NSString *gnl;

/// 放送内容
@property (strong) NSString *desc;

/// DJ
@property (strong) NSString *dj;

/// 現在の曲名情報
@property (strong) NSString *song;

/// WebサイトのURL
@property (strong) NSURL *url;

/// 現リスナ数
@property int cln;

/// 総リスナ数
@property int clns;

/// 最大リスナ数
@property int max;

/// ビットレート（Kbps）
@property int bit;

/// サンプリングレート
@property int smpl;

/// チャンネル数
@property int chs;

- (id)init;

- (NSString *)description;

- (void)setSurlFromString:(NSString *)u;

- (NSString *)getTimsToString;

- (void)setTimsFromString:(NSString *)t;

- (void)setUrlFromString:(NSString *)u;

- (NSURL *)getPlayUrl;

- (NSComparisonResult)compareNewly:(Channel *)_channel;

- (NSComparisonResult)compareListeners:(Channel *)_channel;

- (NSComparisonResult)compareTitle:(Channel *)_channel;

- (NSComparisonResult)compareDj:(Channel *)_channel;

@end
