/*
 * Copyright (c) 2012 Yuichi Hirano
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
@interface Channel : NSObject <NSCoding>

/// 番組の詳細内容を表示するサイトのURL
@property (strong) NSURL *surl;

/// 放送開始時刻
@property (copy) NSDate *tims;

/// 配信サーバホスト名
@property (copy) NSString *srv;

/// 配信サーバポート番号
@property NSInteger prt;

/// 配信サーバマウント
@property (copy) NSString *mnt;

/// 配信フォーマットの種類
@property (copy) NSString *type;

/// タイトル
@property (copy) NSString *nam;

/// ジャンル
@property (copy) NSString *gnl;

/// 放送内容
@property (copy) NSString *desc;

/// DJ
@property (copy) NSString *dj;

/// 現在の曲名情報
@property (copy) NSString *song;

/// WebサイトのURL
@property (strong) NSURL *url;

/// 現リスナ数
@property NSInteger cln;

/// 総リスナ数
@property NSInteger clns;

/// 最大リスナ数
@property NSInteger max;

/// ビットレート（Kbps）
@property NSInteger bit;

/// サンプリングレート
@property NSInteger smpl;

/// チャンネル数
@property NSInteger chs;

/// お気に入りに登録済みか
@property BOOL favorite;

- (void)setSurlFromString:(NSString *)url;

- (NSString *)timsToString;

- (void)setTimsFromString:(NSString *)tims;

- (void)setUrlFromString:(NSString *)url;

- (NSURL *)playUrl;

- (void)switchFavorite;

- (BOOL)isMatch:(NSArray *)searchWords;

- (BOOL)isSameMount:(Channel *)channel;

@end
