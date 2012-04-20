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

#import "Favorite.h"

@implementation Favorite

@synthesize channel = channel_;
@synthesize registedDate = registedDate_;

- (id)init
{
    if (self = [super init]) {
        // とりあえず現在の時刻を入れておく
        registedDate_ = [NSDate date];
    }
    return self;
}

#pragma mark NSCoding methods

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:registedDate_ forKey:@"REGISTED_DATE"];
    if (channel_ != nil) {
        NSData *channelData = [NSKeyedArchiver archivedDataWithRootObject:channel_];
        [coder encodeObject:channelData forKey:@"CHANNEL"];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        registedDate_ = [coder decodeObjectForKey:@"REGISTED_DATE"];
        NSData *channelData = [coder decodeObjectForKey:@"CHANNEL"];
        if (channelData != nil) {
            channel_ = [NSKeyedUnarchiver unarchiveObjectWithData:channelData];
        }
    }
    return self;
}

#pragma mark -

@end
