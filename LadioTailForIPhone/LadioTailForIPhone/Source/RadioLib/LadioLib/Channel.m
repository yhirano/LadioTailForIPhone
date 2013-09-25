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

#import <AVFoundation/AVAsset.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "FavoriteManager.h"
#import "Html/ChannelHtml.h"
#import "Channel.h"

@implementation Channel
{
    NSURL *surl_;
    NSDate *tims_;
    NSString *srv_;
    NSInteger prt_;
    NSString *mnt_;
    NSString *type_;
    NSString *nam_;
    NSString *gnl_;
    NSString *desc_;
    NSString *dj_;
    NSString *song_;
    NSURL *url_;
    NSInteger cln_;
    NSInteger clns_;
    NSInteger max_;
    NSInteger bit_;
    NSInteger smpl_;
    NSInteger chs_;

    BOOL hasHashCache_;
    NSUInteger hashCache_;
    NSURL *playUrlCache_;
    /// お気に入りキャッシュが有効か
    BOOL hasFavoriteCache_;
    /// お気に入りキャッシュ
    BOOL favoriteCache_;
    BOOL hasPlaySupportedCache_;
    BOOL playSupportedCache_;
}

/// isMatchの結果を格納するキャッシュ
static NSCache *matchCache = nil;

- (id)init
{
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        matchCache = [[NSCache alloc] init];
    });

    if (self = [super init]) {
        surl_ = nil;
        tims_ = nil;
        srv_ = nil;
        prt_ = -1;
        mnt_ = nil;
        type_ = nil;
        nam_ = nil;
        gnl_ = nil;
        desc_ = nil;
        dj_ = nil;
        song_ = nil;
        url_ = nil;
        cln_ = CHANNEL_UNKNOWN_LISTENER_NUM;
        clns_ = CHANNEL_UNKNOWN_LISTENER_NUM;
        max_ = CHANNEL_UNKNOWN_LISTENER_NUM;
        bit_ = CHANNEL_UNKNOWN_BITRATE_NUM;
        smpl_ = CHANNEL_UNKNOWN_SAMPLING_RATE_NUM;
        chs_ = CHANNEL_UNKNOWN_CHANNEL_NUM;

        hasHashCache_ = NO;
        playUrlCache_ = nil;
        hasFavoriteCache_ = NO;
        favoriteCache_ = NO;
        hasPlaySupportedCache_ = NO;
        playSupportedCache_ = NO;
    }
    return self;
}

- (NSString *)description
{
    NSString *format = @"<%@ :%p , surl:%@ tims:%@ srv:%@ prt:%d mnt:%@ type:%@ nam:%@ gnl:%@ desc:%@ dj:%@ song:%@"
                        " url:%@ cln:%d clns:%d max:%d bit:%d smpl:%d chs:%d>";
    return [NSString stringWithFormat:format, NSStringFromClass([self class]), self, surl_, tims_, srv_, prt_, mnt_,
                                      type_, nam_, gnl_, desc_, dj_, song_, url_, cln_, clns_, max_, bit_, smpl_, chs_];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    }
    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }

    Channel *otherChannel = (Channel*)other;
    if (self.surl == nil) {
        if (otherChannel.surl != nil) {
            return NO;
        }
    } else if (![[self.surl absoluteString] isEqual:[otherChannel.surl absoluteString]]) {
        return NO;
    }
    if (self.tims == nil) {
        if (otherChannel.tims != nil) {
            return NO;
        }
    } else if (![self.tims isEqual:otherChannel.tims]) {
        return NO;
    }
    if (self.prt != otherChannel.prt) {
        return NO;
    }
    if (self.mnt == nil) {
        if (otherChannel.mnt != nil) {
            return NO;
        }
    } else if (![self.mnt isEqual:otherChannel.mnt]) {
        return NO;
    }
    if (self.type == nil) {
        if (otherChannel.type != nil) {
            return NO;
        }
    } else if (![self.type isEqual:otherChannel.type]) {
        return NO;
    }
    if (self.nam == nil) {
        if (otherChannel.nam != nil) {
            return NO;
        }
    } else if (![self.nam isEqual:otherChannel.nam]) {
        return NO;
    }
    if (self.gnl == nil) {
        if (otherChannel.gnl != nil) {
            return NO;
        }
    } else if (![self.gnl isEqual:otherChannel.gnl]) {
        return NO;
    }
    if (self.desc == nil) {
        if (otherChannel.desc != nil) {
            return NO;
        }
    } else if (![self.desc isEqual:otherChannel.desc]) {
        return NO;
    }
    if (self.dj == nil) {
        if (otherChannel.dj != nil) {
            return NO;
        }
    } else if (![self.dj isEqual:otherChannel.dj]) {
        return NO;
    }
    if (self.song == nil) {
        if (otherChannel.song != nil) {
            return NO;
        }
    } else if (![self.song isEqual:otherChannel.song]) {
        return NO;
    }
    if (self.url == nil) {
        if (otherChannel.url != nil) {
            return NO;
        }
    } else if (![[self.url absoluteString] isEqual:[otherChannel.url absoluteString]]) {
        return NO;
    }
    if (self.cln != otherChannel.cln) {
        return NO;
    }
    if (self.clns != otherChannel.clns) {
        return NO;
    }
    if (self.max != otherChannel.max) {
        return NO;
    }
    if (self.bit != otherChannel.bit) {
        return NO;
    }
    if (self.smpl != otherChannel.smpl) {
        return NO;
    }
    if (self.chs != otherChannel.chs) {
        return NO;
    }

    return YES;
}

