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

#import "Headline.h"

/// ねとらじのヘッドラインのURL DAT v2
#define NETLADIO_HEADLINE_DAT_V2_URL @"http://yp.ladio.net/stats/list.v2.dat"

@implementation Headline
{
@private
    NSArray *channels;
    NSMutableData *receivedData;
}

- (id)init
{
    if (self = [super init]) {
        channels = nil;
        receivedData = nil;
    }
    return self;
}

- (void)fetchHeadline
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_FETCH_HEADLINE_STARTED object:self];

    channels = nil;

    NSURL *url = [NSURL URLWithString:NETLADIO_HEADLINE_DAT_V2_URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:request delegate:self];
    if (conn) {
        receivedData = [NSMutableData data];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_FETCH_HEADLINE_FAILED object:self];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    receivedData = nil;
    NSLog(@"NetLadio fetch headline connection failed! Error - %@ %@",
            [error localizedDescription],
            [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_FETCH_HEADLINE_FAILED object:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"NetLadio fetch headline received. %d bytes received.", [receivedData length]);

    // 取得したデータをNSStringに変換し、1行ごとに分館してNSArrayに格納する
    NSString *data = [[NSString alloc] initWithData:receivedData encoding:NSShiftJISStringEncoding];
    NSArray *lines = [data componentsSeparatedByString:@"\n"];
    receivedData = nil;

    NSError *expError = nil;

    const NSRegularExpression *surlExp = [NSRegularExpression regularExpressionWithPattern:@"^SURL=(.*)" options:0 error:&expError];
    const NSRegularExpression *timsExp = [NSRegularExpression regularExpressionWithPattern:@"^TIMS=(.*)" options:0 error:&expError];
    const NSRegularExpression *srvExp = [NSRegularExpression regularExpressionWithPattern:@"^SRV=(.*)" options:0 error:&expError];
    const NSRegularExpression *prtExp = [NSRegularExpression regularExpressionWithPattern:@"^PRT=(.*)" options:0 error:&expError];
    const NSRegularExpression *mntExp = [NSRegularExpression regularExpressionWithPattern:@"^MNT=(.*)" options:0 error:&expError];
    const NSRegularExpression *typeExp = [NSRegularExpression regularExpressionWithPattern:@"^TYPE=(.*)" options:0 error:&expError];
    const NSRegularExpression *namExp = [NSRegularExpression regularExpressionWithPattern:@"^NAM=(.*)" options:0 error:&expError];
    const NSRegularExpression *gnlExp = [NSRegularExpression regularExpressionWithPattern:@"^GNL=(.*)" options:0 error:&expError];
    const NSRegularExpression *descExp = [NSRegularExpression regularExpressionWithPattern:@"^DESC=(.*)" options:0 error:&expError];
    const NSRegularExpression *djExp = [NSRegularExpression regularExpressionWithPattern:@"^DJ=(.*)" options:0 error:&expError];
    const NSRegularExpression *songExp = [NSRegularExpression regularExpressionWithPattern:@"^SONG=(.*)" options:0 error:&expError];
    const NSRegularExpression *urlExp = [NSRegularExpression regularExpressionWithPattern:@"^URL=(.*)" options:0 error:&expError];
    const NSRegularExpression *clnExp = [NSRegularExpression regularExpressionWithPattern:@"^CLN=(\\d+)" options:0 error:&expError];
    const NSRegularExpression *clnsExp = [NSRegularExpression regularExpressionWithPattern:@"^CLNS=(\\d+)" options:0 error:&expError];
    const NSRegularExpression *maxExp = [NSRegularExpression regularExpressionWithPattern:@"^MAX=(\\d+)" options:0 error:&expError];
    const NSRegularExpression *bitExp = [NSRegularExpression regularExpressionWithPattern:@"^BIT=(\\d+)" options:0 error:&expError];
    const NSRegularExpression *smplExp = [NSRegularExpression regularExpressionWithPattern:@"^SMPL=(\\d+)" options:0 error:&expError];
    const NSRegularExpression *chsExp = [NSRegularExpression regularExpressionWithPattern:@"^CHS=(\\d+)" options:0 error:&expError];

    NSMutableArray *channelList = [NSMutableArray array];
    Channel *channel = nil;

    for (NSString *line in lines) {
        if ([line length] == 0 && channel != nil) {
            [channelList addObject:channel];
            channel = nil;
            continue;
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [surlExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    [channel setSurlFromString:matchString];
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [timsExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    [channel setTimsFromString:matchString];
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [srvExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.srv = matchString;
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [prtExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.prt = [matchString intValue];
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [mntExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.mnt = matchString;
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [typeExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.type = matchString;
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [namExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.nam = matchString;
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [gnlExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.gnl = matchString;
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [descExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.desc = matchString;
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [djExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.dj = matchString;
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [songExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.song = matchString;
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [urlExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    [channel setUrlFromString:matchString];
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [clnExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.cln = [matchString intValue];
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [clnsExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.clns = [matchString intValue];
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [maxExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.max = [matchString intValue];
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [bitExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.bit = [matchString intValue];
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [smplExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.smpl = [matchString intValue];
                    continue;
                }
            }
        }

        if (expError != nil) {
            NSLog(@"Expression error : %@", expError);
        } else {
            NSTextCheckingResult *match = [chsExp firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match.numberOfRanges >= 2) {
                NSString *matchString = [line substringWithRange:[match rangeAtIndex:1]];
                if ([matchString length] > 0) {
                    if (channel == nil) {
                        channel = [[Channel alloc] init];
                    }
                    channel.chs = [matchString intValue];
                    continue;
                }
            }
        }
    }

    channels = [[NSArray alloc] initWithArray:channelList];

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_FETCH_HEADLINE_SUCEED object:self];
}

- (NSArray *)getChannels
{
    return [self getChannels:CHANNEL_SORT_TYPE_NONE searchWord:nil];
}

- (NSArray *)getChannels:(int)sortType
{
    return [self getChannels:sortType searchWord:nil];
}

- (NSArray *)getChannels:(int)sortType searchWord:(NSString*)searchWord
{
    NSMutableArray *result = [channels mutableCopy];

    // フィルタリング
    if (!([searchWord length] == 0)) {
        NSMutableArray *removeList = [[NSMutableArray alloc] init];
        for (Channel *channel in result) {
            if ([channel isMatch:[Headline splitStringByWhiteSpace:searchWord]] == NO) {
                [removeList addObject:channel];
            }
        }
        if ([removeList count] != 0) {
            for (Channel *removeCannel in removeList) {
                [result removeObject:removeCannel];
            }
        }
    }
    
    switch (sortType) {
        case CHANNEL_SORT_TYPE_NEWLY:
            return [result sortedArrayUsingSelector:@selector(compareNewly:)];
        case CHANNEL_SORT_TYPE_LISTENERS:
            return [result sortedArrayUsingSelector:@selector(compareListeners:)];
        case CHANNEL_SORT_TYPE_TITLE:
            return [result sortedArrayUsingSelector:@selector(compareTitle:)];
        case CHANNEL_SORT_TYPE_DJ:
            return [result sortedArrayUsingSelector:@selector(compareDj:)];
        case CHANNEL_SORT_TYPE_NONE:
        default:
            return result;
    }
}

/**
 * 指定した文字列を、ホワイトスペースで区切って配列にして返す
 *
 * @param 文字列
 * @return ホワイトスペースで区切った結果
 */
+ (NSArray*) splitStringByWhiteSpace:(NSString*)word
{
    // 文字列を空白文字で分割し、検索単語列を生成する
    NSCharacterSet *separator = [NSCharacterSet characterSetWithCharactersInString:@" \t　"];
    NSMutableArray *words = [[word componentsSeparatedByCharactersInSet:separator] mutableCopy];

    // 空白文字を除外する
    NSMutableArray *removeList = [[NSMutableArray alloc] init];
    for (NSString* word in words) {
        if ([word length] == 0) {
            [removeList addObject:word];
        }
    }
    if ([removeList count] != 0) {
        for (NSString *removeWord in removeList) {
            [words removeObject:removeWord];
        }
    }

    return words;
}

- (Channel*)getChannel:(NSURL*)playUrl
{
    if (playUrl == nil) {
        return nil;
    }
    
    for (Channel* c in channels) {
        NSURL* url = [c getPlayUrl];
        if([[playUrl absoluteString] isEqualToString:[url absoluteString]]) {
            return c;
        }
    }
    return nil;
}
@end
