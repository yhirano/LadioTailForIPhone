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
#import "FavoriteHtml.h"

@implementation FavoriteHtml

+ (NSString *)descriptionHtml:(Favorite *)favorite
{
    Channel *channel = favorite.channel;
    if (favorite == nil || channel == nil) {
        return nil;
    }
    
    TempleteInfo *templeteInfo = [[TempleteInfo alloc] init];
    templeteInfo.title = channel.nam;
    if ([channel.dj length] > 0) {
        templeteInfo.subTitle = [[NSLocalizedString(@"DJ", @"DJ")
                                  stringByAppendingString:@": "]
                                 stringByAppendingString:channel.dj];
    }
    
    NSMutableArray *info = [[NSMutableArray alloc] init];
    
    NSString *tag;
    NSString *value;

    // ジャンル
    value = channel.gnl;
    if ([value length] > 0) {
        tag = NSLocalizedString(@"Genre", @"ジャンル");
        [info addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // 詳細
    value = channel.desc;
    if ([value length] > 0) {
        tag = NSLocalizedString(@"Description", @"詳細");
        [info addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // 曲
    value = channel.song;
    if ([value length] > 0) {
        tag = NSLocalizedString(@"Song", @"曲");
        [info addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // URL
    value = [channel.url absoluteString];
    if ([value length] > 0) {
        static GRMustacheTemplate *channelLinkHtmlTemplate = nil;
        static dispatch_once_t onceToken = 0;
        dispatch_once(&onceToken, ^{
            NSError *error = nil;
            NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Resources" ofType:@"bundle"];
            channelLinkHtmlTemplate = [GRMustacheTemplate templateFromResource:@"templete/ChannelLinkHtml"
                                                                        bundle:[NSBundle bundleWithPath:bundlePath]
                                                                         error:&error];
            if (error != nil) {
                NSLog(@"GRMustacheTemplate parse error. Error: %@", [error localizedDescription]);
            }
        });
        NSError *error = nil;
        value = [channelLinkHtmlTemplate renderObject:@{@"url":value} error:&error];
        if (error != nil) {
            NSLog(@"GRMustacheTemplate render error. Error: %@", [error localizedDescription]);
        } else {
            tag =  NSLocalizedString(@"Site", @"サイト");
            [info addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
        }
    }
    // ビットレート
    if (channel.bit != CHANNEL_UNKNOWN_BITRATE_NUM) {
        tag =  NSLocalizedString(@"Bitrate", @"ビットレート");
        value = [NSString stringWithFormat:@"%dkbps", channel.bit];
        [info addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // チャンネル数
    if (channel.chs != CHANNEL_UNKNOWN_CHANNEL_NUM) {
        tag =  NSLocalizedString(@"Stereo/Mono", @"ステレオ/モノラル");
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
        value = [NSString stringWithFormat:@"%@", chsStr];
        [info addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // サンプリングレート
    if (channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM) {
        tag =  NSLocalizedString(@"Samplerate", @"サンプリングレート");
        value = [NSString stringWithFormat:@"%dHz", channel.smpl];
        [info addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // フォーマット
    value = channel.type;
    if ([value length] > 0) {
        tag =  NSLocalizedString(@"Format", @"フォーマット");
        [info addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // マウント
    value = channel.mnt;
    if ([value length] > 0) {
        tag = NSLocalizedString(@"Mount", @"マウント");
        [info addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }

    templeteInfo.info = [NSArray arrayWithArray:info];

#if DEBUG
    NSMutableArray *debugInfo = [[NSMutableArray alloc] init];

    // 番組の詳細内容を表示するサイトのURL
    value = [channel.surl absoluteString];
    if ([value length] > 0) {
        NSString *tag = @"SURL";
        [debugInfo addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // 配信サーバホスト名
    value = channel.srv;
    if ([value length] > 0) {
        NSString *tag = @"SRV";
        [debugInfo addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // 配信サーバポート番号
    value = [[NSNumber numberWithInt:channel.prt] stringValue];;
    if ([value length] > 0) {
        NSString *tag = @"PRT";
        [debugInfo addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // リスナー数
    {
        if (channel.cln != CHANNEL_UNKNOWN_LISTENER_NUM
            || channel.clns != CHANNEL_UNKNOWN_LISTENER_NUM
            || channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
            // リスナー数
            tag = @"cln/clns/mnt";
            value = @"";
            if (channel.cln != CHANNEL_UNKNOWN_LISTENER_NUM) {
                value = [NSString stringWithFormat:@"%@ %d",
                         NSLocalizedString(@"Listeners", @"リスナー数"),
                         channel.cln];
                if (channel.clns != CHANNEL_UNKNOWN_LISTENER_NUM || channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
                    value = [NSString stringWithFormat:@"%@%@", value, @" / "];
                }
            }
            
            // 述べリスナー数
            if (channel.clns != CHANNEL_UNKNOWN_LISTENER_NUM) {
                value = [NSString stringWithFormat:@"%@%@ %d",
                         value,
                         NSLocalizedString(@"Total", @"述べ"),
                         channel.clns];
                if (channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
                    value = [NSString stringWithFormat:@"%@%@", value, @" / "];
                }
            }
            
            // 最大リスナー数
            if (channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
                value = [NSString stringWithFormat:@"%@%@ %d",
                         value,
                         NSLocalizedString(@"Max", @"最大"),
                         channel.max];
            }
            
            [debugInfo addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
        }
    }
    // 開始時刻
    value = channel.timsToString;
    if ([value length] > 0) {
        NSString *tag =  NSLocalizedString(@"At", @"開始時刻");
        [debugInfo addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // お気に入り
    value = (channel.favorite ? @"YES" : @"NO");
    if ([value length] > 0) {
        NSString *tag = @"Favorite";
        [debugInfo addObject:[[TempleteSubInfo alloc] initWithTag:tag value:value]];
    }
    // 再生URL
    value = [[channel playUrl] absoluteString];
    if ([value length] > 0) {
        NSString *tag = @"- PlayUrl";
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
