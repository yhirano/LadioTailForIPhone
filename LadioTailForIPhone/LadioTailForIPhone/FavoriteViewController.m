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

/// リンクをクリックするとSafariが開く
#define OPEN_SAFARI_WHEN_CLICK_LINK 0

@implementation FavoriteViewController

@synthesize favorite = favorite_;
@synthesize topNavigationItem = topNavigationItem_;
@synthesize descriptionWebView = descriptionWebView_;
@synthesize bottomView = bottomView_;

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
    if (!([favorite_.channel.nam length] == 0)) {
        topNavigationItem_.title = favorite_.channel.nam;
    }
    // DJが存在する場合はDJを表示する
    else if (!([favorite_.channel.dj length] == 0)) {
        topNavigationItem_.title = favorite_.channel.dj;
    }
    // それ以外はマウントを表示
    else {
        topNavigationItem_.title = favorite_.channel.mnt;
    }

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
    
    // WebViewのデリゲートを設定する
    descriptionWebView_.delegate = self;
    
    // 広告を表示する
    AdBannerManager *adBannerManager = [AdBannerManager sharedInstance];
    [adBannerManager setShowPosition:CGPointMake(0, 366) hiddenPosition:CGPointMake(320, 366)];
    adBannerManager.bannerSibling = self.view;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // WebViewのデリゲートを削除する
    descriptionWebView_.delegate = nil;
    
    [super viewWillDisappear:animated];
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

@end
