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

#import "../Notifications.h"
#import "Headline.h"
#import "Favorite.h"
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
        // データを復元する
        [self loadFavorites];
        // 旧バージョンのデータを復元する
        [self restoreFromV1];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(headlineChannelChanged:)
                                                     name:RadioLibHeadlineChannelChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RadioLibHeadlineChannelChangedNotification object:nil];
}

- (void)addFavorite:(Channel *)channel
{
    [self addFavorites:@[channel]];
}

- (void)addFavorites:(NSArray *)channels
{
    if ([channels count] == 0) {
        return;
    }

    @synchronized(self) {
        BOOL added = NO;

        for (Channel *channel in channels) {
            if ([self isValidChannel:channel] == NO) {
                continue;
            }

            // 登録済みの場合は何もしない
            if ([self isFavorite:channel]) {
                continue;
            }

            added = YES;
            Favorite *favorite = [[Favorite alloc] init];
            favorite.channel = channel;
            _favorites[channel.mnt] = favorite;
            [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibChannelChangedFavoriteNotification
                                                                object:channel];
        }

        if (added) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibChannelChangedFavoritesNotification
                                                                object:nil];
        }

        // お気に入りを保存する
        [self storeFavorites];
    }
}

- (void)removeFavorite:(Channel *)channel
{
    if (channel == nil) {
        return;
    }

    @synchronized(self) {
        if (_favorites[channel.mnt] != nil) {
            [_favorites removeObjectForKey:channel.mnt];

            [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibChannelChangedFavoriteNotification
                                                                object:channel];

            [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibChannelChangedFavoritesNotification
                                                                object:nil];
        }

        // お気に入りを保存する
        [self storeFavorites];
    }
}

- (void)switchFavorite:(Channel *)channel
{
    @synchronized(self) {
        if ([self isFavorite:channel]) {
            [self removeFavorite:channel];
        } else {
            [self addFavorite:channel];
        }
    }
}

- (void)replace:(NSArray *)favorites
{
    @synchronized(self) {
        // 今までのお気に入りをクリア
        [_favorites removeAllObjects];

        for (Favorite *favorite in favorites) {
            if ([self isValidFavorite:favorite] == NO) {
                continue;
            }

            _favorites[favorite.channel.mnt] = favorite;

            [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibChannelChangedFavoriteNotification
                                                                object:favorite.channel];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibChannelChangedFavoritesNotification
                                                            object:nil];

        // お気に入りを保存する
        [self storeFavorites];
    }
}

- (void)merge:(NSArray *)favorites
{
    @synchronized(self) {
        BOOL added = NO;

        for (Favorite *favorite in favorites) {
            if ([self isValidFavorite:favorite] == NO) {
                continue;
            }

            // おなじお気に入りが登録されている場合は新しい方を登録する
            Favorite *alreadyFavorite = _favorites[favorite.channel.mnt];
            if (alreadyFavorite != nil
                && [alreadyFavorite.registedDate timeIntervalSinceDate:favorite.registedDate] > 0) {
                continue;
            }

            added = YES;
            _favorites[favorite.channel.mnt] = favorite;
            [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibChannelChangedFavoriteNotification
                                                                object:favorite.channel];
        }

        if (added) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibChannelChangedFavoritesNotification
                                                                object:nil];
        }

        // お気に入りを保存する
        [self storeFavorites];
    }
}

- (BOOL)isFavorite:(Channel *)channel
{
    if (channel == nil || channel.mnt == nil) {
        return NO;
    }

    @synchronized(self) {
        return _favorites[channel.mnt] != nil;
    }
}

#pragma mark - Headline notification

- (void)headlineChannelChanged:(NSNotification *)notification
{
    // お気に入りの番組情報を更新する
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    NSArray *channels = [Headline sharedInstance].channels;
    dispatch_apply([channels count], queue, ^(size_t i) {
        Channel *channel = channels[i];
        if (channel != nil) {
            Favorite *favorite = _favorites[channel.mnt];
            if (favorite) {
                favorite.channel = channel;
            }
        }
    });
    [self storeFavorites];
}

#pragma mark - Private methods

/// データベースからお気に入り情報を復元する
- (void)loadFavorites
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *favoritesData = [defaults objectForKey:FAVORITES_KEY_V2];
    if (favoritesData != nil) {
        NSDictionary *favoritesArray = [NSKeyedUnarchiver unarchiveObjectWithData:favoritesData];
        if (favoritesArray != nil) {
            _favorites = [[NSMutableDictionary alloc] initWithDictionary:favoritesArray];
        } else {
            _favorites = [[NSMutableDictionary alloc] init];
        }
    } else {
        _favorites = [[NSMutableDictionary alloc] init];
    }
}

/// データベースにお気に入り情報を保存する
- (void)storeFavorites
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:_favorites] forKey:FAVORITES_KEY_V2];
}

/// データベースを空にする
- (void)clearFavorites
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:FAVORITES_KEY_V2];
    _favorites = nil;
}

- (BOOL)isValidChannel:(Channel *)channel
{
    if (channel == nil || [channel isKindOfClass:[Channel class]] == NO) {
        return NO;
    }

    // マウント名が入っていない場合はお気に入りに登録しない
    // マウント名でお気に入りの一致を見ているため
    if ([channel.mnt length] == 0) {
        return NO;
    }

    return YES;
}

- (BOOL)isValidFavorite:(Favorite *)favorite
{
    if (favorite == nil || [favorite isKindOfClass:[Favorite class]] == NO) {
        return NO;
    }

    if ([self isValidChannel:favorite.channel] == NO) {
        return NO;
    }

    return YES;
}

#pragma mark - Favorite Manager Data version 1 methods

// 使用しないこと
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

// 使用しないこと
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

// 使用しないこと
- (void)switchFavoriteV1:(NSString *)mount
{
    if ([self isFavoriteV1:mount]) {
        [self removeFavoriteV1:mount];
    } else {
        [self addFavoriteV1:mount];
    }
}

// 使用しないこと
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

    // V1のデータを削除
    [defaults removeObjectForKey:FAVORITES_KEY_V1];
}

@end
