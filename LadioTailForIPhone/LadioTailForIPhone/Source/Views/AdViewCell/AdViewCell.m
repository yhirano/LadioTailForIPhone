//
//  AdViewCell.m
//  LadioTailForIPhone
//
//  Created by Yuichi Hirano on 2013/02/11.
//  Copyright (c) 2013年 Y.Hirano. All rights reserved.
//

#import "AdViewCell.h"
#import "../../GoogleAdMobAds/GADBannerView.h"
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
        adMobView_.adUnitID = [LadioTaifConfig admobUnitId];
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