- (NSUInteger)hash
{
    if (hasHashCache_) {
        return hashCache_;
    }
    
    NSUInteger result = 1;
    static const NSUInteger prime = 31;
    
    result = prime * result + [surl_ hash];
    result = prime * result + [tims_ hash];
    result = prime * result + [srv_ hash];
    result = prime * result + prt_;
    result = prime * result + [mnt_ hash];
    result = prime * result + [type_ hash];
    result = prime * result + [nam_ hash];
    result = prime * result + [gnl_ hash];
    result = prime * result + [desc_ hash];
    result = prime * result + [dj_ hash];
    result = prime * result + [song_ hash];
    result = prime * result + [url_ hash];
    result = prime * result + cln_;
    result = prime * result + clns_;
    result = prime * result + max_;
    result = prime * result + bit_;
    result = prime * result + smpl_;
    result = prime * result + chs_;
    
    hasHashCache_ = YES;
    hashCache_ = result;
    return result;
}

- (void)setSurlFromString:(NSString *)url
{
    surl_ = [NSURL URLWithString:url];
}

- (NSString *)timsToString
{
    static NSDateFormatter *timsToStringDateFormatter = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        timsToStringDateFormatter = [[NSDateFormatter alloc] init];
        [timsToStringDateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [timsToStringDateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    });
    return [timsToStringDateFormatter stringFromDate:tims_];
}

- (void)setTimsFromString:(NSString *)tims
{
    static NSDateFormatter *setTimsFromStringDateFormatter = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        setTimsFromStringDateFormatter = [[NSDateFormatter alloc] init];
        [setTimsFromStringDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]]; // 番組表は日本時間
        [setTimsFromStringDateFormatter setDateFormat:@"yy/MM/dd HH:mm:ss"];
    });
    tims_ = [setTimsFromStringDateFormatter dateFromString:tims];
}

- (void)setUrlFromString:(NSString *)url
{
    url_ = [NSURL URLWithString:url];
}

- (NSURL *)playUrl
{
    if (playUrlCache_ == nil) {
        NSString *url = [NSString stringWithFormat:@"http://%@:%d%@", srv_, prt_, mnt_];
        playUrlCache_ = [NSURL URLWithString:url];
    }
    return playUrlCache_;
}

- (NSURL*)surl
{
    return surl_;
}

- (void)setSurl:(NSURL*)u
{
    surl_ = u;
    hasHashCache_ = NO;
}

- (NSDate*)tims
{
    return tims_;
}

- (void)setTims:(NSDate*)t
{
    tims_ = t;
    hasHashCache_ = NO;
}

- (NSString*)srv
{
    return srv_;
}

- (void)setSrv:(NSString*)s
{
    srv_ = s;
    hasHashCache_ = NO;
    playUrlCache_ = nil;
}

- (NSInteger)prt
{
    return prt_;
}

- (void)setPrt:(NSInteger)p
{
    prt_ = p;
    hasHashCache_ = NO;
    playUrlCache_ = nil;
}

- (NSString*)mnt
{
    return mnt_;
}

- (void)setMnt:(NSString*)m
{
    mnt_ = m;
    hasHashCache_ = NO;
    playUrlCache_ = nil;
}

- (NSString*)type
{
    return type_;
}

