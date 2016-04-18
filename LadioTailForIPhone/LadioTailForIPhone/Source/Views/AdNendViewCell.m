/*
 * Copyright (c) 2013-2016 Yuichi Hirano
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

#import <NendSDK_iOS/NADView.h>
#import "AdNendViewCell.h"
#import "LadioTailConfig.h"

@interface AdNendViewCell () <NADViewDelegate>

@end

@implementation AdNendViewCell
{
    /// Nend View
    __weak NADView *nadView_;
    
    /// root view controller
    __weak UIViewController *rootViewController_;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // 選択時ハイライトなし
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        NADView *nadView = nil;
        // 広告Viewを生成
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            nadView = [[NADView alloc] initWithFrame:CGRectMake(0, 0, NAD_ADVIEW_SIZE_728x90.width, NAD_ADVIEW_SIZE_728x90.height)];
        } else {
            nadView = [[NADView alloc] initWithFrame:CGRectMake(0, 0, NAD_ADVIEW_SIZE_320x50.width, NAD_ADVIEW_SIZE_320x50.height)];
        }
        nadView_ = nadView;
        [nadView_ setNendID:[LadioTailConfig nendApiKey] spotID:[LadioTailConfig nendSpotId]];
        nadView_.isOutputLog = YES;
        nadView_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        nadView_.delegate = self;
        [self.contentView addSubview:nadView_];
    }
    return self;
}

- (void)dealloc
{
    nadView_.delegate = nil;
    [nadView_ removeFromSuperview];
    nadView_ = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    nadView_.center = self.contentView.center;
}

#pragma mark - Instance methods

- (CGSize)cellSize
{
    CGFloat width;
    CGFloat height;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        width = NAD_ADVIEW_SIZE_728x90.width;
        height = NAD_ADVIEW_SIZE_728x90.height + 2;
    } else {
        width = NAD_ADVIEW_SIZE_320x50.width;
        height = NAD_ADVIEW_SIZE_320x50.height + 2;
    }
    return CGSizeMake(width, height);
}

- (void)load
{
    [nadView_ load];
}

- (UIViewController*)rootViewController
{
    return rootViewController_;
}

- (void)setRootViewController:(UIViewController *)rootViewController
{
    rootViewController_ = rootViewController;
}

#pragma mark - NADViewDelegate

- (void)nadViewDidReceiveAd:(NADView *)adView
{
#if DEBUG
    NSLog(@"NADView succeed loading.");
#endif // #if DEBUG
}

#pragma mark - 広告受信に失敗した際に通知されます
- (void)nadViewDidFailToReceiveAd:(NADView *)adView
{
#if DEBUG
    NSLog(@"NADView failed loading.");
#endif // #if DEBUG
}

@end
