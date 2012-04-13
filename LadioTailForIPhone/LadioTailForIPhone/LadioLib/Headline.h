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
#import "Channel.h"

/// ヘッドラインの取得を開始した際のNotification
#define NOTIFICATION_NAME_FETCH_HEADLINE_STARTED @"FetchHeadlineStarted"
/// ヘッドラインの取得に成功した際のNotification
#define NOTIFICATION_NAME_FETCH_HEADLINE_SUCEED @"FetchHeadlineSuceed"
/// ヘッドラインの取得に失敗した際のNotification
#define NOTIFICATION_NAME_FETCH_HEADLINE_FAILED @"FetchHeadlineFailed"

enum
{
    CHANNEL_SORT_TYPE_NEWLY,
    CHANNEL_SORT_TYPE_LISTENERS,
    CHANNEL_SORT_TYPE_TITLE,
    CHANNEL_SORT_TYPE_DJ,
    CHANNEL_SORT_TYPE_NONE,
};

/**
 * ヘッドライン
 */
@interface Headline : NSObject

- (id)init;

/**
 * ヘッドラインをネット上から取得する
 */
- (void)fetchHeadline;

/**
 * 番組を取得する
 *
 * @return 番組
 */
- (NSArray *)getChannels;

/**
 * 指定したソート順で番組を取得する
 *
 * @param sortType ソート種類
 * @return 番組
 * @see CHANNEL_SORT_TYPE_NEWLY
 * @see CHANNEL_SORT_TYPE_LISTENERS
 * @see CHANNEL_SORT_TYPE_TITLE
 * @see CHANNEL_SORT_TYPE_DJ
 * @see CHANNEL_SORT_TYPE_NONE
 */
- (NSArray *)getChannels:(int)sortType;

/**
 * 一致する再生URLを持つ番組を取得する
 * 
 * @param playUrl 再生URL
 * @return Channel。見つからない場合はnil。
 */
- (Channel*)getChannel:(NSURL*)playUrl;
@end
