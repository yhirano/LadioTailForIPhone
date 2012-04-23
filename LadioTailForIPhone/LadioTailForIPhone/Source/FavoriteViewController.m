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
#import "ChannelsHtml.h"
#import "WebPageViewController.h"
#import "FavoriteViewController.h"

/// 戻るボタンの色
#define BACK_BUTTON_COLOR [UIColor darkGrayColor]

/// リンクをクリックするとSafariが開く
#define OPEN_SAFARI_WHEN_CLICK_LINK 0

@implementation FavoriteViewController

@synthesize favorite = favorite_;
@synthesize topNavigationItem = topNavigationItem_;
@synthesize descriptionWebView = descriptionWebView_;
@synthesize bottomView = bottomView_;

#pragma mark Private methods

- (void)writeDescription
{
    if (favorite_ == nil) {
        return;
    }
    
    NSString *html = [ChannelsHtml favoritelViewHtml:favorite_];
    
    // HTMLが取得できない場合（実装エラーと思われる）は何もしない
    if (html == nil) {
        return;
    }
    
    // WebViewへのhtmlの書き込みは loadHTMLString:baseURL: だと遅い（ビューが表示されてからワンテンポ後に表示）ので
    // JavaScriptの document.write() で直接書き込む
    // http://d.hatena.ne.jp/PoohKid/20110920/1316523493
    NSString *escapedHtml = [html stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]; // "をエスケープ
    escapedHtml = [escapedHtml stringByReplacingOccurrencesOfString:@"\n" withString:@""]; //改行をエスケープ
    NSString *jsString = [NSString stringWithFormat:@"document.write(\"%@\"); document.close();", escapedHtml];
    [self.descriptionWebView stringByEvaluatingJavaScriptFromString:jsString];
}

#pragma mark - UIView methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // ナビゲーションタイトルを表示する
    // タイトルが存在する場合はタイトルを表示する
    NSString *titleString;
    if (!([favorite_.channel.nam length] == 0)) {
        titleString = favorite_.channel.nam;
    }
    // DJが存在する場合はDJを表示する
    else if (!([favorite_.channel.dj length] == 0)) {
        titleString = favorite_.channel.dj;
    }
    // それ以外はマウントを表示
    else {
        titleString = favorite_.channel.mnt;
    }
    topNavigationItem_.title = titleString;

    // Web画面からの戻るボタンのテキストと色を書き換える
    NSString *backButtonString = titleString;
    if ([backButtonString length] == 0) {
        backButtonString = NSLocalizedString(@"Back", @"戻る");
    }
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:backButtonString
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
    backButtonItem.tintColor = BACK_BUTTON_COLOR;
    self.navigationItem.backBarButtonItem = backButtonItem;

    // 下部Viewの背景色をグラデーションに
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = bottomView_.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id) [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1].CGColor,
                       (id) [UIColor colorWithRed:0 green:0 blue:0 alpha:1].CGColor,
                       nil];
    [bottomView_.layer insertSublayer:gradient atIndex:0];
    
    // 表示情報を生成する
    [self writeDescription];
}

- (void)viewDidUnload
{
    [self setDescriptionWebView:nil];
    [self setBottomView:nil];
    [self setTopNavigationItem:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // 広告を表示する
    ADBannerView *adBannerView = [AdBannerManager sharedInstance].adBannerView;
    [adBannerView setFrame:CGRectMake(320, 366, 320, 50)];
    if (adBannerView.bannerLoaded) {
        adBannerView.hidden = NO;
        [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION
                         animations:^{
                             adBannerView.frame = CGRectMake(0, 366, 320, 50);
                         }];
    }
    adBannerView.delegate = self;
    [self.view addSubview:adBannerView];

    // WebViewのデリゲートを設定する
    descriptionWebView_.delegate = self;
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
    descriptionWebView_.delegate = nil;
    
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // リンクを押した
    if ([[segue identifier] isEqualToString:@"OpenUrl"]) {
        // URLを遷移先のViewに設定
        UIViewController *viewCon = [segue destinationViewController];
        if ([viewCon isKindOfClass:[WebPageViewController class]]) {
            ((WebPageViewController *) viewCon).url = favorite_.channel.url;
        }
    }
}

#pragma mark - UIWebViewDelegate methods

- (BOOL)            webView:(UIWebView *)webView
 shouldStartLoadWithRequest:(NSURLRequest *)request
             navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeOther) {
        NSString *scheme = [[request URL] scheme];
        if ([scheme compare:@"about"] == NSOrderedSame) {
            return YES;
        }
        if ([scheme compare:@"http"] == NSOrderedSame) {
#if OPEN_SAFARI_WHEN_CLICK_LINK
            // リンクをクリック時、Safariを起動する
            [[UIApplication sharedApplication] openURL:[request URL]];
            return NO;
#else
            [self performSegueWithIdentifier:@"OpenUrl" sender:self];
            return NO;
#endif /* OPEN_SAFARI_WHEN_CLICK_LINK */
        }
    }
    return YES;
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
                         adBannerView.frame = CGRectMake(0, 366, 320, 50);
                     }];
}

// iADバナーの読み込みに失敗
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"Received iAD banner error. Error : %@", [error localizedDescription]);
    
    ADBannerView *adBannerView = [AdBannerManager sharedInstance].adBannerView;
    [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION
                     animations:^{
                         adBannerView.frame = CGRectMake(320, 366, 320, 50);
                     }
                     completion:^(BOOL finished)
                     {
                         // AdBannerViewを隠す
                         adBannerView.hidden = YES;
                     }];
}

@end
