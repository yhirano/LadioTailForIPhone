//
//  AdViewCell.m
//  LadioTailForIPhone
//
//  Created by Yuichi Hirano on 2013/02/11.
//  Copyright (c) 2013年 Y.Hirano. All rights reserved.
//

#import "AdViewCell.h"
#import "../../NendAd/NADView.h"
#import "../../AdLantis/AdlantisAdManager.h"
#import "../../AdLantis/AdlantisView.h"
#import "../../GoogleAdMobAds/GADBannerView.h"
#import "LadioTailConfig.h"

typedef enum : NSUInteger {
    AdModeTypeNone,
    AdModeTypeNend,
    AdModeTypeAdLantis,
    AdModeTypeAdMob,
} AdModeType;

@interface AdViewCell () <NADViewDelegate, GADBannerViewDelegate>

@end

@implementation AdViewCell
{
    /// 広告の表示モード
    AdModeType adModeType_;
    
    /// Nend Ad View
    __weak NADView *nadView_;

    __weak AdlantisView *adlantisView_;

    /// AdMob View
    __weak GADBannerView *adMobView_;
    
    /// root view controller
    __weak UIViewController *rootViewController_;
    
    /// 広告はポーズ中か
    BOOL isPaused_;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // 選択時ハイライトなし
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        // AdLantis Publiser IDを設定する
        if (ADLANTIS_ID) {
            AdlantisAdManager.sharedManager.publisherID = ADLANTIS_ID;
        }
        
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    nadView_.delegate = nil;
    [nadView_ removeFromSuperview];
    nadView_ = nil;
    [adlantisView_ removeFromSuperview];
    adlantisView_ = nil;
    adMobView_.delegate = nil;
    [adMobView_ removeFromSuperview];
    adMobView_ = nil;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
    
    switch (adModeType_) {
        case AdModeTypeNend:
            nadView_.center = self.contentView.center;
            break;
        case AdModeTypeAdMob:
            adMobView_.center = self.contentView.center;
            break;
        default:
            break;
    }
}

#pragma mark - Private methods

- (void)setup
{
    adModeType_ = AdModeTypeNone;
    
    [nadView_ removeFromSuperview];
    nadView_.delegate = nil;
    nadView_ = nil;
    [adlantisView_ removeFromSuperview];
    adlantisView_ = nil;
    [adlantisView_ removeFromSuperview];
    adlantisView_ = nil;
    
    // 端末の言語設定を取得
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *lang = @"";
    if (languages != nil && [languages count] > 0) {
        lang = [languages objectAtIndex:0];
    }
    
    // iPadの場合
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && ADMOB_PUBLISHER_ID) {
        [self addAdMobView];
    }
    // 日本語でない場合
    else if ((![lang isEqualToString:@"ja"]) && ADMOB_PUBLISHER_ID) {
        [self addAdMobView];
    }
    // Nendが設定されている場合
    else if (NEND_ID && NEND_SPOT_ID) {
        [self addNendView];
    }
    // AdLantisが設定されている場合
    else if (ADLANTIS_ID) {
        [self addAdLantisView];
    }
    // AdMobが設定されている場合
    else if (ADMOB_PUBLISHER_ID) {
        [self addAdMobView];
    }
    
    isPaused_ = NO;
}

#pragma mark - Instance methods

- (void)addNendView
{
    if (adModeType_ == AdModeTypeNend) {
        return;
    }
    
    [adlantisView_ removeFromSuperview];
    adlantisView_ = nil;
    [adMobView_ removeFromSuperview];
    adMobView_.delegate = nil;
    adMobView_ = nil;

    adModeType_ = AdModeTypeNend;
    // 広告Viewを生成
    NADView *nadView = [[NADView alloc] initWithFrame:CGRectMake(0,
                                                                 0,
                                                                 NAD_ADVIEW_SIZE_320x50.width,
                                                                 NAD_ADVIEW_SIZE_320x50.height)];
    nadView_ = nadView;
    [nadView_ setNendID:NEND_ID spotID:NEND_SPOT_ID];
    nadView_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    nadView_.delegate = self;
    [self.contentView addSubview:nadView_];
    [self setRootViewController:rootViewController_];
}

