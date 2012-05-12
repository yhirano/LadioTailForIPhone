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

#import "FavoriteManager.h"
#import "Channel.h"

/// setTimsFromString用のNSDateFormatter
static NSDateFormatter *setTimsFromStringDateFormatter = nil;

/// timsToString用のNSDateFormatter
static NSDateFormatter *timsToStringDateFormatter = nil;

@implementation Channel

@synthesize surl = surl_;
@synthesize tims = tims_;
@synthesize srv = srv_;
@synthesize prt = prt_;
@synthesize mnt = mnt_;
@synthesize type = type_;
@synthesize nam = nam_;
@synthesize gnl = gnl_;
@synthesize desc = desc_;
@synthesize dj = dj_;
@synthesize song = song_;
@synthesize url = url_;
@synthesize cln = cln_;
@synthesize clns = clns_;
@synthesize max = max_;
@synthesize bit = bit_;
@synthesize smpl = smpl_;
@synthesize chs = chs_;
@synthesize favorite;

- (id)init
{
    if (self = [super init]) {
        cln_ = CHANNEL_UNKNOWN_LISTENER_NUM;
        clns_ = CHANNEL_UNKNOWN_LISTENER_NUM;
        max_ = CHANNEL_UNKNOWN_LISTENER_NUM;
        bit_ = CHANNEL_UNKNOWN_BITRATE_NUM;
        smpl_ = CHANNEL_UNKNOWN_SAMPLING_RATE_NUM;
        chs_ = CHANNEL_UNKNOWN_CHANNEL_NUM;
    }
    return self;
}

- (NSString *)description
{
    NSString *format = @"<%@ :%p , surl:%@ tims:%@ srv:%@ prt:%d mnt:%@ type:%@ nam:%@ gnl:%@ desc:%@ dj:%@ song:%@"
                        " url:%@ cln:%d clns:%d max:%d bit:%d smpl:%d chs:%d>";
    return [NSString stringWithFormat:format, NSStringFromClass([self class]), self, surl_, tims_, srv_, prt_, mnt_,
                                      type_, nam_, gnl_, desc_, dj_,song_, url_, cln_, clns_, max_, bit_, smpl_, chs_];
}

- (void)setSurlFromString:(NSString *)url
{
    surl_ = [NSURL URLWithString:url];
}

- (NSString *)timsToString
{
    if (timsToStringDateFormatter == nil) {
        timsToStringDateFormatter = [[NSDateFormatter alloc] init];
        [timsToStringDateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [timsToStringDateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return [timsToStringDateFormatter stringFromDate:tims_];
}

- (void)setTimsFromString:(NSString *)tims
{
    if (setTimsFromStringDateFormatter == nil) {
        setTimsFromStringDateFormatter = [[NSDateFormatter alloc] init];
        [setTimsFromStringDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]]; // 番組表は日本時間
        [setTimsFromStringDateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
        
    }
    tims_ = [setTimsFromStringDateFormatter dateFromString:tims];
}

- (void)setUrlFromString:(NSString *)url
{
    url_ = [NSURL URLWithString:url];
}

- (NSURL *)playUrl
{
    NSString *url = [NSString stringWithFormat:@"http://%@:%d%@", srv_, prt_, mnt_];
    return [NSURL URLWithString:url];
}

- (BOOL)favorite
{
    FavoriteManager *favoriteManager = [FavoriteManager sharedInstance];
    return [favoriteManager isFavorite:self];
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

    // 検索単語を辞書に登録する
    // 辞書は Key:検索単語 Value:マッチしたか
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] initWithCapacity:[searchWords count]];
    for (NSString *word in searchWords) {
        if (!([word length] == 0)) {
            [searchDictionary setObject:[NSNumber numberWithBool:NO] forKey:word];
        }
    }

    // 検索対象文字列を配列にする
    NSMutableArray *searchedWords = [[NSMutableArray alloc] initWithCapacity:4];
    if (!([nam_ length] == 0)) {
        [searchedWords addObject:nam_];
    }
    if (!([gnl_ length] == 0)) {
        [searchedWords addObject:gnl_];
    }
    if (!([desc_ length] == 0)) {
        [searchedWords addObject:desc_];
    }
    if (!([dj_ length] == 0)) {
        [searchedWords addObject:dj_];
    }

    // 検索文字と検索対象文字を比較する
    for (NSString *searchedWord in searchedWords) {
        for (NSString *searchWord in [searchDictionary allKeys]) {
            // 見つかった場合は検索辞書の該当単語にYESを代入
            if ([searchedWord rangeOfString:searchWord
                                    options:(NSCaseInsensitiveSearch | NSLiteralSearch | NSWidthInsensitiveSearch)]
                    .location != NSNotFound) {
                [searchDictionary setObject:[NSNumber numberWithBool:YES] forKey:searchWord];
            }
        }
    }

    // すべての検索単語がマッチした場合にのみYESを返す
    for (NSNumber *match in [searchDictionary allValues]) {
        if ([match boolValue] == NO) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isSameMount:(Channel *)channel
{
    if (channel == nil) {
        return NO;
    }
    return [mnt_ isEqualToString:channel.mnt];
}

#pragma mark - Comparison Methods

- (NSComparisonResult)compareNewly:(Channel *)channel
{
    NSComparisonResult result;

    // お気に入りで比較する
    result = [Channel compareFavorite:self compared:channel];
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
    result = [Channel compareFavorite:self compared:channel];
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
    result = [Channel compareFavorite:self compared:channel];
    if (result != NSOrderedSame) {
        return result;
    }

    // タイトルで比較
    result = [Channel compareString:self.nam compared:channel.nam];
    if (result != NSOrderedSame) {
        return result;
    }

    // タイトルおなじ場合はDJで比較
    result = [Channel compareString:self.dj compared:channel.dj];
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
    result = [Channel compareFavorite:self compared:channel];
    if (result != NSOrderedSame) {
        return result;
    }

    // DJで比較
    result = [Channel compareString:self.dj compared:channel.dj];
    if (result != NSOrderedSame) {
        return result;
    }

    // DJがおなじ場合はタイトルで比較
    result = [Channel compareString:self.nam compared:channel.nam];
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
    if (!([str1 length] == 0) && ([str2 length] == 0)) {
        return NSOrderedAscending;
    } else if (([str1 length] == 0) && !([str2 length] == 0)) {
        return NSOrderedDescending;
    } else if (([str1 length] == 0) && ([str2 length] == 0)) {
        return NSOrderedSame;
    } else {
        NSString *trimStr1 = [str1
                              stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]];
        NSString *trimStr2 = [str2
                              stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]];
        return [trimStr1 localizedCaseInsensitiveCompare:trimStr2];
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
        gnl_ = [coder decodeObjectForKey:@"GNL"];
        desc_ = [coder decodeObjectForKey:@"DESC"];
        dj_ = [coder decodeObjectForKey:@"DJ"];
        song_ = [coder decodeObjectForKey:@"SONG"];
        url_ = [coder decodeObjectForKey:@"URL"];
        cln_ = [coder decodeIntegerForKey:@"CLN"];
        clns_ = [coder decodeIntegerForKey:@"CLNS"];
        max_ = [coder decodeIntegerForKey:@"MAX"];
        bit_ = [coder decodeIntegerForKey:@"BIT"];
        smpl_ = [coder decodeIntegerForKey:@"SMPL"];
        chs_ = [coder decodeIntegerForKey:@"CHS"];
    }
    return self;
}

@end
