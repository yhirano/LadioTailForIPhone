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

- (NSComparisonResult) compareNewly:(Channel*)_channel
{
    // 新しい方が上に来る
    return [_channel.tims compare:self.tims];
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

- (NSComparisonResult) compareListeners:(Channel*)_channel
{
    if (self.cln > _channel.cln) {
        return NSOrderedAscending;
    } else if (self.cln < _channel.cln) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSComparisonResult) compareTitle:(Channel*)_channel
{
    // 名前で比較
    {
        NSString *sNam = [self.nam
                          stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceCharacterSet]];
        NSString *aNam = [_channel.nam
                          stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceCharacterSet]];
        
        // 空の場合はソート順位を下げる
        if (!([sNam length] == 0) && ([aNam length] == 0)) {
            return NSOrderedAscending;
        }
        if (([sNam length] == 0) && !([aNam length] ==0)) {
            return NSOrderedDescending;
        }
        
        // 名前で比較
        NSComparisonResult result = [sNam localizedCaseInsensitiveCompare:aNam];
        
        // ソート順位が確定した
        if (result != NSOrderedSame) {
            return result;
        }
    }
    
    // ソート順位が確定しない場合はDJで比較
    {
        NSString *sDj = [self.dj
                         stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]];
        NSString *aDj = [_channel.dj
                         stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]];
        
        // 空の場合はソート順位を下げる
        if (!([sDj length] == 0) && ([aDj length] == 0)) {
            return NSOrderedAscending;
        }
        if (([sDj length] == 0) && !([aDj length] == 0)) {
            return NSOrderedDescending;
        }
        
        // DJで比較
        NSComparisonResult result = [sDj localizedCaseInsensitiveCompare:aDj];
        
        // ソート順位が確定した
        if (result != NSOrderedSame) {
            return result;
        }
    }
    
    // まだ確定しない場合は日付で比較
    return [self compareNewly:_channel];
}

- (NSComparisonResult) compareDj:(Channel*)_channel
{
    // DJで比較
    {
        NSString *sDj = [self.dj
                         stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]];
        NSString *aDj = [_channel.dj
                         stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]];
        
        // 空の場合はソート順位を下げる
        if (!([sDj length] == 0) && ([aDj length] == 0)) {
            return NSOrderedAscending;
        }
        if (([sDj length] == 0) && !([aDj length] == 0)) {
            return NSOrderedDescending;
        }
        
        // DJで比較
        NSComparisonResult result = [sDj localizedCaseInsensitiveCompare:aDj];
        
        // ソート順位が確定した
        if (result != NSOrderedSame) {
            return result;
        }
    }

    // ソート順位が確定しない場合は名前で比較
    {
        NSString *sNam = [self.nam
                          stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceCharacterSet]];
        NSString *aNam = [_channel.nam
                          stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceCharacterSet]];
        
        // 空の場合はソート順位を下げる
        if (!([sNam length] == 0) && ([aNam length] == 0)) {
            return NSOrderedAscending;
        }
        if (([sNam length] == 0) && !([aNam length] ==0)) {
            return NSOrderedDescending;
        }
        
        // 名前で比較
        NSComparisonResult result = [sNam localizedCaseInsensitiveCompare:aNam];
        
        // ソート順位が確定した
        if (result != NSOrderedSame) {
            return result;
        }
    }
    
    // まだ確定しない場合は日付で比較
    return [self compareNewly:_channel];
}

@end
