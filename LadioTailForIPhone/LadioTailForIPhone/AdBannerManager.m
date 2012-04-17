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
    ADBannerView *adBannerView;
    CGRect showRect;
    CGRect hiddenRect;
}

@synthesize bannerSibling;
@synthesize isBannerVisible;

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
        isBannerVisible = NO;
    }
    return self;
}

- (void)dealloc
{
    adBannerView.delegate = nil;
}

- (void)setShowPosition:(CGPoint)position hiddenPosition:(CGPoint)hPosition
{
    showRect.origin.x = position.x;
    showRect.origin.y = position.y;
    showRect.size.width = 320;
    showRect.size.height = 50;
    hiddenRect.origin.x = hPosition.x;
    hiddenRect.origin.y = hPosition.y;
    hiddenRect.size.width = 320;
    hiddenRect.size.height = 50;

    [adBannerView setFrame:hiddenRect];
}

- (UIView*)bannerSibling
{
    return bannerSibling;
}

- (void)setBannerSibling:(UIView*)view
{
    // adBannerViewを生成
    if (adBannerView == nil) {
        adBannerView = [[ADBannerView alloc] initWithFrame: CGRectMake(0, 0, 320, 50)];
        adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        adBannerView.hidden = YES; // 画面外からの遷移の場合、画面外にあるとViewがちらつくので消す
        adBannerView.delegate = self;
    }

    if (bannerSibling != view) {
        [adBannerView removeFromSuperview];

        bannerSibling = view;

        // 新しいbannerSiblingが存在する場合
        if (bannerSibling != nil) {
            [bannerSibling addSubview:adBannerView];
            if (isBannerVisible) {
                [self show];
            }
        }
    }
}

- (void)show
{
    NSLog(@"Show iAD banner.");
    
    if (bannerSibling != nil) {
        [adBannerView setFrame:hiddenRect];
        
        // iADバナーを表示状態にする
        adBannerView.hidden = NO;
        
        [UIView
         animateWithDuration:AD_VIEW_ANIMATION_DURATION
         animations:^{
             adBannerView.frame = showRect;
         }];
    } else {
        // iADバナーを表示状態にする
        adBannerView.hidden = NO;
        
        [adBannerView setFrame:showRect];
    }
    
    isBannerVisible = YES;
}

- (void)hide
{
    NSLog(@"Hide iAD banner.");
    
    if (bannerSibling != nil) {
        [adBannerView setFrame:showRect];
        
        [UIView
         animateWithDuration:AD_VIEW_ANIMATION_DURATION
         animations:^{
             adBannerView.frame = hiddenRect;
         }
         completion:^(BOOL finished) {
             // AdBannerViewを隠す
             adBannerView.hidden = YES;
         }];
    } else {
        // AdBannerViewを隠す
        adBannerView.hidden = YES;
        
        [adBannerView setFrame:hiddenRect];
    }
    
    isBannerVisible = NO;
}

#pragma mark ADBannerViewDelegate methods

- (BOOL)bannerViewActionShouldBegin:(ADBannerView*)banner willLeaveApplication:(BOOL)willLeave
{
    // 広告をはいつでも表示可能
    return YES;
}

// iADバナーが読み込み終わった
- (void)bannerViewDidLoadAd:(ADBannerView*)banner
{
    NSLog(@"iAD banner load complated.");

    // iADバナー未表示状態の場合
    if (isBannerVisible == NO && adBannerView != nil) {
        [self show];
    }
}

// iADバナーの読み込みに失敗
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError*)error
{
    NSLog(@"Received iAD banner error. Error : %@", [error localizedDescription]);

    // iADバナー表示済み状態の場合
    if (isBannerVisible == YES && adBannerView != nil) {
        [self hide];
    }
}

#pragma mark -

@end
