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
#import "RadioLib/RadioLib.h"
#import "SendFavoritesToProviderOperation.h"

@implementation SendFavoritesToProviderOperation
{
@private
    /// デバイストークン
    NSString *deviceToken_;
}

- (id)initWithDeviceToken:(NSString *)deviceToken
{
    if (self = [self init]) {
        deviceToken_ = deviceToken;
    }
    return self;
}

#pragma mark - NSOperation methods

- (void)main
{
    if (PROVIDER_URL == nil) {
        return;
    }
    if (deviceToken_ == nil) {
        return;
    }

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
                      deviceToken_, lang, favoritesJson];
    
    NSURL *url = [NSURL URLWithString:PROVIDER_URL];
    NSData *requestData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod: @"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody: requestData];

    // このクラスがNSOperationを継承したクラスなので、サーバにお気に入りの情報を同期で送信する。
    // また、iOS5環境だと、非同期通信だと正常に送信できていなかったため、同期で送信している。
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
}

@end
