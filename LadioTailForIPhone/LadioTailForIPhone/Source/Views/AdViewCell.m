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

#import "AdViewCell.h"
#import "../GoogleAdMobAds/GADBannerView.h"
#import "LadioTailConfig.h"

@interface AdViewCell () <GADBannerViewDelegate>

@end

@implementation AdViewCell
{
    /// AdMob View
    __weak GADBannerView *adMobView_;
    
    /// root view controller
    __weak UIViewController *rootViewController_;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // 選択時ハイライトなし
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        GADBannerView *adMobView = nil;
        // 広告Viewを生成
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            adMobView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeLeaderboard];
        } else {
            adMobView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        }
        adMobView_ = adMobView;
        adMobView_.adUnitID = [LadioTailConfig admobUnitId];
        adMobView_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        adMobView_.delegate = self;
        [self.contentView addSubview:adMobView_];
    }
    return self;
}

- (void)dealloc
{
    adMobView_.delegate = nil;
    [adMobView_ removeFromSuperview];
    adMobView_ = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    adMobView_.center = self.contentView.center;
}

#pragma mark - Instance methods

- (CGSize)cellSize
{
    CGFloat width;
    CGFloat height;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        width = kGADAdSizeLeaderboard.size.width;
        height = kGADAdSizeLeaderboard.size.height + 2;
    } else {
        width = kGADAdSizeBanner.size.width;
        height = kGADAdSizeBanner.size.height + 2;
    }
    return CGSizeMake(width, height);
}

- (void)load
{
    [adMobView_ loadRequest:[GADRequest request]];
}

- (UIViewController*)rootViewController
{
    return rootViewController_;
}

- (void)setRootViewController:(UIViewController *)rootViewController
{
    rootViewController_ = rootViewController;
    adMobView_.rootViewController = rootViewController;
}

#pragma mark - GADBannerViewDelegate method

- (void)adViewDidReceiveAd:(GADBannerView *)view
{
#if DEBUG
    NSLog(@"adMobView succeed loading.");
#endif // #if DEBUG
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
#if DEBUG
    NSLog(@"adMobView failed loading. error:%@", [error localizedDescription]);
#endif // #if DEBUG
}

@end
