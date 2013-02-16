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

#import "Html/FavoriteHtml.h"
#import "Favorite.h"

@implementation Favorite

- (id)init
{
    if (self = [super init]) {
        // とりあえず現在の時刻を入れておく
        _registedDate = [NSDate date];
    }
    return self;
}

- (NSString *)descriptionHtml {
    return [FavoriteHtml descriptionHtml:self];
}

#pragma mark - Comparison Methods

- (NSComparisonResult)compareNewly:(Favorite *)favorite
{
    return [favorite.registedDate compare:self.registedDate];
}

#pragma mark - NSCoding methods

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_registedDate forKey:@"REGISTED_DATE"];
    if (_channel != nil) {
        NSData *channelData = [NSKeyedArchiver archivedDataWithRootObject:_channel];
        [coder encodeObject:channelData forKey:@"CHANNEL"];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        _registedDate = [coder decodeObjectForKey:@"REGISTED_DATE"];
        NSData *channelData = [coder decodeObjectForKey:@"CHANNEL"];
        if (channelData != nil) {
            _channel = [NSKeyedUnarchiver unarchiveObjectWithData:channelData];
        }
    }
    return self;
}

@end
