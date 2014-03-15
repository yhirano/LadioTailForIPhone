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

#import "LadioTailConfig.h"
#import "RadioLib/RadioLib.h"
#import "ApnsStorage.h"

/// デバイストークンを記憶するためのキー
#define DEVICE_TOKEN @"DEVICE_TOKEN"

@implementation ApnsStorage
{
    dispatch_queue_t sendFavoritesDispatchQueue_;
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
        const char *sendFavoritesDispatchQueueName = [[[[NSBundle mainBundle] bundleIdentifier]
                                                         stringByAppendingString:@".SendFavoritesToProviderDispatchQueue"]
                                                             UTF8String];
        sendFavoritesDispatchQueue_ = dispatch_queue_create(sendFavoritesDispatchQueueName, NULL);
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
    dispatch_async(sendFavoritesDispatchQueue_, ^ {
        NSArray *favorites = [[FavoriteManager sharedInstance].favorites allValues];
        NSLog(@"Send %d favorite(s) to the provider.", [favorites count]);
        
        // 端末の言語設定を取得
        NSArray *languages = [NSLocale preferredLanguages];
        NSString *lang = @"";
        if (languages != nil && [languages count] > 0) {
            lang = [languages objectAtIndex:0];
        }
        
        NSString *favoritesJson = @"";
        // お気に入りのマウントをカンマ区切りで結合
        for (int i = 0; i < [favorites count]; ++i) {
            Favorite *favorite = [favorites objectAtIndex:i];
            Channel *channel = favorite.channel;
#if defined(LADIO_TAIL)
            favoritesJson = [[NSString alloc] initWithFormat:@"%@\"%@\"", favoritesJson, channel.mnt];
#elif defined(RADIO_EDGE)
            favoritesJson = [[NSString alloc] initWithFormat:@"%@\"%@\"", favoritesJson, [channel.listenUrl absoluteString]];
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif
            // Add ','.
            if (i < [favorites count] - 1) {
                favoritesJson = [[NSString alloc] initWithFormat:@"%@,", favoritesJson];
            }
        }
        
        NSString *json = [[NSString alloc] initWithFormat:@"{\"device_token\":\"%@\",\"lang\":\"%@\",\"favorites\":[%@]}",
                          deviceToken, lang, favoritesJson];
        
        NSURL *url = [NSURL URLWithString:PROVIDER_URL];
        NSData *requestData = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod: @"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setHTTPBody: requestData];
        
        // NSURLConnectionの非同期通信は、メインスレッドで行う必要があるらしいが、このNSOperationは別スレッドで行っているため、
        // ここでは非同期通信にする。
        NSURLResponse* response = nil;
        NSError* error = nil;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (error != nil) {
            NSLog(@"Failed sending favorite(s) to the provider. Error: %@", [error localizedDescription]);
        }
        if (response == nil) {
            NSLog(@"Failed sending favorite(s) to the provider. Empty responce.");
        } else {
            NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            // 通信に成功した場合はサーバはステータスコード200を返す
            if (statusCode == 200) {
                NSLog(@"Succeed sending favorite(s) to the provider.");
            } else {
                NSLog(@"Failed sending favorite(s) to the provider. HTTP Status code: %d", statusCode);
            }
        }
    });
}

#pragma mark - Private methods

- (void)channelFavoritesChanged:(NSNotification *)notification
{
    // お気に入りをプロバイダに送信
    [self sendFavoriteToProvider];
}

@end