- (void)setType:(NSString*)t
{
    type_ = t;
    hasHashCache_ = NO;
    hasPlaySupportedCache_ = NO;
}

- (NSString*)nam
{
    return nam_;
}

- (void)setNam:(NSString*)n
{
    nam_ = n;
    _trimedNam = [nam_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    hasHashCache_ = NO;
}

- (NSString*)gnl
{
    return gnl_;
}

- (void)setGnl:(NSString*)g
{
    gnl_ = g;
    hasHashCache_ = NO;
}

- (NSString*)desc
{
    return desc_;
}

- (void)setDesc:(NSString*)d
{
    desc_ = d;
    hasHashCache_ = NO;
}

- (NSString*)dj
{
    return dj_;
}

- (void)setDj:(NSString*)d
{
    dj_ = d;
    _trimedDj = [dj_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    hasHashCache_ = NO;
}

- (NSString*)song
{
    return song_;
}

- (void)setSong:(NSString*)s
{
    song_ = s;
    hasHashCache_ = NO;
}

- (NSURL*)url
{
    return url_;
}

- (void)setUrl:(NSURL*)u
{
    url_ = u;
    hasHashCache_ = NO;
}

- (NSInteger)cln
{
    return cln_;
}

- (void)setCln:(NSInteger)c
{
    cln_ = c;
    hasHashCache_ = NO;
}

- (NSInteger)clns
{
    return clns_;
}

- (void)setClns:(NSInteger)c
{
    clns_ = c;
    hasHashCache_ = NO;
}

- (NSInteger)max
{
    return max_;
}

- (void)setMax:(NSInteger)m
{
    max_ = m;
    hasHashCache_ = NO;
}

- (NSInteger)bit
{
    return bit_;
}

- (void)setBit:(NSInteger)b
{
    bit_ = b;
    hasHashCache_ = NO;
}

- (NSInteger)smpl
{
    return smpl_;
}

- (void)setSmpl:(NSInteger)s
{
    smpl_ = s;
    hasHashCache_ = NO;
}

- (NSInteger)chs
{
    return chs_;
}

- (void)setChs:(NSInteger)c
{
    chs_ = c;
    hasHashCache_ = NO;
}

- (BOOL)favorite
{
    if (hasFavoriteCache_) {
        return favoriteCache_;
    } else {
        FavoriteManager *favoriteManager = [FavoriteManager sharedInstance];
        BOOL result = [favoriteManager isFavorite:self];
        hasFavoriteCache_ = YES;
        favoriteCache_ = result;
        return result;
    }
}

- (void)setFavorite:(BOOL)fav
{
    FavoriteManager *favoriteManager = [FavoriteManager sharedInstance];
    if ([self favorite] && fav == NO) {
        [favoriteManager removeFavorite:self];
    } else if ([self favorite] == NO && fav) {
        [favoriteManager addFavorite:self];
    }
}

- (void)switchFavorite
{
    FavoriteManager *favoriteManager = [FavoriteManager sharedInstance];
    [favoriteManager switchFavorite:self];
}

- (BOOL)isMatch:(NSArray *)searchWords
{
    // フィルタリング単語が指定されていない場合は無条件に合致する
    if ([searchWords count] == 0) {
        return YES;
    }

    // 結果がキャッシュにある場合はそれを返す
    NSString *cacheKey = [searchWords componentsJoinedByString:@"//"];
    cacheKey = [[NSString alloc] initWithFormat:@"%d//%@", [self hash], cacheKey];
    NSNumber *cacheResult = [matchCache objectForKey:cacheKey];
    if (cacheResult != nil) {
        return [cacheResult boolValue];
    }

    BOOL result = YES;

    // 検索単語を辞書に登録する
    // 辞書は Key:検索単語 Value:マッチしたか
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] initWithCapacity:[searchWords count]];
    for (NSString *word in searchWords) {
        if ([word length] > 0) {
            searchDictionary[word] = @NO;
        }
    }

    // 検索対象文字列を配列にする
    NSMutableArray *searchedWords = [[NSMutableArray alloc] initWithCapacity:4];
    if ([nam_ length] > 0) {
        [searchedWords addObject:nam_];
    }
    if ([gnl_ length] > 0) {
        [searchedWords addObject:gnl_];
    }
    if ([desc_ length] > 0) {
        [searchedWords addObject:desc_];
    }
    if ([dj_ length] > 0) {
        [searchedWords addObject:dj_];
    }

    // 検索文字と検索対象文字を比較する
    for (NSString *searchedWord in searchedWords) {
        for (NSString *searchWord in [searchDictionary allKeys]) {
            // 見つかった場合は検索辞書の該当単語にYESを代入
            if ([searchedWord rangeOfString:searchWord
                                    options:(NSCaseInsensitiveSearch | NSLiteralSearch | NSWidthInsensitiveSearch)]
                    .location != NSNotFound) {
                searchDictionary[searchWord] = @YES;
            }
        }
    }

    // すべての検索単語がマッチした場合にのみYESを返す
    for (NSNumber *match in [searchDictionary allValues]) {
        if ([match boolValue] == NO) {
            result = NO;
            break;
        }
    }

    // 結果をキャッシュに格納
    [matchCache setObject: [[NSNumber alloc] initWithBool:result] forKey:cacheKey];

    return result;
}

