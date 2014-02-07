/*
 * Copyright (c) 2012-2014 Yuichi Hirano
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
#import "LadioTailConfig.h"
#import "WebPageViewController.h"

@interface WebPageViewController () <UIWebViewDelegate>

@end

@implementation WebPageViewController
{
    /// ページを読み込み中か
    BOOL isPageLoading_;
}

#pragma mark - Private methods

- (void)updateViews
{
    NSString* title = [_pageWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if ([title length] > 0) {
        _topNavigationItem.title = title;
    }

    _backButton.enabled = _pageWebView.canGoBack;
    _forwardButton.enabled = _pageWebView.canGoForward;
    if (isPageLoading_) {
        [_reloadButton setImage:[UIImage imageNamed:@"button_reload_stop"] forState:UIControlStateNormal];
        _reloadButton.accessibilityLabel = NSLocalizedString(@"Stop", @"停止");
    } else {
        [_reloadButton setImage:[UIImage imageNamed:@"button_reload"] forState:UIControlStateNormal];
        _reloadButton.accessibilityLabel = NSLocalizedString(@"Reload", @"更新");
    }
}

#pragma mark - Actions

- (IBAction)back:(id)sender
{
    if (_pageWebView.canGoBack) {
        [_pageWebView goBack];
    }
}

- (IBAction)forward:(id)sender
{
    if (_pageWebView.canGoForward) {
        [_pageWebView goForward];
    }
}

- (IBAction)goToBottom:(id)sender
{
    int pageHeight = _pageWebView.scrollView.contentSize.height;
    if (pageHeight == 0) {
        return;
    }
    
    CGPoint movePoint = CGPointMake(
                                    _pageWebView.scrollView.contentOffset.x,
                                    pageHeight - _pageWebView.frame.size.height);
#ifdef DEBUG
    NSLog(@"Page scroll form %@ to %@.",
          NSStringFromCGPoint(_pageWebView.scrollView.contentOffset),
          NSStringFromCGPoint(movePoint));
#endif /* #ifdef DEBUG */
    [_pageWebView.scrollView setContentOffset:movePoint animated:YES];
}

- (IBAction)reload:(id)sender
{
    if (isPageLoading_) {
        [_pageWebView stopLoading];
    } else {
        [_pageWebView reload];
    }
}

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    [_pageWebView loadRequest:[NSURLRequest requestWithURL:_url]];
    
    _backButton.accessibilityLabel = NSLocalizedString(@"Back", @"戻る");
    _forwardButton.accessibilityLabel = NSLocalizedString(@"Forward", @"次へ");
    _gotoBottomButton.accessibilityLabel = NSLocalizedString(@"Go to bottom", @"一番下に移動");
    _gotoBottomButton.accessibilityHint = NSLocalizedString(@"Go to the bottom of this Web page",
                                                            @"このWebページの一番下に移動");
}

- (void)viewDidUnload
{
    [self setPageWebView:nil];
    [self setBackButton:nil];
    [self setForwardButton:nil];
    [self setReloadButton:nil];
    [self setTopNavigationItem:nil];
    [self setBottomView:nil];
    [self setGotoBottomButton:nil];
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

    // WebViewのデリゲートを設定する
    _pageWebView.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // WebViewのデリゲートを削除する
    _pageWebView.delegate = nil;
    
    // WebViewの読み込みを中止する
    [_pageWebView stopLoading];
    
    if (isPageLoading_) {
        // ネットワークインジケーターを消す
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
    
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        switch (interfaceOrientation) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
                return YES;
            case UIInterfaceOrientationPortraitUpsideDown:
            default:
                return NO;
        }
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

- (BOOL)shouldAutorotate
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return NO;
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
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

@end
