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

@property (strong) NSString *tag;

@property (strong) NSString *value;

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
static GRMustacheTemplate *channelLinkHtmlTemplate = nil;

+ (NSString *)descriptionHtml:(Channel *)channel
{
    if (channel == nil) {
        return nil;
    }

    NSMutableArray *channelInfo = [[NSMutableArray alloc] init];

    NSString *tag;
    NSString *value;

    // タイトル
    value = channel.nam;
    if (!([value length] == 0)) {
        tag = NSLocalizedString(@"Title", @"タイトル");
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // DJ
    value = channel.dj;
    if (!([value length] == 0)) {
        tag = NSLocalizedString(@"DJ", @"DJ");
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // ジャンル
    value = channel.gnl;
    if (!([value length] == 0)) {
        tag = NSLocalizedString(@"Genre", @"ジャンル");
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // 詳細
    value = channel.desc;
    if (!([value length] == 0)) {
        tag = NSLocalizedString(@"Description", @"詳細");
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // 曲
    value = channel.song;
    if (!([value length] == 0)) {
        tag = NSLocalizedString(@"Song", @"曲");
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // URL
    value = [channel.url absoluteString];
    if (!([value length] == 0)) {
        if (channelLinkHtmlTemplate == nil) {
            NSError *error = nil;
            channelLinkHtmlTemplate = [GRMustacheTemplate templateFromResource:@"ChannelLinkHtml"
                                                                 withExtension:@"mustache"
                                                                        bundle:[NSBundle mainBundle]
                                                                         error:&error];
            if (error != nil) {
                NSLog(@"GRMustacheTemplate parse error. Error: %@", [error localizedDescription]);
            }
        }
        value = [channelLinkHtmlTemplate renderObject:@{@"url":value}];
        // 何も返ってこない場合（多分実装エラー）は何もしない
        if (value != nil) {
            tag =  NSLocalizedString(@"Site", @"サイト");
            [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
        }
    }
    // リスナー
    {
        if (channel.cln != CHANNEL_UNKNOWN_LISTENER_NUM
            || channel.clns != CHANNEL_UNKNOWN_LISTENER_NUM
            || channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
            // リスナー数
            tag = NSLocalizedString(@"Listeners", @"リスナー数");
            value = @"";
            if (channel.cln != CHANNEL_UNKNOWN_LISTENER_NUM) {
                value = [NSString stringWithFormat:@"%@ %d",
                     NSLocalizedString(@"Listeners", @"リスナー数"),
                     channel.cln];
                if (channel.clns != CHANNEL_UNKNOWN_LISTENER_NUM || channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
                    value = [NSString stringWithFormat:@"%@%@", value, @" / "];
                }
            }
            
            // 最大リスナー数
            if (channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
                value = [NSString stringWithFormat:@"%@%@ %d",
                         value,
                         NSLocalizedString(@"Max", @"最大"),
                         channel.max];
                if (channel.clns != CHANNEL_UNKNOWN_LISTENER_NUM) {
                    value = [NSString stringWithFormat:@"%@%@", value, @" / "];
                }
            }
            
            // 述べリスナー数
            if (channel.clns != CHANNEL_UNKNOWN_LISTENER_NUM) {
                value = [NSString stringWithFormat:@"%@%@ %d",
                         value,
                         NSLocalizedString(@"Total", @"述べ"),
                         channel.clns];
            }

            [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
        }
    }
    // 開始時刻
    value = channel.timsToString;
    if (!([value length] == 0)) {
        NSString *tag =  NSLocalizedString(@"At", @"開始時刻");
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // フォーマット
    {
        if (channel.bit != CHANNEL_UNKNOWN_BITRATE_NUM
            || channel.chs != CHANNEL_UNKNOWN_CHANNEL_NUM
            || channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM
            || !([channel.type length] == 0)) {
            tag = NSLocalizedString(@"Format", @"フォーマット");
            value = @"";
            // ビットレート
            if (channel.bit != CHANNEL_UNKNOWN_BITRATE_NUM) {
                value = [NSString stringWithFormat:@"%dkbps", channel.bit];
                if (channel.chs != CHANNEL_UNKNOWN_CHANNEL_NUM
                    || channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM
                    || !([channel.type length] == 0)) {
                    value = [NSString stringWithFormat:@"%@%@", value, @" / "];
                }
            }
            
            // チャンネル数
            if (channel.chs != CHANNEL_UNKNOWN_CHANNEL_NUM) {
                NSString *chsStr;
                switch (channel.chs) {
                    case 1:
                        chsStr = NSLocalizedString(@"Mono", @"モノラル");
                        break;
                    case 2:
                        chsStr = NSLocalizedString(@"Stereo", @"ステレオ");
                        break;
                    default:
                        chsStr = [NSString stringWithFormat:@"%dch", channel.chs];
                        break;
                }
                value = [NSString stringWithFormat:@"%@%@", value, chsStr];
                if (channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM || !([channel.type length] == 0)) {
                    value = [NSString stringWithFormat:@"%@%@", value, @" / "];
                }
            }
            
            // サンプリングレート数
            if (channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM) {
                value = [NSString stringWithFormat:@"%@%dHz", value, channel.smpl];
                if (!([channel.type length] == 0)) {
                    value = [NSString stringWithFormat:@"%@%@", value, @" / "];
                }
            }

            // 種類
            if (!([channel.type length] == 0)) {
                value = [NSString stringWithFormat:@"%@%@", value, channel.type];
            }

            [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
        }
    }
    // マウント
    value = channel.mnt;
    if (!([value length] == 0)) {
        tag = NSLocalizedString(@"Mount", @"マウント");
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
#if DEBUG
    // 番組の詳細内容を表示するサイトのURL
    value = [channel.surl absoluteString];
    if (!([value length] == 0)) {
        NSString *tag = @"- SURL";
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // 配信サーバホスト名
    value = channel.srv;
    if (!([value length] == 0)) {
        NSString *tag = @"- SRV";
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // 配信サーバポート番号
    value = [[NSNumber numberWithInt:channel.prt] stringValue];;
    if (!([value length] == 0)) {
        NSString *tag = @"- PRT";
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // お気に入り
    value = (channel.favorite ? @"YES" : @"NO");
    if (!([value length] == 0)) {
        NSString *tag = @"- Favorite";
        [channelInfo addObject:[[ChannelInfo alloc] initWithTag:tag value:value]];
    }
    // 再生URL
    value = [[channel playUrl] absoluteString];
    if (!([value length] == 0)) {
        NSString *tag = @"- PlayUrl";
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
