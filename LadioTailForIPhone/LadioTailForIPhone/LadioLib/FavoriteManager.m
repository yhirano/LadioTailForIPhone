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

static FavoriteManager *instance = nil;

@implementation FavoriteManager
+ (FavoriteManager *)sharedInstance
{
    if (instance == nil) {
        instance = [[FavoriteManager alloc] init];
    }
    return instance;
}

- (void)addFavorite:(NSString*)mount
{
    // 登録済みの場合は何もしない
    if ([self isFavorite:mount]) {
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

- (void)removeFavorite:(NSString*)mount
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

- (void)switchFavorite:(NSString*)mount
{
    if ([self isFavorite:mount]) {
        [self removeFavorite:mount];
    } else {
        [self addFavorite:mount];
    }
}

- (BOOL)isFavorite:(NSString*)mount
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

@end
