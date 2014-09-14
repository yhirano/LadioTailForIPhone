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

#import <OpenInChrome/OpenInChromeController.h>
#import "WebPageViewController.h"
#import "FavoriteViewController.h"

@interface FavoriteViewController () <UIWebViewDelegate>

@end

@implementation FavoriteViewController
{
    NSURL *openUrl_;
}

- (void)dealloc
{
    openUrl_ = nil;
}

#pragma mark Private methods

- (void)writeDescription
{
    if (_favorite == nil) {
        return;
    }
    
    NSString *html = [_favorite descriptionHtml];
    
    // HTMLが取得できない場合（実装エラーと思われる）は何もしない
    if (html == nil) {
        return;
    }
    
    [_descriptionWebView loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}

#pragma mark - UIView methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // ナビゲーションタイトルを表示する
    NSString *titleString;
#if defined(LADIO_TAIL)
    // タイトルが存在する場合はタイトルを表示する
    if ([_favorite.channel.nam length] > 0) {
        titleString = _favorite.channel.nam;
    }
    // DJが存在する場合はDJを表示する
    else if ([_favorite.channel.dj length] > 0) {
        titleString = _favorite.channel.dj;
    }
    // それ以外はマウントを表示
    else {
        titleString = _favorite.channel.mnt;
    }
#elif defined(RADIO_EDGE)
    // Server Nameが存在する場合はタイトルを表示する
    if ([_favorite.channel.serverName length] > 0) {
        titleString = _favorite.channel.serverName;
    }
    // Genreが存在する場合はGenreを表示する
    else if ([_favorite.channel.genre length] > 0) {
        titleString = _favorite.channel.genre;
    } else {
        titleString = @"";
    }
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif

    _topNavigationItem.title = titleString;

    // Web画面からの戻るボタンのテキストを書き換える
    NSString *backButtonString = titleString;
    if ([backButtonString length] == 0) {
        backButtonString = NSLocalizedString(@"Back", @"戻る");
    }
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:backButtonString
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
    self.navigationItem.backBarButtonItem = backButtonItem;
    
    // WebViewのスクロールの影を消す
    for (UIView *view in [[[_descriptionWebView subviews] objectAtIndex:0] subviews]) {
        if ([view isKindOfClass:[UIImageView class]]) {
            view.hidden = YES;
        }
    }

    // 表示情報を生成する
    [self writeDescription];
}

- (void)viewDidUnload
{
    [self setDescriptionWebView:nil];
    [self setTopNavigationItem:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // WebViewのデリゲートを設定する
    _descriptionWebView.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // WebViewのデリゲートを削除する
    _descriptionWebView.delegate = nil;
    
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // リンクを押した
    if ([[segue identifier] isEqualToString:@"OpenUrl"]) {
        // URLを遷移先のViewに設定
        UIViewController *viewCon = [segue destinationViewController];
        if ([viewCon isKindOfClass:[WebPageViewController class]]) {
            ((WebPageViewController *) viewCon).url = [ReplaceUrlUtil urlForSmartphone:openUrl_];
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
        if ([scheme compare:@"http"] == NSOrderedSame || [scheme compare:@"https"] == NSOrderedSame) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *webBrowser = [defaults stringForKey:@"web_browser"];
            if ([webBrowser isEqualToString:@"web_browser_safari"]) {
                // Safariを起動する
                [[UIApplication sharedApplication] openURL:[ReplaceUrlUtil urlForSmartphone:[request URL]]];
                return NO;
            } else if ([webBrowser isEqualToString:@"web_browser_google_chrome"]) {
                OpenInChromeController *openInChromeController = [[OpenInChromeController alloc] init];
                // Chromeがインストール済み
                if ([openInChromeController isChromeInstalled]) {
                    [openInChromeController openInChrome:[ReplaceUrlUtil urlForSmartphone:[request URL]]
                                         withCallbackURL:nil
                                            createNewTab:YES];
                    return NO;
                }
                // Chromeが未インストール
                else {
                    // リンクをクリック時、Safariを起動する
                    [[UIApplication sharedApplication] openURL:[ReplaceUrlUtil urlForSmartphone:[request URL]]];
                    return NO;
                }
            } else {
                openUrl_ = [request URL];
                [self performSegueWithIdentifier:@"OpenUrl" sender:self];
                return NO;
            }
        }
    }
    return YES;
}

@end
