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
#import "Channel.h"

/**
 * お気に入りを管理するシングルトンクラス
 */
@interface FavoriteManager : NSObject

/// お気に入りリスト
/// Channel.mntがキー、FavoriteがオブジェクトのNSDictionary
///
/// 直接いじらないこと Don't edit directly.
@property (strong, readonly) NSMutableDictionary *favorites;

/**
 * FavoriteManagerを取得する
 * 
 * @return FavoriteManager
 */
+ (FavoriteManager *)sharedInstance;

/**
 * お気に入りを追加する
 *
 * @param channel お気に入りに追加する番組
 */
- (void)addFavorite:(Channel *)channel;

/**
 * お気に入りを追加する
 *
 * @param channels お気に入りに追加する番組
 */
- (void)addFavorites:(NSArray *)channels;

/**
 * お気に入りを削除する
 *
 * @param channel お気に入りから削除する番組
 */
- (void)removeFavorite:(Channel *)channel;

/**
 * お気に入りに登録済みの場合は削除し、登録されていない場合は登録する
 *
 * @param channel お気に入りから削除する番組
 */
- (void)switchFavorite:(Channel *)channel;

/**
 * お気に入りを置き換える
 *
 * @param favorites 置き換えるお気に入り
 */
- (void)replace:(NSArray *)favorites;

/**
 * お気に入りをマージする
 *
 * @param favorites 加えるお気に入り
 */
- (void)merge:(NSArray *)favorites;

/**
 * お気に入りかを取得する
 *
 * @param channel お気に入りかを確認する番組
 * @return お気に入りの場合はYES、それ以外はNO
 */
- (BOOL)isFavorite:(Channel *)channel;

@end
