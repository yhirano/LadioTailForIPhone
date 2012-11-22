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
#import "Favorite.h"
#import "FavoriteManager.h"

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
    }
    return self;
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
            _favorites[[channel.listenUrl absoluteString]] = favorite;
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
        NSString* urlString = [channel.listenUrl absoluteString];
        if (_favorites[urlString] != nil) {
            [_favorites removeObjectForKey:urlString];

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

            _favorites[[favorite.channel.listenUrl absoluteString]] = favorite;

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
            NSString* urlString = [favorite.channel.listenUrl absoluteString];
            Favorite *alreadyFavorite = _favorites[urlString];
            if (alreadyFavorite != nil
                && [alreadyFavorite.registedDate timeIntervalSinceDate:favorite.registedDate] > 0) {
                continue;
            }

            added = YES;
            _favorites[urlString] = favorite;
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
    @synchronized(self) {
        return _favorites[[channel.listenUrl absoluteString]] != nil;
    }
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

    // Listener URLが入っていない場合はお気に入りに登録しない
    // Listener URLでお気に入りの一致を見ているため
    if (channel.listenUrl == nil && [[channel.listenUrl absoluteString] length] == 0) {
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

@end
