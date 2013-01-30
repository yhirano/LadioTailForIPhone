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

#import "../../GRMustache/GRMustache.h"
#import "ChannelHtml.h"

@class ChannelInfo;

@interface ChannelInfo : NSObject

@property (nonatomic, strong) NSString *tag;

@property (nonatomic, strong) NSString *value;

- (id)initWithTag:(NSString *)tag value:(NSString *)value;

@end

@implementation ChannelInfo

- (id)initWithTag:(NSString *)tag value:(NSString *)value
{
    if (self = [self init]) {
        _tag = tag;
        _value = value;
    }
    return self;
}

@end

@implementation ChannelHtml

static GRMustacheTemplate *channelPageHtmlTemplate = nil;

+ (NSString *)descriptionHtml:(Channel *)channel
{
    if (channel == nil) {
        return nil;
    }

    NSMutableArray *channelInfo = [[NSMutableArray alloc] init];

    NSString *tag;
    NSString *value;

    // Server Name
    value = channel.serverName;
    if (!([value length] == 0)) {
        tag = NSLocalizedString(@"Title", @"タイトル");
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // Genre
    value = channel.genre;
    if (!([value length] == 0)) {
        tag = NSLocalizedString(@"Genre", @"ジャンル");
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // Current Song
    value = channel.currentSong;
    if (!([value length] == 0)) {
        tag = NSLocalizedString(@"Song", @"曲");
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // ビットレート
    if (channel.bitrate != 0) {
        tag =  NSLocalizedString(@"Bitrate", @"ビットレート");
        value = [NSString stringWithFormat:@"%dkbps", channel.bitrate];
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // 種類
    value = channel.serverType;
    if (!([value length] == 0)) {
        tag =  NSLocalizedString(@"Format", @"フォーマット");
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
#if DEBUG
    // fid
    value = [[NSString alloc] initWithFormat:@"%d", channel.fid];
    if (!([value length] == 0)) {
        NSString *tag = @"- fid";
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // Listen URL
    value = [channel.listenUrl absoluteString];
    if (!([value length] == 0)) {
        NSString *tag = @"- listen_url";
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // Channels
    value = [[NSString alloc] initWithFormat:@"%d", channel.channels];
    if (!([value length] == 0)) {
        NSString *tag = @"- channels";
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // SampleRate
    value = [[NSString alloc] initWithFormat:@"%d", channel.sampleRate];
    if (!([value length] == 0)) {
        NSString *tag = @"- samplerate";
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // お気に入り
    value = (channel.favorite ? @"YES" : @"NO");
    if (!([value length] == 0)) {
        NSString *tag = @"- Favorite";
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
#endif /* #if DEBUG */

    NSDictionary *data = @{@"channels": channelInfo};

    if (channelPageHtmlTemplate == nil) {
        NSError *error = nil;
        channelPageHtmlTemplate = [GRMustacheTemplate templateFromResource:@"ChannelPageHtml"
                                                             withExtension:@"mustache"
                                                                    bundle:[NSBundle mainBundle]
                                                                     error:&error];
        if (error != nil) {
            NSLog(@"GRMustacheTemplate parse error. Error: %@", [error localizedDescription]);
        }
    }
    NSString *result = [channelPageHtmlTemplate renderObject:data];
    return result;
}

@end