- (void)addAdLantisView
{
    if (adModeType_ == AdModeTypeAdLantis) {
        return;
    }

    [nadView_ removeFromSuperview];
    nadView_.delegate = nil;
    nadView_ = nil;
    [adMobView_ removeFromSuperview];
    adMobView_.delegate = nil;
    adMobView_ = nil;

    adModeType_ = AdModeTypeAdLantis;
    // 広告Viewを生成
    CGSize size = [AdlantisView sizeForOrientation:UIInterfaceOrientationPortrait];
    AdlantisView *adlantisView = [[AdlantisView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    adlantisView_ = adlantisView;
//    adlantisView_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.contentView addSubview:adlantisView_];
    [self setRootViewController:rootViewController_];
}

- (void)addAdMobView
{
    if (adModeType_ == AdModeTypeAdMob) {
        return;
    }

    [nadView_ removeFromSuperview];
    nadView_.delegate = nil;
    nadView_ = nil;
    [adlantisView_ removeFromSuperview];
    adlantisView_ = nil;

    adModeType_ = AdModeTypeAdMob;
    GADBannerView *adMobView = nil;
    // 広告Viewを生成
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        adMobView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeLeaderboard];
    } else {
        adMobView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    }
    adMobView_ = adMobView;
    adMobView_.adUnitID = ADMOB_PUBLISHER_ID;
    CGSize size = [self cellSize];
    adMobView_.frame = CGRectMake(0, 0, size.width, size.height);
    adMobView_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    adMobView_.delegate = self;
    [self.contentView addSubview:adMobView_];
    [self setRootViewController:rootViewController_];
}

- (CGSize)cellSize
{
    CGSize result = CGSizeZero;
    
    switch (adModeType_) {
        case AdModeTypeNend:
        {
            CGFloat width = NAD_ADVIEW_SIZE_320x50.width;
            CGFloat height = NAD_ADVIEW_SIZE_320x50.height;
            result = CGSizeMake(width, height);
            break;
        }
        case AdModeTypeAdLantis:
        {
            result = [AdlantisView sizeForOrientation:UIInterfaceOrientationPortrait];
            break;
        }
        case AdModeTypeAdMob:
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
            result = CGSizeMake(width, height);
            break;
        }
        default:
            break;
    }
    
    return result;
}

- (void)load
{
    switch (adModeType_) {
        case AdModeTypeNend:
            [nadView_ load];
            break;
        case AdModeTypeAdLantis:
            break;
        case AdModeTypeAdMob:
            [adMobView_ loadRequest:[GADRequest request]];
            break;
        default:
            break;
    }
}

- (void)pause
{
    switch (adModeType_) {
        case AdModeTypeNend:
            [nadView_ pause];
            break;
        case AdModeTypeAdLantis:
            break;
        case AdModeTypeAdMob:
            break;
        default:
            break;
    }

    isPaused_ = YES;
}

- (void)resume
{
    if (!isPaused_) {
        return;
    }

    switch (adModeType_) {
        case AdModeTypeNend:
            [nadView_ resume];
            break;
        case AdModeTypeAdLantis:
            break;
        case AdModeTypeAdMob:
            break;
        default:
            break;
    }
}

- (UIViewController*)rootViewController
{
    return rootViewController_;
}

- (void)setRootViewController:(UIViewController *)rootViewController
{
    rootViewController_ = rootViewController;
    switch (adModeType_) {
        case AdModeTypeNend:
            nadView_.rootViewController = rootViewController;
            break;
        case AdModeTypeAdLantis:
            break;
        case AdModeTypeAdMob:
            adMobView_.rootViewController = rootViewController;
            break;
        default:
            break;
    }
}

#pragma mark - UITableViewCell methods

- (void)prepareForReuse
{
    [super prepareForReuse];

    [self setup];
}

#pragma mark - NADViewDelegate methods

// NADViewのロードが成功した時に呼ばれる
- (void)nadViewDidFinishLoad:(NADView *)adView
{
#if DEBUG
    NSLog(@"nadView start loading.");
#endif // #if DEBUG
}

// 広告受信成功
-(void)nadViewDidReceiveAd:(NADView *)adView
{
#if DEBUG
    NSLog(@"nadView succeed loading.");
#endif // #if DEBUG
}

// 広告受信エラー
-(void)nadViewDidFailToReceiveAd:(NADView *)adView
{
#if DEBUG
    NSLog(@"nadView failed loading.");
#endif // #if DEBUG

    if (ADLANTIS_ID) {
        // AdLantisの表示に切り替える
        [self addAdLantisView];
        [self setNeedsLayout];
        [self load];
    } else if (ADMOB_PUBLISHER_ID) {
        // AdMobの表示に切り替える
        [self addAdMobView];
        [self setNeedsLayout];
        [self load];
    }
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
    NSLog(@"adMobView failed loading.");
#endif // #if DEBUG
}

@end
