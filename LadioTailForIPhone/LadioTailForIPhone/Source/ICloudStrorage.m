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

#import "RadioLib/RadioLib.h"
#import "ICloudStrorage.h"

/// お気に入りを保存のキー
#define FAVORITES_V1 @"FAVORITES_V1"

static ICloudStrorage *instance = nil;

@implementation ICloudStrorage
{
@private
    /// お気に入りを同期するか
    BOOL syncFavorites_;
}

+ (ICloudStrorage *)sharedInstance
{
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[ICloudStrorage alloc] init];
    });
    return instance;
}

- (id)init
{
    syncFavorites_ = NO;

    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        syncFavorites_ = [defaults boolForKey:@"favorites_icloud_sync"];
    }
    return self;
}

- (void)registICloudNotification
{
     // is iCloud enabled
    if([NSUbiquitousKeyValueStore defaultStore]) {
        // iCloudから通知を受ける
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(iCloudNotification:)
                                                     name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                   object:nil];

        // 番組のお気に入りの変化通知を受け取る
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(channelFavoritesChanged:)
                                                     name:RadioLibChannelChangedFavoritesNotification
                                                   object:nil];

        // 設定の変更を捕捉する
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(defaultsChanged:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    } else {
        NSLog(@"iCloud not enabled");
    }
}

- (void)unregistICloudNotification
{
    // is iCloud enabled
    if([NSUbiquitousKeyValueStore defaultStore]) {
        // 設定の変更を捕捉しなくする
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];

        // 番組のお気に入りの変化通知を受け取らなくする
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:RadioLibChannelChangedFavoritesNotification
                                                      object:nil];

        // iCloudからの通知を受けなくする
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                      object:nil];
    } else {
        NSLog(@"iCloud not enabled");
    }
}

- (void)iCloudNotification:(NSNotification *)notification
{
#if DEBUG
    NSDictionary *dic = [notification userInfo];
    NSLog(@"Received iCloud message. : %@", [dic description]);
#else
    NSLog(@"Received iCloud message.");
#endif /* #if DEBUG */

    // お気に入りを書き換える
    if (syncFavorites_) {
        NSUbiquitousKeyValueStore *icStore = [NSUbiquitousKeyValueStore defaultStore];
        NSData *archive = [icStore objectForKey:FAVORITES_V1];
        NSArray *favorites = [NSKeyedUnarchiver unarchiveObjectWithData:archive];
        [[FavoriteManager sharedInstance] replace:favorites];

        [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailICloudStorageChangedFavoritesNotification
                                                            object:nil];
    }
}

- (void)defaultsChanged:(NSNotification *)notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL mergeFavorite = NO;

    @synchronized (self) {
        BOOL syncFavorites = [defaults boolForKey:@"favorites_icloud_sync"];
#if DEBUG
        if (syncFavorites != syncFavorites_) {
            NSLog(@"Favorite iCloud sync setting is changed from %@ to %@.",
                  (syncFavorites_ ? @"YES" : @"NO"),
                  (syncFavorites ? @"YES" : @"NO"));
        }
#endif /* #if DEBUG */

        if (syncFavorites_ == NO && syncFavorites) {
            mergeFavorite = YES;
        }

        syncFavorites_ = syncFavorites;
    }

    // お気に入り同期設定がNOからYESになる場合はお気に入りをマージし、iCloudに送信
    if (mergeFavorite) {
        NSUbiquitousKeyValueStore *icStore = [NSUbiquitousKeyValueStore defaultStore];
        NSData *archive = [icStore objectForKey:FAVORITES_V1];
        NSArray *favorites = [NSKeyedUnarchiver unarchiveObjectWithData:archive];
        [[FavoriteManager sharedInstance] merge:favorites];

        [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailICloudStorageChangedFavoritesNotification
                                                            object:nil];

        // RadioLibChannelChangedFavoritesNotificationが飛んでくるので
        // channelFavoritesChanged:を実行しiCloudnに同期される
    }
}

- (void)channelFavoritesChanged:(NSNotification *)notification
{
    // お気に入りをiCloudに送信
    if (syncFavorites_) {
        NSArray *favorites = [[FavoriteManager sharedInstance].favorites allValues];
        NSLog(@"Send %d favorite to iCloud.", [favorites count]);
        NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:favorites];
        NSUbiquitousKeyValueStore *icStore = [NSUbiquitousKeyValueStore defaultStore];
        [icStore setObject:archive forKey:FAVORITES_V1];
        BOOL result = [icStore synchronize];
        if (result == NO) {
            NSLog(@"Sending favorite to iCloud error occurred.");
        }
    }
}

@end
