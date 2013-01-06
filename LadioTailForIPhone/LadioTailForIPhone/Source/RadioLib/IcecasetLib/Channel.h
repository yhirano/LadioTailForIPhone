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

#ifdef RADIO_EDGE

/**
 * 番組
 */
@interface Channel : NSObject <NSCoding>

/// サーバから取得した番組順に振ったID
@property NSInteger fid;

/// Server Name
@property (copy) NSString *serverName;

@property (strong, readonly) NSString *trimedServerName;

/// Listen URL
@property (strong) NSURL *listenUrl;

/// ジャンル
@property (copy) NSString *genre;

@property (strong, readonly) NSString *trimedGenre;

/// Current Song
@property (copy) NSString *currentSong;

/// Server Type
@property (copy) NSString *serverType;

/// ビットレート（Kbps）
@property NSInteger bitrate;

/// サンプリングレート
@property NSInteger sampleRate;

/// チャンネル数
@property NSInteger channels;

/// お気に入りに登録済みか
@property BOOL favorite;

- (void)switchFavorite;

- (BOOL)isMatch:(NSArray *)searchWords;

- (BOOL)isSameName:(Channel *)channel;

- (BOOL)isSameListenUrl:(Channel *)channel;

/// この番組のストリームが再生可能な形式かを取得する
- (BOOL)isPlaySupported;

/// お気に入りキャッシュをクリアする
///
/// お気に入りの状態が変わった場合に、番組のお気に入りのキャッシュを削除する必要がある。
- (void)clearFavoriteCache;

/// 番組画面用のHTMLを取得する
- (NSString *)descriptionHtml;

@end

#endif // #ifdef RADIO_EDGE