- (BOOL)isSameMount:(Channel *)channel
{
    if (channel == nil) {
        return NO;
    }
    return [mnt_ isEqualToString:channel.mnt];
}

- (BOOL)isPlaySupported
{
    if (hasPlaySupportedCache_) {
        return playSupportedCache_;
    }

    BOOL result;

    // OSがサポートしているかをチェック
    result = [AVURLAsset isPlayableExtendedMIMEType:type_];
    // MIMEにvideoが含まれていないかをチェック
    if (result &&
        [type_ rangeOfString:@"video" options:(NSCaseInsensitiveSearch | NSLiteralSearch)].location != NSNotFound) {
        result = NO;
    }

    hasPlaySupportedCache_ = YES;
    playSupportedCache_ = result;

    return result;
}

- (NSString *)filenameExtensionFromMimeType
{
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)type_, NULL);
    NSString *result = (__bridge NSString*)UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
    CFRelease(uti);
    
    if (!result) {
        if ([type_ isEqualToString:@"audio/aac"]) {
            result = @"aac";
        } else if ([type_ isEqualToString:@"audio/aacp"]) {
            result = @"aac";
        } else if ([type_ isEqualToString:@"audio/3gpp"]) {
            result = @"3gp";
        } else if ([type_ isEqualToString:@"audio/3gpp2"]) {
            result = @"3g2";
        } else if ([type_ isEqualToString:@"audio/mp4"]) {
            result = @"mp4";
        } else if ([type_ isEqualToString:@"audio/MP4A-LATM"]) {
            result = @"mp4";
        } else if ([type_ isEqualToString:@"audio/mpeg4-generic"]) {
            result = @"mp4";
        }
    }
    
    return result;
}

- (void)clearFavoriteCache
{
    hasFavoriteCache_ = NO;
}

- (NSString *)descriptionHtml
{
    return [ChannelHtml descriptionHtml:self];
}

#pragma mark - Comparison Methods

- (NSComparisonResult)compareNewly:(Channel *)channel
{
    NSComparisonResult result;

    // お気に入りで比較する
    result = [[self class]compareFavorite:self compared:channel];
    if (result != NSOrderedSame) {
        return result;
    }

    // 新しい方が前に来る
    result = [channel.tims compare:self.tims];

    return result;
}

- (NSComparisonResult)compareListeners:(Channel *)channel
{
    NSComparisonResult result;

    // お気に入りで比較する
    result = [[self class]compareFavorite:self compared:channel];
    if (result != NSOrderedSame) {
        return result;
    }

    // リスナー数で比較する
    // 多い方が前に来る
    if (self.cln > channel.cln) {
        result = NSOrderedAscending;
    } else if (self.cln < channel.cln) {
        result = NSOrderedDescending;
    } else {
        result = NSOrderedSame;
    }

    return result;
}

- (NSComparisonResult)compareTitle:(Channel *)channel
{
    NSComparisonResult result;

    // お気に入りで比較する
    result = [[self class]compareFavorite:self compared:channel];
    if (result != NSOrderedSame) {
        return result;
    }

    // タイトルで比較
    result = [[self class]compareString:self.trimedNam compared:channel.trimedNam];
    if (result != NSOrderedSame) {
        return result;
    }

    // タイトルおなじ場合はDJで比較
    result = [[self class]compareString:self.trimedDj compared:channel.trimedDj];
    if (result != NSOrderedSame) {
        return result;
    }

    // タイトルとDJがおなじ場合は日付で比較
    result = [self compareNewly:channel];

    return result;
}

