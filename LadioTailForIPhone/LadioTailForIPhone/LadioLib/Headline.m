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

/// ヘッドラインのインスタンス
static Headline *instance = nil;

@implementation Headline
{
@private
    /// 番組データリスト
    NSArray *channels_;
    /// channelsのロック
    NSObject *channelsLock_;
    /// 受信データバッファ
    NSMutableData *receivedData_;
    /// ヘッドラインを取得中か
    BOOL isFetching_;
    /// isFetchingのロック
    NSObject *isFetchingLock_;
}

+ (Headline *)sharedInstance
{
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[Headline alloc] init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        channelsLock_ = [[NSObject alloc] init];
        isFetching_ = NO;
        isFetchingLock_ = [[NSObject alloc] init];
    }
    return self;
}

- (void) dealloc
{
    isFetchingLock_ = nil;
    channelsLock_ = nil;
}

- (void)fetchHeadline
{
    // ヘッドライン取得中は何もしないで戻る
    @synchronized (isFetchingLock_) {
        if (isFetching_) {
            NSLog(@"fetchHeadline call isn't processing. Fetching NetLadio headline now.");
            return;
        }
        // ヘッドライン取得中のフラグを立てる
        isFetching_ = YES;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:LadioLibHeadlineDidStartLoadNotification object:self];

    NSURL *url = [NSURL URLWithString:NETLADIO_HEADLINE_DAT_V2_URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:request delegate:self];
    if (conn) {
        receivedData_ = [NSMutableData data];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:LadioLibHeadlineFailLoadNotification object:self];
    }
}

- (BOOL)isFetchingHeadline;
{
    @synchronized (isFetchingLock_) {
        return isFetching_;
    }
}

