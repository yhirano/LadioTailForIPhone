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

/// IcecastのヘッドラインのURL
#define ICECAST_HEADLINE_XML_URL @"http://dir.xiph.org/yp.xml"

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

    // XML解析のためのフラグ
	BOOL xmlParseInEntryElement_;
    BOOL xmlParseInServerNameElement_;
    BOOL xmlParseInListenUrlElement_;
    BOOL xmlParseInServerTypeElement_;
    BOOL xmlParseInBitrateElement_;
    BOOL xmlParseInChannelsElement_;
    BOOL xmlParseInSampleRateElement_;
    BOOL xmlParseInGenreElement_;
    BOOL xmlParseInCurrentSongElement_;
    NSMutableArray *xmlParseChannels_;
    Channel *xmlParseChannel_;
    NSInteger xmlParseChannelFid_;
}

+ (Headline *)sharedInstance
{
    static Headline *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[Headline alloc] init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        fetchQueue_ = [[NSOperationQueue alloc] init];
        channelsLock_ = [[NSObject alloc] init];
        channelsCache_ = [[NSCache alloc] init];
        [channelsCache_ setName:@"IcecastLib channels cache"];
        isFetching_ = NO;
        isFetchingLock_ = [[NSObject alloc] init];
        xmlParseChannelFid_ = 0;
        xmlParseInEntryElement_ = NO;
        xmlParseInServerNameElement_ = NO;
        xmlParseInListenUrlElement_ = NO;
        xmlParseInServerTypeElement_ = NO;
        xmlParseInBitrateElement_ = NO;
        xmlParseInChannelsElement_ = NO;
        xmlParseInSampleRateElement_ = NO;
        xmlParseInGenreElement_ = NO;
        xmlParseInCurrentSongElement_ = NO;

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
            NSLog(@"fetchHeadline call isn't processing. Fetching Icecaset headline now.");
            return;
        }
        // ヘッドライン取得中のフラグを立てる
        isFetching_ = YES;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibHeadlineDidStartLoadNotification object:self];

    NSURL *url = [NSURL URLWithString:ICECAST_HEADLINE_XML_URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:fetchQueue_
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ([data length] > 0 && error == nil) {
                                   NSLog(@"Icecaset fetch headline received. %d bytes received.", [data length]);

                                   NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
                                   [parser setDelegate:self];
                                   [parser parse];

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
                                   NSLog(@"Icecast fetch headline connection failed! Error: %@ / %@",
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
    if (!([searchWord length] == 0)) {
        NSArray *words = [[self class] splitStringByWhiteSpace:searchWord];
        NSMutableIndexSet *removeItemIndexes = [NSMutableIndexSet indexSet];

        NSObject *lock = [[NSObject alloc] init];
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_apply([channels count], queue, ^(size_t i) {
            Channel *channel = channels[i];
            if (channel != nil && [channel isMatch:words] == NO) {
                @synchronized (lock) {
                    [removeItemIndexes addIndex:i];
                }
            }
        });

        [channels removeObjectsAtIndexes:removeItemIndexes];
    }

    // ソート
    switch (sortType) {
        case ChannelSortTypeNewly:
            result =  [channels sortedArrayUsingSelector:@selector(compareNewly:)];
            break;
        case ChannelSortTypeServerName:
            result =  [channels sortedArrayUsingSelector:@selector(compareServerName:)];
            break;
        case ChannelSortTypeGenre:
            result = [channels sortedArrayUsingSelector:@selector(compareGenre:)];
            break;
        case ChannelSortTypeBitrate:
            result = [channels sortedArrayUsingSelector:@selector(compareBitrate:)];
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

- (Channel *)channelFromListenUrl:(NSURL *)listenUrl
{
    if (listenUrl == nil) {
        return nil;
    }

    __block Channel *result = nil;

    @synchronized (channelsLock_) {
        __block BOOL found = NO;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_apply([channels_ count], queue, ^(size_t i) {
            if (found == NO) {
                Channel *channel = [channels_ objectAtIndex:i];
                if ([[listenUrl absoluteString] isEqualToString:[channel.listenUrl absoluteString]]) {
                    result = channel;
                    found = YES;
                }
            }
        });
    }
    return result;
}

- (Channel *)channelFromServerName:(NSString *)serverName;
{
    if ([serverName length] == 0) {
        return nil;
    }

    __block Channel *result = nil;

    @synchronized (channelsLock_) {
        __block BOOL found = NO;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_apply([channels_ count], queue, ^(size_t i) {
            if (found == NO) {
                Channel *channel = [channels_ objectAtIndex:i];
                if ([serverName isEqualToString:channel.serverName]) {
                    result = channel;
                    found = YES;
                }
            }
        });
    }
    return result;
}

#pragma mark - NSXMLParserDelegate methods

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	xmlParseInEntryElement_ = NO;
    xmlParseInServerNameElement_ = NO;
    xmlParseInListenUrlElement_ = NO;
    xmlParseInServerTypeElement_ = NO;
    xmlParseInBitrateElement_ = NO;
    xmlParseInChannelsElement_ = NO;
    xmlParseInSampleRateElement_ = NO;
    xmlParseInGenreElement_ = NO;
    xmlParseInCurrentSongElement_ = NO;

    xmlParseChannels_ = [[NSMutableArray alloc] init];
    xmlParseChannelFid_ = 0;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    @synchronized (channelsLock_) {
        channels_ = [[NSArray alloc] initWithArray:xmlParseChannels_];
        xmlParseChannels_ = nil;
#if DEBUG
        NSLog(@"%@'s channels updated by finished fetch headline. Headline has %d channels.",
              NSStringFromClass([self class]), [channels_ count]);
#endif /* #if DEBUG */
        // 番組表データを更新したのでキャッシュを削除
        [self clearChannelsCache];
    }

    // ヘッドライン取得中のフラグを下げる
    @synchronized (isFetchingLock_) {
        isFetching_ = NO;
    }
}

// 要素の開始タグを読み込み
- (void) parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qualifiedName
     attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqualToString:@"entry"]) {
        xmlParseChannel_ = [[Channel alloc] init];
        xmlParseChannel_.fid = xmlParseChannelFid_;
        ++xmlParseChannelFid_;
        xmlParseInEntryElement_ = YES;
    } else if ([elementName isEqualToString:@"server_name"]) {
        xmlParseInServerNameElement_ = YES;
    } else if ([elementName isEqualToString:@"listen_url"]) {
        xmlParseInListenUrlElement_ = YES;
    } else if ([elementName isEqualToString:@"server_type"]) {
        xmlParseInServerTypeElement_ = YES;
    } else if ([elementName isEqualToString:@"bitrate"]) {
        xmlParseInBitrateElement_ = YES;
    } else if ([elementName isEqualToString:@"channels"]) {
        xmlParseInChannelsElement_ = YES;
    } else if ([elementName isEqualToString:@"samplerate"]) {
        xmlParseInSampleRateElement_ = YES;
    } else if ([elementName isEqualToString:@"genre"]) {
        xmlParseInGenreElement_ = YES;
    } else if ([elementName isEqualToString:@"current_song"]) {
        xmlParseInCurrentSongElement_ = YES;
    }
}