- (NSComparisonResult)compareDj:(Channel *)channel
{
    NSComparisonResult result;

    // お気に入りで比較する
    result = [[self class]compareFavorite:self compared:channel];
    if (result != NSOrderedSame) {
        return result;
    }

    // DJで比較
    result = [[self class]compareString:self.trimedDj compared:channel.trimedDj];
    if (result != NSOrderedSame) {
        return result;
    }

    // DJがおなじ場合はタイトルで比較
    result = [[self class]compareString:self.trimedNam compared:channel.trimedNam];
    if (result != NSOrderedSame) {
        return result;
    }

    // タイトルとDJがおなじ場合は日付で比較
    result = [self compareNewly:channel];

    return result;
}

+ (NSComparisonResult)compareString:(NSString *)str1 compared:(NSString *)str2
{
    // 文字列で比較する。
    // 文字列が空の場合は後ろに来る。
    if (([str1 length] > 0) && ([str2 length] == 0)) {
        return NSOrderedAscending;
    } else if (([str1 length] == 0) && ([str2 length] > 0)) {
        return NSOrderedDescending;
    } else if (([str1 length] == 0) && ([str2 length] == 0)) {
        return NSOrderedSame;
    } else {
        return [str1 localizedCaseInsensitiveCompare:str2];
    }
}

+ (NSComparisonResult)compareFavorite:(Channel *)channel1 compared:(Channel *)channel2
{
    NSComparisonResult result;

    // お気に入りで比較する。
    // お気に入りがある場合は前に来る。
    if (channel1.favorite && channel2.favorite == NO) {
        result = NSOrderedAscending;
    } else if (channel1.favorite == NO && channel2.favorite) {
        result = NSOrderedDescending;
    } else {
        result = NSOrderedSame;
    }
    return result;
}

#pragma mark  - NSCoding methods

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:surl_ forKey:@"SURL"];
    [coder encodeObject:tims_ forKey:@"TIMS"];
    [coder encodeObject:srv_ forKey:@"SRV"];
    [coder encodeInteger:prt_ forKey:@"PRT"];
    [coder encodeObject:mnt_ forKey:@"MNT"];
    [coder encodeObject:type_ forKey:@"TYPE"];
    [coder encodeObject:nam_ forKey:@"NAM"];
    [coder encodeObject:gnl_ forKey:@"GNL"];
    [coder encodeObject:desc_ forKey:@"DESC"];
    [coder encodeObject:dj_ forKey:@"DJ"];
    [coder encodeObject:song_ forKey:@"SONG"];
    [coder encodeObject:url_ forKey:@"URL"];
    [coder encodeInteger:cln_ forKey:@"CLN"];
    [coder encodeInteger:clns_ forKey:@"CLNS"];
    [coder encodeInteger:max_ forKey:@"MAX"];
    [coder encodeInteger:bit_ forKey:@"BIT"];
    [coder encodeInteger:smpl_ forKey:@"SMPL"];
    [coder encodeInteger:chs_ forKey:@"CHS"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        surl_ = [coder decodeObjectForKey:@"SURL"];
        tims_ = [coder decodeObjectForKey:@"TIMS"];
        srv_ = [coder decodeObjectForKey:@"SRV"];
        prt_ = [coder decodeIntegerForKey:@"PRT"];
        mnt_ = [coder decodeObjectForKey:@"MNT"];
        type_ = [coder decodeObjectForKey:@"TYPE"];
        nam_ = [coder decodeObjectForKey:@"NAM"];
        _trimedNam = [nam_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        gnl_ = [coder decodeObjectForKey:@"GNL"];
        desc_ = [coder decodeObjectForKey:@"DESC"];
        dj_ = [coder decodeObjectForKey:@"DJ"];
        _trimedDj = [dj_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        song_ = [coder decodeObjectForKey:@"SONG"];
        url_ = [coder decodeObjectForKey:@"URL"];
        cln_ = [coder decodeIntegerForKey:@"CLN"];
        clns_ = [coder decodeIntegerForKey:@"CLNS"];
        max_ = [coder decodeIntegerForKey:@"MAX"];
        bit_ = [coder decodeIntegerForKey:@"BIT"];
        smpl_ = [coder decodeIntegerForKey:@"SMPL"];
        chs_ = [coder decodeIntegerForKey:@"CHS"];

        hasHashCache_ = NO;
        hasFavoriteCache_ = NO;
        favoriteCache_ = NO;
    }
    return self;
}

@end
