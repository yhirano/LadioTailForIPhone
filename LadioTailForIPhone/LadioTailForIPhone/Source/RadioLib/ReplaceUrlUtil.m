/*
 * Copyright (c) 2012-2017 Yuichi Hirano
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

#import "ReplaceUrlUtil.h"

@implementation ReplaceUrlUtil

static NSString *urlLivedoorJbbsThreadPattern = @"^http://jbbs\\.livedoor\\.jp/bbs/read\\.cgi/(\\w+)/(\\d+)/(\\d+)/(.*)";
static NSString *urlLivedoorJbbsBbsPattern = @"^http://jbbs\\.livedoor\\.jp/(\\w+)/(\\d+)/(.*)";

+ (NSURL *)urlForSmartphone:(NSURL *)url
{
    NSURL *result = url;
    NSString *urlString = [url absoluteString];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // したらば スマートフォン用サイトを閲覧するか
    BOOL browseSmartphoneSiteLivedoorJbbs = [defaults boolForKey:@"browse_smartphone_site_livedoor_jbbs"];
    
    if (browseSmartphoneSiteLivedoorJbbs) {
        static dispatch_once_t onceToken = 0;
        static NSRegularExpression *urlLivedoorJbbsThreadExp = nil;
        static NSRegularExpression *urlLivedoorJbbsBbsExp = nil;
        dispatch_once(&onceToken, ^{
            NSError *error = nil;
            urlLivedoorJbbsThreadExp = [NSRegularExpression regularExpressionWithPattern:urlLivedoorJbbsThreadPattern
                                                                                 options:0
                                                                                   error:&error];
            if (error != nil) {
                NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
            }

            error = nil;
            urlLivedoorJbbsBbsExp = [NSRegularExpression regularExpressionWithPattern:urlLivedoorJbbsBbsPattern
                                                                              options:0
                                                                                error:&error];
            if (error != nil) {
                NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
            }
        });
        
        // 解析
        NSString *directory = nil;
        NSString *bbs = nil;
        NSString *thread = nil;
        NSTextCheckingResult *match;
        match = [urlLivedoorJbbsThreadExp firstMatchInString:urlString options:0 range:NSMakeRange(0, urlString.length)];
        if (match.numberOfRanges >= 3) {
            directory = [urlString substringWithRange:[match rangeAtIndex:1]];
            bbs = [urlString substringWithRange:[match rangeAtIndex:2]];
            if (match.numberOfRanges >= 4) {
                thread = [urlString substringWithRange:[match rangeAtIndex:3]];
            }
        } else {
            match = [urlLivedoorJbbsBbsExp firstMatchInString:urlString options:0 range:NSMakeRange(0, urlString.length)];
            if (match.numberOfRanges >= 3) {
                directory = [urlString substringWithRange:[match rangeAtIndex:1]];
                bbs = [urlString substringWithRange:[match rangeAtIndex:2]];
            }
        }
        
        // 書き換え
        if ([directory length] != 0 && [bbs length] != 0 && [thread length] != 0) {
            urlString = [[NSString alloc] initWithFormat:@"http://jbbs.livedoor.jp/bbs/lite/read.cgi/%@/%@/%@/",
                         directory, bbs, thread];
            result = [[NSURL alloc] initWithString:urlString];
        } else if ([directory length] != 0 && [bbs length] != 0) {
            urlString = [[NSString alloc] initWithFormat:@"http://jbbs.livedoor.jp/bbs/lite/subject.cgi/%@/%@/",
                         directory, bbs];
            result = [[NSURL alloc] initWithString:urlString];
        }
    }
    
    return result;
}

@end