- (NSArray*)parseHeadline:(NSArray*)lines
{
    NSMutableArray *result = [NSMutableArray array];

    NSError *surlExpError, *timsExpError, *srvExpError, *prtExpError, *mntExpError, *typeExpError, *namExpError,
        *gnlExpError, *descExpError, *djExpError, *songExpError, *urlExpError, *clnExpError, *clnsExpError,
        *maxExpError, *bitExpError, *smplExpError, *chsExpError;
    surlExpError = timsExpError = srvExpError = prtExpError = mntExpError = typeExpError = namExpError = gnlExpError =
        descExpError = djExpError = songExpError = urlExpError = clnExpError = clnsExpError = maxExpError =
        bitExpError = smplExpError = chsExpError = nil;

    NSRegularExpression *surlExp =
        [NSRegularExpression regularExpressionWithPattern:@"^SURL=(.*)" options:0 error:&surlExpError];
    NSRegularExpression *timsExp =
        [NSRegularExpression regularExpressionWithPattern:@"^TIMS=(.*)" options:0 error:&timsExpError];
    NSRegularExpression *srvExp =
        [NSRegularExpression regularExpressionWithPattern:@"^SRV=(.*)" options:0 error:&srvExpError];
    NSRegularExpression *prtExp =
        [NSRegularExpression regularExpressionWithPattern:@"^PRT=(.*)" options:0 error:&prtExpError];
    NSRegularExpression *mntExp =
        [NSRegularExpression regularExpressionWithPattern:@"^MNT=(.*)" options:0 error:&mntExpError];
    NSRegularExpression *typeExp =
        [NSRegularExpression regularExpressionWithPattern:@"^TYPE=(.*)" options:0 error:&typeExpError];
    NSRegularExpression *namExp =
        [NSRegularExpression regularExpressionWithPattern:@"^NAM=(.*)" options:0 error:&namExpError];
    NSRegularExpression *gnlExp =
        [NSRegularExpression regularExpressionWithPattern:@"^GNL=(.*)" options:0 error:&gnlExpError];
    NSRegularExpression *descExp =
        [NSRegularExpression regularExpressionWithPattern:@"^DESC=(.*)" options:0 error:&descExpError];
    NSRegularExpression *djExp =
        [NSRegularExpression regularExpressionWithPattern:@"^DJ=(.*)" options:0 error:&djExpError];
    NSRegularExpression *songExp =
        [NSRegularExpression regularExpressionWithPattern:@"^SONG=(.*)" options:0 error:&songExpError];
    NSRegularExpression *urlExp =
        [NSRegularExpression regularExpressionWithPattern:@"^URL=(.*)" options:0 error:&urlExpError];
    NSRegularExpression *clnExp =
        [NSRegularExpression regularExpressionWithPattern:@"^CLN=(\\d+)" options:0 error:&clnExpError];
    NSRegularExpression *clnsExp =
        [NSRegularExpression regularExpressionWithPattern:@"^CLNS=(\\d+)" options:0 error:&clnsExpError];
    NSRegularExpression *maxExp =
        [NSRegularExpression regularExpressionWithPattern:@"^MAX=(\\d+)" options:0 error:&maxExpError];
    NSRegularExpression *bitExp =
        [NSRegularExpression regularExpressionWithPattern:@"^BIT=(\\d+)" options:0 error:&bitExpError];
    NSRegularExpression *smplExp =
        [NSRegularExpression regularExpressionWithPattern:@"^SMPL=(\\d+)" options:0 error:&smplExpError];
    NSRegularExpression *chsExp =
        [NSRegularExpression regularExpressionWithPattern:@"^CHS=(\\d+)" options:0 error:&chsExpError];

    Channel *channel = nil;
    
    for (NSString *line in lines) {
        if ([line length] == 0 && channel != nil) {
            [result addObject:channel];
            channel = nil;
            continue;
        }

        if (surlExpError != nil) {
            NSLog(@"Expression error : %@", surlExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:surlExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                [channel setSurlFromString:matchString];
                continue;
            }
        }

        if (timsExpError != nil) {
            NSLog(@"Expression error : %@", timsExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:timsExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                [channel setTimsFromString:matchString];
                continue;
            }
        }

        if (srvExpError != nil) {
            NSLog(@"Expression error : %@", srvExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:srvExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.srv = matchString;
                continue;
            }
        }

        if (prtExpError != nil) {
            NSLog(@"Expression error : %@", prtExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:prtExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.prt = [matchString intValue];
                continue;
            }
        }

        if (mntExpError != nil) {
            NSLog(@"Expression error : %@", mntExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:mntExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.mnt = matchString;
                continue;
            }
        }

        if (typeExpError != nil) {
            NSLog(@"Expression error : %@", typeExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:typeExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.type = matchString;
                continue;
            }
        }

        if (namExpError != nil) {
            NSLog(@"Expression error : %@", namExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:namExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.nam = matchString;
                continue;
            }
        }

        if (gnlExpError != nil) {
            NSLog(@"Expression error : %@", gnlExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:gnlExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.gnl = matchString;
                continue;
            }
        }

        if (descExpError != nil) {
            NSLog(@"Expression error : %@", descExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:descExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.desc = matchString;
                continue;
            }
        }

        if (djExpError != nil) {
            NSLog(@"Expression error : %@", djExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:djExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.dj = matchString;
                continue;
            }
        }

        if (songExpError != nil) {
            NSLog(@"Expression error : %@", songExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:songExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.song = matchString;
                continue;
            }
        }

        if (urlExpError != nil) {
            NSLog(@"Expression error : %@", urlExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:urlExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                [channel setUrlFromString:matchString];
                continue;
            }
        }

        if (clnExpError != nil) {
            NSLog(@"Expression error : %@", clnExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:clnExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.cln = [matchString intValue];
                continue;
            }
        }

        if (clnsExpError != nil) {
            NSLog(@"Expression error : %@", clnsExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:clnsExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.clns = [matchString intValue];
                continue;
            }
        }

        if (maxExpError != nil) {
            NSLog(@"Expression error : %@", maxExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:maxExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.max = [matchString intValue];
                continue;
            }
        }

        if (bitExpError != nil) {
            NSLog(@"Expression error : %@", bitExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:bitExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.bit = [matchString intValue];
                continue;
            }
        }

        if (smplExpError != nil) {
            NSLog(@"Expression error : %@", smplExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:smplExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.smpl = [matchString intValue];
                continue;
            }
        }

        if (chsExpError != nil) {
            NSLog(@"Expression error : %@", chsExpError);
        } else {
            NSString *matchString = [self parseLine:line expression:chsExp];
            if ([matchString length] > 0) {
                if (channel == nil) {
                    channel = [[Channel alloc] init];
                }
                channel.chs = [matchString intValue];
                continue;
            }
        }
    }

    return result;
}

