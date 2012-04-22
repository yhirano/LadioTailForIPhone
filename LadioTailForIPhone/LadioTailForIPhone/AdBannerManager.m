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

#import "AdBannerManager.h"

/// iADビューの表示アニメーションの秒数
#define AD_VIEW_ANIMATION_DURATION 0.6

static AdBannerManager *instance = nil;

@implementation AdBannerManager
{
@private
    ADBannerView *adBannerView_;
    CGRect showRect_;
    CGRect hiddenRect_;
}

@synthesize bannerSibling = bannerSibling_;
@synthesize isBannerVisible = isBannerVisible_;

+ (AdBannerManager *)sharedInstance
{
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[AdBannerManager alloc] init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        isBannerVisible_ = NO;
    }
    return self;
}

- (void)dealloc
{
    adBannerView_.delegate = nil;
}

- (void)setShowPosition:(CGPoint)position hiddenPosition:(CGPoint)hPosition
{
    showRect_.origin.x = position.x;
    showRect_.origin.y = position.y;
    showRect_.size.width = 320;
    showRect_.size.height = 50;
    hiddenRect_.origin.x = hPosition.x;
    hiddenRect_.origin.y = hPosition.y;
    hiddenRect_.size.width = 320;
    hiddenRect_.size.height = 50;

    [adBannerView_ setFrame:hiddenRect_];
}

- (UIView *)bannerSibling
{
    return bannerSibling_;
}

- (void)setBannerSibling:(UIView *)view
{
    // adBannerViewを生成
    if (adBannerView_ == nil) {
        adBannerView_ = [[ADBannerView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
        adBannerView_.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        adBannerView_.hidden = YES; // 画面外からの遷移の場合、画面外にあるとViewがちらつくので消す
        adBannerView_.delegate = self;
    }

    if (bannerSibling_ != view) {
        [adBannerView_ removeFromSuperview];

        bannerSibling_ = view;

        // 新しいbannerSiblingが存在する場合
        if (bannerSibling_ != nil) {
            [bannerSibling_ addSubview:adBannerView_];
            if (isBannerVisible_) {
                [self show];
            }
        }
    }
}

#pragma mark - Private methods

- (void)show
{
    NSLog(@"Show iAD banner.");
    
    if (bannerSibling_ != nil) {
        [adBannerView_ setFrame:hiddenRect_];

        // iADバナーを表示状態にする
        adBannerView_.hidden = NO;

        [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION
                         animations:^{
                                         adBannerView_.frame = showRect_;
                                     }];
    } else {
        // iADバナーを表示状態にする
        adBannerView_.hidden = NO;

        [adBannerView_ setFrame:showRect_];
    }

    isBannerVisible_ = YES;
}

- (void)hide
{
    NSLog(@"Hide iAD banner.");

    if (bannerSibling_ != nil) {
        [adBannerView_ setFrame:showRect_];

        [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION
                         animations:^{
                                         adBannerView_.frame = hiddenRect_;
                                     }
                         completion:^(BOOL finished)
                                    {
                                        // AdBannerViewを隠す
                                        adBannerView_.hidden = YES;
                                    }];
    } else {
        // AdBannerViewを隠す
        adBannerView_.hidden = YES;

        [adBannerView_ setFrame:hiddenRect_];
    }

    isBannerVisible_ = NO;
}

#pragma mark - ADBannerViewDelegate methods

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    // 広告をはいつでも表示可能
    return YES;
}

// iADバナーが読み込み終わった
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"iAD banner load complated.");

    // iADバナー未表示状態の場合
    if (isBannerVisible_ == NO && adBannerView_ != nil) {
        // バナーを表示する
        [self show];
    }
}

// iADバナーの読み込みに失敗
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"Received iAD banner error. Error : %@", [error localizedDescription]);

    // iADバナー表示済み状態の場合
    if (isBannerVisible_ && adBannerView_ != nil) {
        // バナーを表しない
        [self hide];
    }
}

@end
