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

#import "FavoriteManager.h"
#import "Channel.h"

@implementation Channel

@synthesize surl;
@synthesize tims;
@synthesize srv ;
@synthesize prt;
@synthesize mnt;
@synthesize type;
@synthesize nam;
@synthesize gnl;
@synthesize desc;
@synthesize dj;
@synthesize song;
@synthesize url;
@synthesize cln;
@synthesize clns;
@synthesize max;
@synthesize bit;
@synthesize smpl;
@synthesize chs;
@synthesize favorite;

- (id)init
{
    if(self = [super init]){
        surl = nil;
        tims = nil;
        srv = nil;
        prt = 0;
        mnt = nil;
        type = nil;
        nam = nil;
        gnl = nil;
        desc = nil;
        dj = nil;
        song = nil;
        url = nil;
        cln = CHANNEL_UNKNOWN_LISTENER_NUM;
        clns = CHANNEL_UNKNOWN_LISTENER_NUM;
        max = CHANNEL_UNKNOWN_LISTENER_NUM;
        bit = CHANNEL_UNKNOWN_BITRATE_NUM;
        smpl = CHANNEL_UNKNOWN_SAMPLING_RATE_NUM;
        chs = CHANNEL_UNKNOWN_CHANNEL_NUM;
    }
    return self;
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<%@ :%p ,surl:%@ tims:%@ srv:%@ prt:%d mnt:%@ type:%@ nam:%@ gnl:%@ desc:%@ dj:%@ song:%@ url:%@ cln:%d clns:%d max:%d bit:%d smpl:%d chs:%d>",
            NSStringFromClass([self class]), self, surl, tims, srv, prt, mnt, type, nam, gnl, desc, dj, song, url, cln, clns, max, bit, smpl, chs];
}

- (void)setSurlFromString:(NSString*)u
{
    surl = [NSURL URLWithString:u];
}

- (void)setTimsFromString:(NSString*)t
{
    @autoreleasepool {
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
        tims = [format dateFromString:t];
    }
}

- (NSString*)getTimsToString
{
    @autoreleasepool {
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
        return [format stringFromDate:tims];
    }
}

- (void)setUrlFromString:(NSString*)u
{
    url = [NSURL URLWithString:u];
}

- (NSURL*)getPlayUrl
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d%@", srv, prt, mnt]];
}

- (BOOL)favorite
{
    FavoriteManager *favoriteManager = [FavoriteManager getFavoriteManager];
    return [favoriteManager isFavorite:mnt];
}

- (void)setFavorite:(BOOL)favorite
{
    FavoriteManager *favoriteManager = [FavoriteManager getFavoriteManager];
    [favoriteManager addFavorite:mnt];
}

- (BOOL) isMatch:(NSArray*)searchWords
{
    // フィルタリング単語が指定されていない場合は無条件に合致する
    if ([searchWords count] == 0) {
        return YES;
    }

    // 検索単語を辞書に登録する
    // 辞書は Key:検索単語 Value:マッチしたか
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc]initWithCapacity:[searchWords count]];
    for (NSString* word in searchWords) {
        if (!([word length] == 0)) {
            [searchDictionary setObject:[NSNumber numberWithBool:NO] forKey:word];
        }
    }

    // 検索対象文字列を配列にする
    NSMutableArray *searchedWords = [[NSMutableArray alloc] initWithCapacity:4];
    if (!([nam length] == 0)) {
        [searchedWords addObject:nam];
    }
    if (!([gnl length] == 0)) {
        [searchedWords addObject:gnl];
    }
    if (!([desc length] == 0)) {
        [searchedWords addObject:desc];
    }
    if (!([dj length] == 0)) {
        [searchedWords addObject:dj];
    }

    // 検索文字と検索対象文字を比較する
    for (NSString *searchedWord in searchedWords) {
        for (NSString* searchWord in [searchDictionary allKeys]) {
            // 見つかった場合は検索辞書の該当単語にYESを代入
            if ([searchedWord rangeOfString:searchWord options:(NSCaseInsensitiveSearch|NSLiteralSearch|NSWidthInsensitiveSearch)].location != NSNotFound) {
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

- (NSComparisonResult) compareNewly:(Channel*)_channel
{
    NSComparisonResult result;
    
    // お気に入りで比較する
    result = [Channel compareFavorite:self compared:_channel];
    if (result != NSOrderedSame) {
        return result;
    }
    
    // 新しい方が前に来る
    result = [_channel.tims compare:self.tims];
    
    return result;
}

- (NSComparisonResult) compareListeners:(Channel*)_channel
{
    NSComparisonResult result;

    // お気に入りで比較する
    result = [Channel compareFavorite:self compared:_channel];
    if (result != NSOrderedSame) {
        return result;
    }

    // リスナー数で比較する
    // 多い方が前に来る
    if (self.cln > _channel.cln) {
        result = NSOrderedAscending;
    } else if (self.cln < _channel.cln) {
        result = NSOrderedDescending;
    } else {
        result = NSOrderedSame;
    }

    return result;
}

- (NSComparisonResult) compareTitle:(Channel*)_channel
{
    NSComparisonResult result;

    // お気に入りで比較する
    result = [Channel compareFavorite:self compared:_channel];
    if (result != NSOrderedSame) {
        return result;
    }
    
    // タイトルで比較
    result = [Channel compareString:self.nam compared:_channel.nam];
    if (result != NSOrderedSame) {
        return result;
    }

    // タイトルおなじ場合はDJで比較
    result = [Channel compareString:self.dj compared:_channel.dj];
    if (result != NSOrderedSame) {
        return result;
    }

    // タイトルとDJがおなじ場合は日付で比較
    result = [self compareNewly:_channel];

    return result;
}

- (NSComparisonResult) compareDj:(Channel*)_channel
{
    NSComparisonResult result;

    // お気に入りで比較する
    result = [Channel compareFavorite:self compared:_channel];
    if (result != NSOrderedSame) {
        return result;
    }

    // DJで比較
    result = [Channel compareString:self.dj compared:_channel.dj];
    if (result != NSOrderedSame) {
        return result;
    }

    // DJがおなじ場合はタイトルで比較
    result = [Channel compareString:self.nam compared:_channel.nam];
    if (result != NSOrderedSame) {
        return result;
    }

    // タイトルとDJがおなじ場合は日付で比較
    result = [self compareNewly:_channel];

    return result;
}

+ (NSComparisonResult) compareString:(NSString*)str1 compared:(NSString*)str2
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

+ (NSComparisonResult) compareFavorite:(Channel*)channel1 compared:(Channel*)channel2
{
    NSComparisonResult result;

    // お気に入りで比較する。
    // お気に入りがある場合は前に来る。
    if (channel1.favorite == YES && channel2.favorite == NO) {
        result = NSOrderedAscending;
    } else if (channel1.favorite == NO && channel2.favorite == YES) {
        result = NSOrderedDescending;
    } else {
        result = NSOrderedSame;
    }
    return result;
}

@end
