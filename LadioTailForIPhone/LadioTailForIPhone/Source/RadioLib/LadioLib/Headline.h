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

#ifdef LADIO_TAIL

#import "Channel.h"

typedef enum
{
    ChannelSortTypeNone,
    ChannelSortTypeNewly,
    ChannelSortTypeListeners,
    ChannelSortTypeTitle,
    ChannelSortTypeDj,
} ChannelSortType;

/**
 * ヘッドライン
 */
@interface Headline : NSObject

/**
 * ヘッドラインインスタンスを取得
 */
+ (Headline *)sharedInstance;

/// ヘッドラインの最終更新時間。更新したことが無い場合はnil。
@property (nonatomic, strong, readonly) NSDate* lastUpdate;

/**
 * ヘッドラインをネット上から取得する
 */
- (void)fetchHeadline;

/**
 * ヘッドラインをネット上から取得中かを取得する
 *
 * @return ヘッドラインを取得中か
 */
- (BOOL)isFetchingHeadline;

/**
 * 番組リストを取得する
 *
 * @return 番組リスト
 */
- (NSArray *)channels;

/**
 * 指定したソート順で番組リストを取得する
 *
 * @param sortType ソート種類
 * @return 番組リスト
 * @see ChannelSortTypeNone
 * @see ChannelSortTypeNewly
 * @see ChannelSortTypeListeners
 * @see ChannelSortTypeTitle
 * @see ChannelSortTypeDj
 */
- (NSArray *)channels:(ChannelSortType)sortType;

/**
 * 番組リストを取得する
 * 
 * @param sortType ソート種類
 * @param searchWord フィルタリング単語。
 *                   ここで指定した文字列をスペースに分かち書きしたそれぞれの文字列に
 *                   対して、すべてに合致する番組のみtrueを返す（AND検索）。
 *                   フィルタリング単語を指定しない場合は空も時価かnilを指定すること。
 * @return 番組リスト
 * @see ChannelSortTypeNone
 * @see ChannelSortTypeNewly
 * @see ChannelSortTypeListeners
 * @see ChannelSortTypeTitle
 * @see ChannelSortTypeDj
 */
- (NSArray *)channels:(ChannelSortType)sortType searchWord:(NSString *)searchWord;

/**
 * 一致する再生URLを持つ番組を取得する
 *
 * @param playUrl 再生URL
 * @return Channel。見つからない場合はnil。
 */
- (Channel *)channelFromPlayUrl:(NSURL *)playUrl;

/**
 * 一致するマウントを持つ番組を取得する
 *
 * @param mount マウント
 * @return Channel。見つからない場合はnil。
 */
- (Channel *)channelFromMount:(NSString *)mount;

@end

#endif // #ifdef LADIO_TAIL
