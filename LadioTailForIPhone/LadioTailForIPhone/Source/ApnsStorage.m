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

#import "LadioTailConfig.h"
#import "RadioLib/Notifications.h"
#import "SendFavoritesToProviderOperation.h"
#import "ApnsStorage.h"

/// デバイストークンを記憶するためのキー
#define DEVICE_TOKEN @"DEVICE_TOKEN"

@implementation ApnsStorage
{
    NSOperationQueue *sendFavoritesOperationQueue_;
}

+ (ApnsStorage *)sharedInstance
{
    static ApnsStorage *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[ApnsStorage alloc] init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        sendFavoritesOperationQueue_ = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)registApnsService
{
    // 番組のお気に入りの変化通知を受け取る
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(channelFavoritesChanged:)
                                                 name:RadioLibChannelChangedFavoritesNotification
                                               object:nil];
}

- (void)unregistApnsService
{
    // 番組のお気に入りの変化通知を受け取らなくする
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:RadioLibChannelChangedFavoritesNotification
                                                  object:nil];
}

- (void)setDeviceToken:(NSData *)devToken
{
    NSString *devTokenStr = [[[[devToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
                              stringByReplacingOccurrencesOfString:@">" withString:@""]
                              stringByReplacingOccurrencesOfString: @" " withString: @""];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:devTokenStr forKey:DEVICE_TOKEN];
    [defaults synchronize];
}

- (void)removeDeviceToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:DEVICE_TOKEN];
    [defaults synchronize];
}

- (void)sendFavoriteToProvider
{
    if (PROVIDER_URL == nil) {
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *deviceToken = [defaults objectForKey:DEVICE_TOKEN];
    if (deviceToken == nil) {
#if DEBUG
        NSLog(@"Doesn't have Device token.");
#endif // #if DEBUG
        return;
    }

    // お気に入り送信
    SendFavoritesToProviderOperation *operation =
        [[SendFavoritesToProviderOperation alloc] initWithDeviceToken:deviceToken];
    [sendFavoritesOperationQueue_ addOperation:operation];
}

#pragma mark - Private methods

- (void)channelFavoritesChanged:(NSNotification *)notification
{
    // お気に入りをプロバイダに送信
    [self sendFavoriteToProvider];
}

@end
