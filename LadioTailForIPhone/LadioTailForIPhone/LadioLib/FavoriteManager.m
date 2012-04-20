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

#import "FavoriteManager.h"

#define FAVORITES_KEY_V1 @"FAVORITES_V1"
#define FAVORITES_KEY_V2 @"FAVORITES_V2"

static FavoriteManager *instance = nil;

@implementation FavoriteManager

+ (FavoriteManager *)sharedInstance
{
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[FavoriteManager alloc] init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        // 旧バージョンのデータを復元する
        [self restoreFromV1];
    }
    return self;
}

- (void)addFavorite:(Channel *)channel
{
    NSArray *channels = [[NSArray alloc] initWithObjects:channel, nil];
    [self addFavorites:channels];
}

- (void)addFavorites:(NSArray *)channels
{
    if ([channels count] == 0) {
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSData *favoritesData = [defaults objectForKey:FAVORITES_KEY_V2];
    NSMutableArray *favorites = nil;
    if (favoritesData != nil) {
        NSArray *favoritesArray = [NSKeyedUnarchiver unarchiveObjectWithData:favoritesData];
        if (favoritesArray != nil) {
            favorites = [[NSMutableArray alloc] initWithArray:favoritesArray];
        } else {
            favorites = [[NSMutableArray alloc] initWithCapacity:1];
        }
    } else {
        favorites = [[NSMutableArray alloc] initWithCapacity:1];
    }

    for (id channelId in channels) {
        if (channelId == nil || [channelId isKindOfClass:[Channel class]] == NO) {
            continue;
        }

        Channel* channel = (Channel *)channelId;
        // 登録済みの場合は何もしない
        if ([self isFavorite:channel]) {
            continue;
        }

        [favorites addObject:channel];
    }

    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:favorites] forKey:FAVORITES_KEY_V2];
    [defaults synchronize];
}

- (void)removeFavorite:(Channel *)channel
{
    if (channel == nil) {
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *favoritesData = [defaults objectForKey:FAVORITES_KEY_V2];
    NSMutableArray *favorites = nil;
    if (favoritesData != nil) {
        NSArray *favoritesArray = [NSKeyedUnarchiver unarchiveObjectWithData:favoritesData];
        if (favoritesArray != nil) {
            favorites = [[NSMutableArray alloc] initWithArray:favoritesArray];
        }
    }

    // 登録されているお気に入りを探索してリストから削除
    for (Channel *favoritedChannel in favorites) {
        if ([favoritedChannel.mnt isEqualToString:channel.mnt]) {
            [favorites removeObject:favoritedChannel];
            break;
        }
    }

    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:favorites] forKey:FAVORITES_KEY_V2];
    [defaults synchronize];
}

- (void)switchFavorite:(Channel *)channel
{
    if ([self isFavorite:channel]) {
        [self removeFavorite:channel];
    } else {
        [self addFavorite:channel];
    }
}

- (BOOL)isFavorite:(Channel *)channel
{
    if (channel == nil) {
        return NO;
    }
    
    BOOL result = NO;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *favoritesData = [defaults objectForKey:FAVORITES_KEY_V2];
    NSArray *favoritesArray = nil;
    if (favoritesData != nil) {
        favoritesArray = [NSKeyedUnarchiver unarchiveObjectWithData:favoritesData];
    }

    // 登録されているお気に入りを探索
    for (Channel *favoritedChannel in favoritesArray) {
        if ([favoritedChannel.mnt isEqualToString:channel.mnt]) {
            result = YES;
            break;
        }
    }

    return result;
}

#pragma mark Favorite Manager Data version 1 methods

- (void)addFavoriteV1:(NSString *)mount
{
    // 登録済みの場合は何もしない
    if ([self isFavoriteV1:mount]) {
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *favorites = [[defaults arrayForKey:FAVORITES_KEY_V1] mutableCopy];
    if (favorites == nil) {
        favorites = [[NSMutableArray alloc] initWithCapacity:1];
    }
    [favorites addObject:mount];
    [defaults setObject:favorites forKey:FAVORITES_KEY_V1];
    [defaults synchronize];
}

- (void)removeFavoriteV1:(NSString *)mount
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *favorites = [[defaults arrayForKey:FAVORITES_KEY_V1] mutableCopy];
    
    // 登録されているお気に入りを探索してリストから削除
    for (NSString *favoritedMount in favorites) {
        if ([favoritedMount isEqualToString:mount]) {
            [favorites removeObject:favoritedMount];
            break;
        }
    }
    
    [defaults setObject:favorites forKey:FAVORITES_KEY_V1];
    [defaults synchronize];
}

- (void)switchFavoriteV1:(NSString *)mount
{
    if ([self isFavoriteV1:mount]) {
        [self removeFavoriteV1:mount];
    } else {
        [self addFavoriteV1:mount];
    }
}

- (BOOL)isFavoriteV1:(NSString *)mount
{
    BOOL result = NO;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *favorites = [defaults arrayForKey:FAVORITES_KEY_V1];
    
    // 登録されているお気に入りを探索
    for (NSString *favoritedMount in favorites) {
        if ([favoritedMount isEqualToString:mount]) {
            result = YES;
            break;
        }
    }
    
    return result;
}

- (void)restoreFromV1
{
    // V1のデータを読み込む
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *favoritesV1 = [defaults arrayForKey:FAVORITES_KEY_V1];

    // V1のデータから番組を生成し（マウントしか入っていないが）、お気に入りに書き込む
    NSMutableArray* favorites = [[NSMutableArray alloc] initWithCapacity:[favoritesV1 count]];
    for (NSString *favoritedV1Mount in favoritesV1) {
        Channel *channel = [[Channel alloc] init];
        channel.mnt = favoritedV1Mount;
        [favorites addObject:channel];
    }
    [self addFavorites:favorites];
}

#pragma -

@end
