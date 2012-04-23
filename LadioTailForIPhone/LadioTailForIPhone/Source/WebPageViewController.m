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

#import <QuartzCore/QuartzCore.h>
#import "AdBannerManager.h"
#import "WebPageViewController.h"

@implementation WebPageViewController
{
@private
    /// ページを読み込み中か
    BOOL isPageLoading_;
}

@synthesize url = url_;
@synthesize topNavigationItem = topNavigationItem_;
@synthesize pageWebView = pageWebView_;
@synthesize backButton = backButton_;
@synthesize forwardButton = forwardButton_;
@synthesize reloadButton = reloadButton_;
@synthesize bottomView = bottomView_;

#pragma mark - Private methods

- (void)updateViews
{
    NSString* title = [pageWebView_ stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (!([title length] == 0)) {
        topNavigationItem_.title = title;
    }

    backButton_.enabled = pageWebView_.canGoBack;
    forwardButton_.enabled = pageWebView_.canGoForward;
    if (isPageLoading_) {
        [reloadButton_ setImage:[UIImage imageNamed:@"button_reload_stop.png"] forState:UIControlStateNormal];
    } else {
        [reloadButton_ setImage:[UIImage imageNamed:@"button_reload.png"] forState:UIControlStateNormal];
    }
}

#pragma mark - Actions

- (IBAction)back:(id)sender
{
    if (pageWebView_.canGoBack) {
        [pageWebView_ goBack];
    }
}

- (IBAction)forward:(id)sender
{
    if (pageWebView_.canGoForward) {
        [pageWebView_ goForward];
    }
}

- (IBAction)goToBottom:(id)sender
{
    int pageHeight = pageWebView_.scrollView.contentSize.height;
    if (pageHeight == 0) {
        return;
    }
    
    CGPoint movePoint = CGPointMake(
                                    pageWebView_.scrollView.contentOffset.x,
                                    pageHeight - pageWebView_.frame.size.height);
#ifdef DEBUG
    NSLog(@"Page scroll form %@ to %@.",
          NSStringFromCGPoint(pageWebView_.scrollView.contentOffset),
          NSStringFromCGPoint(movePoint));
#endif /* #ifdef DEBUG */
    [pageWebView_.scrollView setContentOffset:movePoint animated:YES];
}

- (IBAction)reload:(id)sender
{
    if (isPageLoading_) {
        [pageWebView_ stopLoading];
    } else {
        [pageWebView_ reload];
    }
}

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    [pageWebView_ loadRequest:[NSURLRequest requestWithURL:url_]];

    // 下部Viewの背景色をグラデーションに
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = bottomView_.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id) [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1].CGColor,
                                                (id) [UIColor colorWithRed:0 green:0 blue:0 alpha:1].CGColor,
                                                nil];
    [bottomView_.layer insertSublayer:gradient atIndex:0];
}

- (void)viewDidUnload
{
    [self setPageWebView:nil];
    [self setBackButton:nil];
    [self setForwardButton:nil];
    [self setReloadButton:nil];
    [self setTopNavigationItem:nil];
    [self setBottomView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // ボタン類の表示を更新する
    [self updateViews];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // 広告を表示する
    ADBannerView *adBannerView = [AdBannerManager sharedInstance].adBannerView;
    [adBannerView setFrame:CGRectMake(320, 316, 320, 50)];
    if (adBannerView.bannerLoaded) {
        adBannerView.hidden = NO;
        [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION
                         animations:^{
                             adBannerView.frame = CGRectMake(0, 316, 320, 50);
                         }];
    }
    adBannerView.delegate = self;
    [self.view addSubview:adBannerView];

    // WebViewのデリゲートを設定する
    pageWebView_.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // 広告の表示を消す
    ADBannerView *adBannerView = [AdBannerManager sharedInstance].adBannerView;
    if (adBannerView.bannerLoaded == NO) {
        adBannerView.hidden = YES;
    }
    adBannerView.delegate = nil;

    // WebViewのデリゲートを削除する
    pageWebView_.delegate = nil;
    
    // WebViewの読み込みを中止する
    [pageWebView_ stopLoading];
    
    if (isPageLoading_) {
        // ネットワークインジケーターを消す
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    // 広告Viewを削除
    ADBannerView *adBannerView = [AdBannerManager sharedInstance].adBannerView;
    [adBannerView removeFromSuperview];
    
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIWebViewDelegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    // ネットワークインジケーターを表示
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    // ページ読み込み中フラグを上げる
    isPageLoading_ = YES;

    // ボタン類の表示を更新する
    [self updateViews];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // ネットワークインジケーターを消す
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    // ページ読み込み中フラグを下げる
    isPageLoading_ = NO;

    // ボタン類の表示を更新する
    [self updateViews];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // ネットワークインジケーターを消す
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    // ページ読み込み中フラグを下げる
    isPageLoading_ = NO;

    // ボタン類の表示を更新する
    [self updateViews];
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
    
    ADBannerView *adBannerView = [AdBannerManager sharedInstance].adBannerView;
    adBannerView.hidden = NO;
    [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION
                     animations:^{
                         adBannerView.frame = CGRectMake(0, 316, 320, 50);
                     }];
}

// iADバナーの読み込みに失敗
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"Received iAD banner error. Error : %@", [error localizedDescription]);
    
    ADBannerView *adBannerView = [AdBannerManager sharedInstance].adBannerView;
    [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION
                     animations:^{
                         adBannerView.frame = CGRectMake(320, 316, 320, 50);
                     }
                     completion:^(BOOL finished)
     {
         // AdBannerViewを隠す
         adBannerView.hidden = YES;
     }];
}

@end
