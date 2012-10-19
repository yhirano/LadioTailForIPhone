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
#import "Ladiolib/LadioLib.h"
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
        favoritesJson = [[NSString alloc] initWithFormat:@"%@\"%@\"", favoritesJson, channel.mnt];
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
    
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:request delegate:self];
    
    if (conn == nil) {
        NSLog(@"Failed sending favorite(s) to the provider.");
    }
}

#pragma mark - NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Failed sending favorite(s) to the provider. Error: %@ / %@",
          [error localizedDescription],
          [error userInfo][NSURLErrorFailingURLStringErrorKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Succeed sending favorite(s) to the provider.");
}

@end
