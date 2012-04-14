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

#import "LadioLib/LadioLib.h"
#import "SVProgressHUD/SVProgressHUD.h"
#import "FetchHeadline.h"

@interface FetchHeadline ()

+ (void)addFetchHeadlineNotifications;

+ (void)removeFetchHeadlineNotifications;

@end

@implementation FetchHeadline

+ (void)fetchHeadlineStarted:(NSNotification *)notification
{
    [SVProgressHUD show];
}

+ (void)fetchHeadlineSuceed:(NSNotification *)notification
{
    [self removeFetchHeadlineNotifications];
    [SVProgressHUD dismiss];
}

+ (void)fetchHeadlineFailed:(NSNotification *)notification
{
    [self removeFetchHeadlineNotifications];
    NSString* errorStr = NSLocalizedString(@"Channel information could not be obtained.", @"番組表の取得に失敗"); 
    [SVProgressHUD dismissWithError:errorStr afterDelay:3];
}

+ (void)addFetchHeadlineNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchHeadlineStarted:) name:NOTIFICATION_NAME_FETCH_HEADLINE_STARTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchHeadlineSuceed:) name:NOTIFICATION_NAME_FETCH_HEADLINE_SUCEED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchHeadlineFailed:) name:NOTIFICATION_NAME_FETCH_HEADLINE_FAILED object:nil];
}

+ (void)removeFetchHeadlineNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NAME_FETCH_HEADLINE_STARTED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NAME_FETCH_HEADLINE_SUCEED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NAME_FETCH_HEADLINE_FAILED object:nil];
}

+ (void)fetchHeadline
{
    [self addFetchHeadlineNotifications];
    Headline *headline = [HeadlineManager getHeadline];
    [headline fetchHeadline];
}

@end