// 要素の閉じタグを読み込み
- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
	if ([elementName isEqualToString:@"entry"]) {
        [xmlParseChannels_ addObject:xmlParseChannel_];
        xmlParseChannel_ = nil;
        xmlParseInEntryElement_ = NO;
        xmlParseInServerNameElement_ = NO;
        xmlParseInListenUrlElement_ = NO;
        xmlParseInServerTypeElement_ = NO;
        xmlParseInBitrateElement_ = NO;
        xmlParseInChannelsElement_ = NO;
        xmlParseInSampleRateElement_ = NO;
        xmlParseInGenreElement_ = NO;
        xmlParseInCurrentSongElement_ = NO;
    } else if ([elementName isEqualToString:@"server_name"]) {
        xmlParseInServerNameElement_ = NO;
    } else if ([elementName isEqualToString:@"listen_url"]) {
        xmlParseInListenUrlElement_ = NO;
    } else if ([elementName isEqualToString:@"server_type"]) {
        xmlParseInServerTypeElement_ = NO;
    } else if ([elementName isEqualToString:@"bitrate"]) {
        xmlParseInBitrateElement_ = NO;
    } else if ([elementName isEqualToString:@"channels"]) {
        xmlParseInChannelsElement_ = NO;
    } else if ([elementName isEqualToString:@"samplerate"]) {
        xmlParseInSampleRateElement_ = NO;
    } else if ([elementName isEqualToString:@"genre"]) {
        xmlParseInGenreElement_ = NO;
    } else if ([elementName isEqualToString:@"current_song"]) {
        xmlParseInCurrentSongElement_ = NO;
    }
}

// テキストデータ読み込み
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (xmlParseInEntryElement_) {
        if (xmlParseInServerNameElement_) {
            xmlParseChannel_.serverName = string;
        } else if (xmlParseInListenUrlElement_) {
            xmlParseChannel_.listenUrl = [[NSURL alloc] initWithString:string];
        } else if (xmlParseInServerTypeElement_) {
            xmlParseChannel_.serverType = string;
        } else if (xmlParseInBitrateElement_) {
            xmlParseChannel_.bitrate = [string integerValue];
        } else if (xmlParseInChannelsElement_) {
            xmlParseChannel_.channels = [string integerValue];
        } else if (xmlParseInSampleRateElement_) {
            xmlParseChannel_.sampleRate = [string integerValue];
        } else if (xmlParseInGenreElement_) {
            xmlParseChannel_.genre = string;
        } else if (xmlParseInCurrentSongElement_) {
            xmlParseChannel_.currentSong = string;
        }
    }
}

#pragma mark - Private methods

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
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_apply([channels_ count], queue, ^(size_t i) {
            // 番組のお気に入りキャッシュをクリアする
            [channels_[i] clearFavoriteCache];
        });
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibHeadlineChannelChangedNotification object:self];
}

@end
