/*
 * Copyright (c) 2012-2014 Yuichi Hirano
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
    NSString *serverName_;
    NSURL* listenUrl_;
    NSString *serverType_;
    NSString *genre_;
    NSInteger bitrate_;
    NSInteger sampleRate_;
    NSInteger channels_;

    BOOL hasHashCache_;
    NSUInteger hashCache_;
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
        _fid = -1;

        serverName_ = nil;
        listenUrl_ = nil;
        genre_ = nil;
        bitrate_ = 0;
        sampleRate_ = 0;
        channels_ = 0;

        hasHashCache_ = NO;
        hasFavoriteCache_ = NO;
        favoriteCache_ = NO;
        hasPlaySupportedCache_ = NO;
        playSupportedCache_ = NO;
    }
    return self;
}

- (NSString *)description
{
    NSString *format = @"<%@ :%p , serverName:%@ listenUrl:%@ serverType:%@ genre:%@ bitrate:%d _sampleRate:%d"
                        " _channels:%d>";
    return [NSString stringWithFormat:format, NSStringFromClass([self class]), self, serverName_, listenUrl_,
                                      serverType_, genre_, bitrate_, sampleRate_, channels_];
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
    if (self.serverName == nil) {
        if (otherChannel.serverName != nil) {
            return NO;
        }
    } else if (![self.serverName isEqual:otherChannel.serverName]) {
        return NO;
    }
    if (self.listenUrl == nil) {
        if (otherChannel.listenUrl != nil) {
            return NO;
        }
    } else if (![[self.listenUrl absoluteString] isEqual:[otherChannel.listenUrl absoluteString]]) {
        return NO;
    }
    if (self.serverType == nil) {
        if (otherChannel.serverType != nil) {
            return NO;
        }
    } else if (![self.serverType isEqual:otherChannel.serverType]) {
        return NO;
    }
    if (self.genre == nil) {
        if (otherChannel.genre != nil) {
            return NO;
        }
    } else if (![self.genre isEqual:otherChannel.genre]) {
        return NO;
    }
    if (self.bitrate != otherChannel.bitrate) {
        return NO;
    }
    if (self.sampleRate != otherChannel.sampleRate) {
        return NO;
    }
    if (self.channels != otherChannel.channels) {
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
    
    result = prime * result + [serverName_ hash];
    result = prime * result + [listenUrl_ hash];
    result = prime * result + [serverType_ hash];
    result = prime * result + [genre_ hash];
    result = prime * result + bitrate_;
    result = prime * result + sampleRate_;
    result = prime * result + channels_;

    hasHashCache_ = YES;
    hashCache_ = result;
    return result;
}

- (NSString*)serverName
{
    return serverName_;
}

- (void)setServerName:(NSString*)s
{
    serverName_ = s;
    _trimedServerName = [serverName_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    hasHashCache_ = NO;
}

- (NSURL*)listenUrl
{
    return listenUrl_;
}

- (void)setListenUrl:(NSURL*)url
{
    listenUrl_ = url;
    hasHashCache_ = NO;
}

- (NSString*)serverType
{
    return serverType_;
}

- (void)setServerType:(NSString*)s
{
    serverType_ = s;
    hasHashCache_ = NO;
    hasPlaySupportedCache_ = NO;
}

- (NSString*)genre
{
    return genre_;
}

- (void)setGenre:(NSString*)g
{
    genre_ = g;
    _trimedGenre = [genre_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    hasHashCache_ = NO;
}

- (NSInteger)bitrate
{
    return bitrate_;
}

- (void)setBitrate:(NSInteger)b
{
    bitrate_ = b;
    hasHashCache_ = NO;
}

- (NSInteger)sampleRate
{
    return sampleRate_;
}

- (void)setSampleRate:(NSInteger)s
{
    sampleRate_ = s;
    hasHashCache_ = NO;
}

- (NSInteger)channels
{
    return channels_;
}

- (void)setChannels:(NSInteger)c
{
    channels_ = c;
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
    NSMutableArray *searchedWords = [[NSMutableArray alloc] initWithCapacity:2];
    if ([serverName_ length] > 0) {
        [searchedWords addObject:serverName_];
    }
    if ([genre_ length] > 0) {
        [searchedWords addObject:genre_];
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

- (BOOL)isSameName:(Channel *)channel
{
    if (channel == nil) {
        return NO;
    }
    return [serverName_ isEqualToString:channel.serverName];
}

- (BOOL)isSameListenUrl:(Channel *)channel
{
    if (channel == nil) {
        return NO;
    }
    return [[listenUrl_ absoluteString] isEqualToString:[channel.listenUrl absoluteString]];
}

- (BOOL)isPlaySupported
{
    if (hasPlaySupportedCache_) {
        return playSupportedCache_;
    }
    
    BOOL result;
    
    // OSがサポートしているかをチェック
    result = [AVURLAsset isPlayableExtendedMIMEType:serverType_];
    // MIMEにvideoが含まれていないかをチェック
    if (result &&
        [serverType_ rangeOfString:@"video"
                           options:(NSCaseInsensitiveSearch | NSLiteralSearch)].location != NSNotFound) {
        result = NO;
    }
    
    hasPlaySupportedCache_ = YES;
    playSupportedCache_ = result;
    
    return result;
}

- (NSString *)filenameExtensionFromMimeType
{
    // MIME Typeから拡張子を取得
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)serverType_, NULL);
    NSString *result = (__bridge NSString*)UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
    CFRelease(uti);
    
    if (!result) {
        if ([serverType_ isEqualToString:@"audio/aac"]) {
            result = @"aac";
        } else if ([serverType_ isEqualToString:@"audio/aacp"]) {
            result = @"aac";
        } else if ([serverType_ isEqualToString:@"audio/3gpp"]) {
            result = @"3gp";
        } else if ([serverType_ isEqualToString:@"audio/3gpp2"]) {
            result = @"3g2";
        } else if ([serverType_ isEqualToString:@"audio/mp4"]) {
            result = @"mp4";
        } else if ([serverType_ isEqualToString:@"audio/MP4A-LATM"]) {
            result = @"mp4";
        } else if ([serverType_ isEqualToString:@"audio/mpeg4-generic"]) {
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
    result = [[self class] compareFavorite:self compared:channel];
    if (result != NSOrderedSame) {
        return result;
    }
    
    // fidで比較する
    // 低い方が前に来る
    if (self.fid < channel.fid) {
        result = NSOrderedAscending;
    } else if (self.fid > channel.fid) {
        result = NSOrderedDescending;
    } else {
        result = NSOrderedSame;
    }
    
    return result;
}

- (NSComparisonResult)compareServerName:(Channel *)channel
{
    NSComparisonResult result;

    // お気に入りで比較する
    result = [[self class] compareFavorite:self compared:channel];
    if (result != NSOrderedSame) {
        return result;
    }

    // Server Nameで比較
    result = [[self class] compareString:self.trimedServerName compared:channel.trimedServerName];
    if (result != NSOrderedSame) {
        return result;
    }

    // Server Nameおなじ場合はGenreで比較
    result = [[self class] compareString:self.trimedGenre compared:channel.trimedGenre];
    if (result != NSOrderedSame) {
        return result;
    }

    // Server NameとGenreがおなじ場合はBitrateで比較
    result = [self compareBitrate:channel];

    return result;
}

- (NSComparisonResult)compareGenre:(Channel *)channel
{
    NSComparisonResult result;

    // お気に入りで比較する
    result = [[self class] compareFavorite:self compared:channel];
    if (result != NSOrderedSame) {
        return result;
    }

    // Genreで比較
    result = [[self class] compareString:self.trimedGenre compared:channel.trimedGenre];
    if (result != NSOrderedSame) {
        return result;
    }
    
    // Genreおなじ場合はServer Nameで比較
    result = [[self class] compareString:self.trimedServerName compared:channel.trimedServerName];
    if (result != NSOrderedSame) {
        return result;
    }

    // Server NameとGenreがおなじ場合はBitrateで比較
    result = [self compareBitrate:channel];

    return result;
}

- (NSComparisonResult)compareBitrate:(Channel *)channel
{
    NSComparisonResult result;

    // お気に入りで比較する
    result = [[self class] compareFavorite:self compared:channel];
    if (result != NSOrderedSame) {
        return result;
    }

    // Bitrateで比較する
    // 高い方が前に来る
    if (self.bitrate > channel.bitrate) {
        result = NSOrderedAscending;
    } else if (self.bitrate < channel.bitrate) {
        result = NSOrderedDescending;
    } else {
        result = NSOrderedSame;
    }

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

#pragma mark - NSCoding methods

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:serverName_ forKey:@"SERVER_NAME"];
    [coder encodeObject:listenUrl_ forKey:@"LISTEN_URL"];
    [coder encodeObject:serverType_ forKey:@"SERVER_TYPE"];
    [coder encodeObject:genre_ forKey:@"GENRE"];
    [coder encodeInteger:bitrate_ forKey:@"BITRATE"];
    [coder encodeInteger:sampleRate_ forKey:@"SAMPLERATE"];
    [coder encodeInteger:channels_ forKey:@"CHANNELS"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        _fid = -1;

        serverName_ = [coder decodeObjectForKey:@"SERVER_NAME"];
        _trimedServerName = [serverName_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        listenUrl_ = [coder decodeObjectForKey:@"LISTEN_URL"];
        serverType_ = [coder decodeObjectForKey:@"SERVER_TYPE"];
        genre_ = [coder decodeObjectForKey:@"GENRE"];
        _trimedGenre = [genre_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        bitrate_ = [coder decodeIntegerForKey:@"BITRATE"];
        sampleRate_ = [coder decodeIntegerForKey:@"SAMPLERATE"];
        channels_ = [coder decodeIntegerForKey:@"CHANNELS"];

        hasHashCache_ = NO;
        hasFavoriteCache_ = NO;
        favoriteCache_ = NO;
    }
    return self;
}

@end
