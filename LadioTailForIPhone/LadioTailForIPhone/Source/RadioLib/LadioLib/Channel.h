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

#ifdef LADIO_TAIL

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
@property (nonatomic, strong) NSURL *surl;

/// 放送開始時刻
@property (nonatomic, strong) NSDate *tims;

/// 配信サーバホスト名
@property (nonatomic, strong) NSString *srv;

/// 配信サーバポート番号
@property NSInteger prt;

/// 配信サーバマウント
@property (nonatomic, strong) NSString *mnt;

/// 配信フォーマットの種類
@property (nonatomic, strong) NSString *type;

/// タイトル
@property (nonatomic, strong) NSString *nam;

@property (nonatomic, strong, readonly) NSString *trimedNam;

/// ジャンル
@property (nonatomic, strong) NSString *gnl;

/// 放送内容
@property (nonatomic, strong) NSString *desc;

/// DJ
@property (nonatomic, strong) NSString *dj;

@property (nonatomic, strong, readonly) NSString *trimedDj;

/// 現在の曲名情報
@property (nonatomic, strong) NSString *song;

/// WebサイトのURL
@property (nonatomic, strong) NSURL *url;

/// 現リスナ数
@property (nonatomic, assign) NSInteger cln;

/// 総リスナ数
@property (nonatomic, assign) NSInteger clns;

/// 最大リスナ数
@property (nonatomic, assign) NSInteger max;

/// ビットレート（Kbps）
@property (nonatomic, assign) NSInteger bit;

/// サンプリングレート
@property (nonatomic, assign) NSInteger smpl;

/// チャンネル数
@property (nonatomic, assign) NSInteger chs;

/// お気に入りに登録済みか
@property (nonatomic, assign) BOOL favorite;

- (void)setSurlFromString:(NSString *)url;

- (NSString *)timsToString;

- (void)setTimsFromString:(NSString *)tims;

- (void)setUrlFromString:(NSString *)url;

- (NSURL *)playUrl;

- (void)switchFavorite;

- (BOOL)isMatch:(NSArray *)searchWords;

- (BOOL)isSameMount:(Channel *)channel;

/// この番組のストリームが再生可能な形式かを取得する
- (BOOL)isPlaySupported;

/// お気に入りキャッシュをクリアする
///
/// お気に入りの状態が変わった場合に、番組のお気に入りのキャッシュを削除する必要がある。
- (void)clearFavoriteCache;

/// 番組画面用のHTMLを取得する
- (NSString *)descriptionHtml;

@end

#endif // #ifdef LADIO_TAIL
