/*
 * Copyright (c) 2013-2014 Yuichi Hirano
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

#import "Player.h"
#import "SleepTimer.h"

@implementation SleepTimer
{
    NSTimer *timer_;
}

+ (SleepTimer *)sharedInstance
{
    static SleepTimer *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[SleepTimer alloc] init];
    });
    return instance;
}

- (void)setSleepTimerWithInterval:(NSTimeInterval)seconds
{
    if (seconds < 0) {
        [self stop];
        return;
    }
    
    if (timer_) {
        [timer_ invalidate];
        timer_ = nil;
    }
    
    NSLog(@"Set sleep timer after %f seconds", seconds);

    timer_ = [NSTimer scheduledTimerWithTimeInterval:seconds
                                              target:self
                                            selector:@selector(fireSleepTimer:)
                                            userInfo:nil
                                             repeats:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailSleepTimerUpdate object:nil];
}

- (void)stop
{
    NSLog(@"Stop sleep timer");

    [timer_ invalidate];
    timer_ = nil;

    [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailSleepTimerUpdate object:nil];
}

- (NSDate *)fireDate
{
    return [timer_ fireDate];
}

#pragma mark - Private methods

- (void)fireSleepTimer:(NSTimer *)timer
{
    NSLog(@"Fire sleep timer");
    Player *player = [Player sharedInstance];
    [player stop];

    [self stop];
    [[NSNotificationCenter defaultCenter] postNotificationName:LadioTailSleepTimerFired object:nil];
}

@end