- (NSString *)parseLine:(NSString *)line expression:(NSRegularExpression *)expression
{
    NSString *result = nil;
    NSTextCheckingResult *match = [expression firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
    if (match.numberOfRanges >= 2) {
        result = [line substringWithRange:[match rangeAtIndex:1]];
    }
    return result;
}

- (NSArray *)channels
{
    return [self channels:ChannelSortTypeNone searchWord:nil];
}

- (NSArray *)channels:(ChannelSortType)sortType
{
    return [self channels:sortType searchWord:nil];
}

- (NSArray *)channels:(ChannelSortType)sortType searchWord:(NSString *)searchWord
{
    NSMutableArray *result = nil;
    @synchronized (channelsLock_) {
        result = [channels_ mutableCopy];
#if DEBUG
        NSLog(@"%@'s copied channels for return channels. There are %d channels.",
              NSStringFromClass([self class]), [result count]);
#endif /* #if DEBUG */
    }

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
        case ChannelSortTypeNewly:
            return [result sortedArrayUsingSelector:@selector(compareNewly:)];
        case ChannelSortTypeListeners:
            return [result sortedArrayUsingSelector:@selector(compareListeners:)];
        case ChannelSortTypeTitle:
            return [result sortedArrayUsingSelector:@selector(compareTitle:)];
        case ChannelSortTypeDj:
            return [result sortedArrayUsingSelector:@selector(compareDj:)];
        case ChannelSortTypeNone:
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
+ (NSArray *)splitStringByWhiteSpace:(NSString *)word
{
    // 文字列を空白文字で分割し、検索単語列を生成する
    NSCharacterSet *separator = [NSCharacterSet characterSetWithCharactersInString:@" \t　"];
    NSMutableArray *words = [[word componentsSeparatedByCharactersInSet:separator] mutableCopy];

    // 空白文字を除外する
    NSMutableArray *removeList = [[NSMutableArray alloc] init];
    for (NSString *word in words) {
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

- (Channel *)channel:(NSURL *)playUrl
{
    if (playUrl == nil) {
        return nil;
    }

    @synchronized (channelsLock_) {
        for (Channel *channel in channels_) {
            NSURL *url = [channel playUrl];
            if ([[playUrl absoluteString] isEqualToString:[url absoluteString]]) {
                return channel;
            }
        }
    }
    return nil;
}

#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receivedData_ setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData_ appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    receivedData_ = nil;
    NSLog(@"NetLadio fetch headline connection failed! Error: %@ / %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    // ヘッドライン取得中のフラグを下げる
    @synchronized (isFetchingLock_) {
        isFetching_ = NO;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:LadioLibHeadlineFailLoadNotification object:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"NetLadio fetch headline received. %d bytes received.", [receivedData_ length]);
    
    // 取得したデータをNSStringに変換し、1行ごとに分館してNSArrayに格納する
    NSString *data = [[NSString alloc] initWithData:receivedData_ encoding:NSShiftJISStringEncoding];
    NSArray *lines = [data componentsSeparatedByString:@"\n"];
    receivedData_ = nil;
    
    NSArray *channels = [self parseHeadline:lines];
    
    @synchronized (channelsLock_) {
        channels_ = [[NSArray alloc] initWithArray:channels];
#if DEBUG
        NSLog(@"%@'s channels updated by finished fetch headline. Headline has %d channels.",
              NSStringFromClass([self class]), [channels count]);
#endif /* #if DEBUG */
    }
    
    // ヘッドライン取得中のフラグを下げる
    @synchronized (isFetchingLock_) {
        isFetching_ = NO;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LadioLibHeadlineDidFinishLoadNotification object:self];
}

#pragma mark -

@end
