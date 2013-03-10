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

#import "../Notifications.h"
#import "FavoriteManager.h"
#import "Headline.h"

/// ねとらじのヘッドラインのURL DAT v2
#define NETLADIO_HEADLINE_DAT_V2_URL @"http://yp.ladio.net/stats/list.v2.zdat"

@implementation Headline
{
    /// 番組データリスト
    NSArray *channels_;
    /// 番組取得処理のNSOperationQueue
    NSOperationQueue *fetchQueue_;
    /// channelsのロック
    NSObject *channelsLock_;
    /// 番組データリストのキャッシュ
    /// ソートやフィルタリングの結果をキャッシュしておく
    NSCache *channelsCache_;
    /// ヘッドラインを取得中か
    BOOL isFetching_;
    /// isFetchingのロック
    NSObject *isFetchingLock_;
}

// ヘッドライン解析用のRegularExpression
static NSRegularExpression *surlExp = nil;
static NSRegularExpression *timsExp = nil;
static NSRegularExpression *srvExp = nil;
static NSRegularExpression *prtExp = nil;
static NSRegularExpression *mntExp = nil;
static NSRegularExpression *typeExp = nil;
static NSRegularExpression *namExp = nil;
static NSRegularExpression *gnlExp = nil;
static NSRegularExpression *descExp = nil;
static NSRegularExpression *djExp = nil;
static NSRegularExpression *songExp = nil;
static NSRegularExpression *urlExp = nil;
static NSRegularExpression *clnExp = nil;
static NSRegularExpression *clnsExp = nil;
static NSRegularExpression *maxExp = nil;
static NSRegularExpression *bitExp = nil;
static NSRegularExpression *smplExp = nil;
static NSRegularExpression *chsExp = nil;

