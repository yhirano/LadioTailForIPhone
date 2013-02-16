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

#import "../../../GRMustache/GRMustache.h"
#import "../../Common/Html/TempleteInfo.h"
#import "ChannelHtml.h"

@implementation ChannelHtml

+ (NSString *)descriptionHtml:(Channel *)channel
{
    if (channel == nil) {
        return nil;
    }

    TempleteInfo *templeteInfo = [[TempleteInfo alloc] init];
    templeteInfo.title = channel.serverName;
    if ([channel.genre length] > 0) {
        templeteInfo.subTitle = [[NSLocalizedString(@"Genre", @"ジャンル")
                                  stringByAppendingString:@": "]
                                  stringByAppendingString:channel.genre];
    }

    NSMutableArray *info = [[NSMutableArray alloc] init];

    NSString *tag;
    NSString *value;

    // Current Song
    value = channel.currentSong;
    if (!([value length] == 0)) {
        tag = NSLocalizedString(@"Song", @"曲");
        [info addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // ビットレート
    if (channel.bitrate != 0) {
        tag =  NSLocalizedString(@"Bitrate", @"ビットレート");
        value = [NSString stringWithFormat:@"%dkbps", channel.bitrate];
        [info addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // 種類
    value = channel.serverType;
    if (!([value length] == 0)) {
        tag =  NSLocalizedString(@"Format", @"フォーマット");
        [info addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }

    templeteInfo.info = [NSArray arrayWithArray:info];

#if DEBUG
    NSMutableArray *debugInfo = [[NSMutableArray alloc] init];

    // fid
    value = [[NSString alloc] initWithFormat:@"%d", channel.fid];
    if (!([value length] == 0)) {
        NSString *tag = @"fid";
        [debugInfo addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // Listen URL
    value = [channel.listenUrl absoluteString];
    if (!([value length] == 0)) {
        NSString *tag = @"listen_url";
        [debugInfo addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // Channels
    value = [[NSString alloc] initWithFormat:@"%d", channel.channels];
    if (!([value length] == 0)) {
        NSString *tag = @"channels";
        [debugInfo addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // SampleRate
    value = [[NSString alloc] initWithFormat:@"%d", channel.sampleRate];
    if (!([value length] == 0)) {
        NSString *tag = @"samplerate";
        [debugInfo addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // お気に入り
    value = (channel.favorite ? @"YES" : @"NO");
    if (!([value length] == 0)) {
        NSString *tag = @"Favorite";
        [debugInfo addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }

    templeteInfo.debugInfo = [NSArray arrayWithArray:debugInfo];
#endif /* #if DEBUG */

    NSDictionary *data = @{@"templete_info": templeteInfo};

    static GRMustacheTemplate *channelPageHtmlTemplate = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Resources" ofType:@"bundle"];
        channelPageHtmlTemplate = [GRMustacheTemplate templateFromResource:@"templete/ChannelPageHtml"
                                                                    bundle:[NSBundle bundleWithPath:bundlePath]
                                                                     error:&error];
        if (error != nil) {
            NSLog(@"GRMustacheTemplate parse error. Error: %@", [error localizedDescription]);
        }
    });

    NSError *error = nil;
    NSString *result = [channelPageHtmlTemplate renderObject:data error:&error];
    if (error != nil) {
        NSLog(@"GRMustacheTemplate render error. Error: %@", [error localizedDescription]);
    }

    return result;
}

@end