+ (Headline *)sharedInstance
{
    static Headline *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[Headline alloc] init];

        NSError *error = nil;

        surlExp = [NSRegularExpression regularExpressionWithPattern:@"^SURL=(.*)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        timsExp = [NSRegularExpression regularExpressionWithPattern:@"^TIMS=(.*)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        srvExp = [NSRegularExpression regularExpressionWithPattern:@"^SRV=(.*)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        prtExp = [NSRegularExpression regularExpressionWithPattern:@"^PRT=(.*)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        mntExp = [NSRegularExpression regularExpressionWithPattern:@"^MNT=(.*)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        typeExp = [NSRegularExpression regularExpressionWithPattern:@"^TYPE=(.*)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        namExp = [NSRegularExpression regularExpressionWithPattern:@"^NAM=(.*)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        gnlExp = [NSRegularExpression regularExpressionWithPattern:@"^GNL=(.*)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        descExp = [NSRegularExpression regularExpressionWithPattern:@"^DESC=(.*)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        djExp = [NSRegularExpression regularExpressionWithPattern:@"^DJ=(.*)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        songExp = [NSRegularExpression regularExpressionWithPattern:@"^SONG=(.*)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        urlExp = [NSRegularExpression regularExpressionWithPattern:@"^URL=(.*)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        clnExp = [NSRegularExpression regularExpressionWithPattern:@"^CLN=(\\d+)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        clnsExp = [NSRegularExpression regularExpressionWithPattern:@"^CLNS=(\\d+)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        maxExp = [NSRegularExpression regularExpressionWithPattern:@"^MAX=(\\d+)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        bitExp = [NSRegularExpression regularExpressionWithPattern:@"^BIT=(\\d+)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        smplExp = [NSRegularExpression regularExpressionWithPattern:@"^SMPL=(\\d+)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }

        error = nil;
        chsExp = [NSRegularExpression regularExpressionWithPattern:@"^CHS=(\\d+)" options:0 error:&error];
        if (error != nil) {
            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
        }
    });
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        fetchQueue_ = [[NSOperationQueue alloc] init];
        channelsLock_ = [[NSObject alloc] init];
        channelsCache_ = [[NSCache alloc] init];
        [channelsCache_ setName:@"LadioLib channels cache"];
        isFetching_ = NO;
        isFetchingLock_ = [[NSObject alloc] init];

        // 番組のお気に入りの変化通知を受け取る。番組キャッシュのクリアをする。
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(channelFavoritesChanged:)
                                                     name:RadioLibChannelChangedFavoritesNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:RadioLibChannelChangedFavoritesNotification
                                                  object:nil];

    isFetchingLock_ = nil;
    channelsCache_ = nil;
    channelsLock_ = nil;
    fetchQueue_ = nil;
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

    [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibHeadlineDidStartLoadNotification object:self];

    NSURL *url = [NSURL URLWithString:NETLADIO_HEADLINE_DAT_V2_URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:fetchQueue_
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ([data length] > 0 && error == nil) {
                                   NSLog(@"NetLadio fetch headline received. %d bytes received.", [data length]);

                                   // 取得したデータをNSStringに変換し、1行ごとに分館してNSArrayに格納する
                                   NSString *str = [[NSString alloc] initWithData:data
                                                                         encoding:NSShiftJISStringEncoding];
                                   NSArray *lines = [str componentsSeparatedByString:@"\n"];

                                   NSArray *channels = [self parseHeadline:lines];

                                   @synchronized (channelsLock_) {
                                       channels_ = [[NSArray alloc] initWithArray:channels];
#if DEBUG
                                       NSLog(@"%@'s channels updated by finished fetch headline."
                                             " Headline has %d channels.",
                                             NSStringFromClass([self class]), [channels count]);
#endif /* #if DEBUG */
                                       // 番組表データを更新したのでキャッシュを削除
                                       [self clearChannelsCache];
                                   }

                                   // ヘッドライン取得中のフラグを下げる
                                   @synchronized (isFetchingLock_) {
                                       isFetching_ = NO;
                                   }

                                   [[NSNotificationCenter defaultCenter]
                                           postNotificationName:RadioLibHeadlineDidFinishLoadNotification object:self];
                                   [[NSNotificationCenter defaultCenter]
                                           postNotificationName:RadioLibHeadlineChannelChangedNotification object:self];
                               } else if ([data length] == 0 && error == nil) {
                                   NSLog(@"Nothing was downloaded.");

                                   // ヘッドライン取得中のフラグを下げる
                                   @synchronized (isFetchingLock_) {
                                       isFetching_ = NO;
                                   }
                                   
                                   [[NSNotificationCenter defaultCenter]
                                           postNotificationName:RadioLibHeadlineFailLoadNotification object:self];
                               } else if (error != nil) {
                                   NSLog(@"NetLadio fetch headline connection failed! Error: %@ / %@",
                                         [error localizedDescription],
                                         [error userInfo][NSURLErrorFailingURLStringErrorKey]);

                                   // ヘッドライン取得中のフラグを下げる
                                   @synchronized (isFetchingLock_) {
                                        isFetching_ = NO;
                                   }

                                   [[NSNotificationCenter defaultCenter]
                                          postNotificationName:RadioLibHeadlineFailLoadNotification object:self];
                               }
                           }];
}

- (BOOL)isFetchingHeadline;
{
    @synchronized (isFetchingLock_) {
        return isFetching_;
    }
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
    // キャッシュがヒットしたらそれを返す
    NSArray *cacheResult = [self channelsFromCache:sortType searchWord:searchWord];
    if ([cacheResult count] != 0) {
        return cacheResult;
    }

    NSArray *result = nil;
    NSMutableArray *channels = nil;

    @synchronized (channelsLock_) {
        channels = [channels_ mutableCopy];
#if DEBUG
        NSLog(@"%@'s copied channels for return channels. There are %d channels.",
              NSStringFromClass([self class]), [channels count]);
#endif /* #if DEBUG */
    }

    // フィルタリング
    if ([searchWord length] > 0) {
        NSArray *words = [[self class] splitStringByWhiteSpace:searchWord];
        NSMutableIndexSet *removeItemIndexes = [NSMutableIndexSet indexSet];

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
        dispatch_apply([channels count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
            Channel *channel = channels[i];
            if (channel != nil && [channel isMatch:words] == NO) {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                {
                    [removeItemIndexes addIndex:i];
                }
                dispatch_semaphore_signal(semaphore);
            }
        });
        dispatch_release(semaphore);

        [channels removeObjectsAtIndexes:removeItemIndexes];
    }

    // ソート
    switch (sortType) {
        case ChannelSortTypeNewly:
            result =  [channels sortedArrayUsingSelector:@selector(compareNewly:)];
            break;
        case ChannelSortTypeListeners:
            result = [channels sortedArrayUsingSelector:@selector(compareListeners:)];
            break;
        case ChannelSortTypeTitle:
            result = [channels sortedArrayUsingSelector:@selector(compareTitle:)];
            break;
        case ChannelSortTypeDj:
            result = [channels sortedArrayUsingSelector:@selector(compareDj:)];
            break;
        case ChannelSortTypeNone:
        default:
            result = channels;
            break;
    }

    // 結果をキャッシュに突っ込む
    [self setChannelsCache:result sortType:sortType searchWord:searchWord];

    return result;
}

- (Channel *)channelFromPlayUrl:(NSURL *)playUrl
{
    if (playUrl == nil) {
        return nil;
    }

    __block Channel *result = nil;
    
    @synchronized (channelsLock_) {
        __block BOOL found = NO;
        dispatch_apply([channels_ count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
            if (found == NO) {
                Channel *channel = [channels_ objectAtIndex:i];
                NSURL *url = [channel playUrl];
                if ([[playUrl absoluteString] isEqualToString:[url absoluteString]]) {
                    result = channel;
                    found = YES;
                }
            }
        });
    }
    return result;
}

- (Channel *)channelFromMount:(NSString *)mount;
{
    if ([mount length] == 0) {
        return nil;
    }

    __block Channel *result = nil;
    
    @synchronized (channelsLock_) {
        __block BOOL found = NO;
        dispatch_apply([channels_ count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
            if (found == NO) {
                Channel *channel = [channels_ objectAtIndex:i];
                if ([mount isEqualToString:channel.mnt]) {
                    result = channel;
                    found = YES;
                }
            }
        });
    }
    return result;
}

#pragma mark - Private methods

- (NSArray*)parseHeadline:(NSArray*)lines
{
    NSMutableArray *result = [NSMutableArray array];
    Channel *channel = nil;

    for (NSString *line in lines) {
        if ([line length] == 0 && channel != nil) {
            [result addObject:channel];
            channel = nil;
            continue;
        }

        NSString *matchString;

        matchString = [self parseLine:line expression:surlExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            [channel setSurlFromString:matchString];
            continue;
        }

        matchString = [self parseLine:line expression:timsExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            [channel setTimsFromString:matchString];
            continue;
        }

        matchString = [self parseLine:line expression:srvExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.srv = matchString;
            continue;
        }

        matchString = [self parseLine:line expression:prtExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.prt = [matchString intValue];
            continue;
        }

        matchString = [self parseLine:line expression:mntExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.mnt = matchString;
            continue;
        }

        matchString = [self parseLine:line expression:typeExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.type = matchString;
            continue;
        }

        matchString = [self parseLine:line expression:namExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.nam = matchString;
            continue;
        }

        matchString = [self parseLine:line expression:gnlExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.gnl = matchString;
            continue;
        }

        matchString = [self parseLine:line expression:descExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.desc = matchString;
            continue;
        }

        matchString = [self parseLine:line expression:djExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.dj = matchString;
            continue;
        }

        matchString = [self parseLine:line expression:songExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.song = matchString;
            continue;
        }

        matchString = [self parseLine:line expression:urlExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            [channel setUrlFromString:matchString];
            continue;
        }

        matchString = [self parseLine:line expression:clnExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.cln = [matchString intValue];
            continue;
        }

        matchString = [self parseLine:line expression:clnsExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.clns = [matchString intValue];
            continue;
        }

        matchString = [self parseLine:line expression:maxExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.max = [matchString intValue];
            continue;
        }

        matchString = [self parseLine:line expression:bitExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.bit = [matchString intValue];
            continue;
        }

        matchString = [self parseLine:line expression:smplExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.smpl = [matchString intValue];
            continue;
        }

        matchString = [self parseLine:line expression:chsExp];
        if ([matchString length] > 0) {
            if (channel == nil) {
                channel = [[Channel alloc] init];
            }
            channel.chs = [matchString intValue];
            continue;
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
    NSMutableIndexSet *removeItemIndexes = [NSMutableIndexSet indexSet];
    NSUInteger index = 0;
    for (NSString *word in words) {
        if ([word length] == 0) {
            [removeItemIndexes addIndex:index];
        }
        ++index;
    }
    [words removeObjectsAtIndexes:removeItemIndexes];
    
    return words;
}

- (NSArray *)channelsFromCache:(ChannelSortType)sortType searchWord:(NSString *)searchWord
{
    NSString *key = [[NSString alloc] initWithFormat:@"%d//%@", sortType, searchWord];
    NSArray *result = [channelsCache_ objectForKey:key];
#if DEBUG
    if (result != nil) {
        NSLog(@"%@ has channels cache. key:%@", NSStringFromClass([self class]), key);
    } else {
        NSLog(@"%@ has NO channels cache. key:%@", NSStringFromClass([self class]), key);
    }
#endif /* #if DEBUG */
    return result;
}

- (void)setChannelsCache:(NSArray *)channels sortType:(ChannelSortType)sortType searchWord:(NSString *)searchWord
{
    // nilの場合はキャッシュに突っ込めない
    if (channels == nil) {
        return;
    }

    NSString *key = [[NSString alloc] initWithFormat:@"%d//%@", sortType, searchWord];
    [channelsCache_ setObject:channels forKey:key];
#if DEBUG
    NSLog(@"%@ set channels cache. key:%@", NSStringFromClass([self class]), key);
#endif /* #if DEBUG */
}

- (void)clearChannelsCache
{
    [channelsCache_ removeAllObjects];
#if DEBUG
    NSLog(@"%@ clear channels cache.", NSStringFromClass([self class]));
#endif /* #if DEBUG */
}

#pragma mark - Favorite notification

- (void)channelFavoritesChanged:(NSNotification *)notification
{
    // お気に入りが変化したのでキャッシュをクリアする
    // お気に入りの有無がソート順番に影響するため
    [self clearChannelsCache];

    @synchronized (channelsLock_) {
        dispatch_apply([channels_ count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
            // 番組のお気に入りキャッシュをクリアする
            [channels_[i] clearFavoriteCache];
        });
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibHeadlineChannelChangedNotification object:self];
}

@end
