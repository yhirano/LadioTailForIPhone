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
#import "LadioTailConfig.h"
#import "Player.h"
#import "AdBannerManager.h"
#import "ChannelsHtml.h"
#import "WebPageViewController.h"
#import "ChannelViewController.h"

/// 広告を表示後に隠すか。デバッグ用。
#define AD_HIDE_DEBUG 0

@implementation ChannelViewController
{
@private
    /// 開くURL
    NSURL *openUrl_;

    /// 広告が表示されているか
    BOOL isVisibleAdBanner_;
}

@synthesize channel = channel_;
@synthesize topNavigationItem = topNavigationItem_;
@synthesize favoriteBarButtonItem = favoriteBarButtonItem_;
@synthesize descriptionWebView = descriptionWebView_;
@synthesize playButton = playButton_;
@synthesize bottomView = bottomView_;

- (void)dealloc
{
    openUrl_ = nil;

    // 再生状況変化の通知を受け取らなくする
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerPrepareNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidPlayNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidStopNotification object:nil];
}

#pragma mark - Private methods

- (void)updateFavoriteButton
{
    UIBarButtonItem *favoriteButton = self.navigationItem.rightBarButtonItem;
    if ([channel_ favorite]) {
        [favoriteButton setImage:[UIImage imageNamed:@"navbarbtn_favorite_yellow.png"]];
    } else {
        [favoriteButton setImage:[UIImage imageNamed:@"navbarbtn_favorite_white.png"]];
    }
}

- (void)updatePlayButton
{
    // 再生ボタンの画像を切り替える
    NSURL *url = [channel_ playUrl];
    Player *player = [Player sharedInstance];
    if ([player isPlaying:url]) {
        [playButton_ setImage:[UIImage imageNamed:@"button_playback_stop.png"] forState:UIControlStateNormal];
    } else {
        [playButton_ setImage:[UIImage imageNamed:@"button_playback_play.png"] forState:UIControlStateNormal];
    }
    
    // 再生ボタンの有効無効を切り替える
    if ([player state] == PlayerStatePrepare) {
        playButton_.enabled = NO;
    } else {
        playButton_.enabled = YES;
    }
}

- (void)writeDescription
{
    if (channel_ == nil) {
        return;
    }

    NSString *html = [ChannelsHtml channelViewHtml:channel_];

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

#if AD_HIDE_DEBUG
// 広告を隠す。デバッグ用。
- (void)hideAdBanner:(NSTimer *)timer
{
    [self bannerView:nil didFailToReceiveAdWithError:nil];
}
#endif /* #if AD_HIDE_DEBUG */

#pragma mark - Actions

- (IBAction)play:(id)sender
{
    NSURL *url = [channel_ playUrl];
    Player *player = [Player sharedInstance];
    if ([player isPlaying:url]) {
        [player stop];
    } else {
        [player playChannel:channel_];
    }
}

- (IBAction)favorite:(id)sender
{
    [self.channel switchFavorite];
    
    // お気に入りボタンを更新
    [self updateFavoriteButton];
}

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 再生状況の変化を受け取って再生ボタンの内容を切り替える
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playStateChanged:)
                                                 name:LadioTailPlayerPrepareNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playStateChanged:)
                                                 name:LadioTailPlayerDidPlayNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playStateChanged:)
                                                 name:LadioTailPlayerDidStopNotification
                                               object:nil];

    NSString *titleString;
    // ナビゲーションタイトルを表示する
    // タイトルが存在する場合はタイトルを表示する
    if (!([channel_.nam length] == 0)) {
        titleString = channel_.nam;
    }
    // DJが存在する場合はDJを表示する
    else if (!([channel_.dj length] == 0)) {
        titleString = channel_.dj;
    }
    topNavigationItem_.title = titleString;

    // お気に入りボタンの色を変える
    favoriteBarButtonItem_.tintColor = FAVORITE_BUTTON_COLOR;

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
    gradient.colors =
        [NSArray arrayWithObjects:
            (id) BOTTOM_BAR_TOP_COLOR.CGColor,
            (id) BOTTOM_BAR_BOTTOM_COLOR.CGColor,
            nil];
    [bottomView_.layer insertSublayer:gradient atIndex:0];

    // 表示情報を生成する
    [self writeDescription];
}

- (void)viewDidUnload
{
    [self setTopNavigationItem:nil];
    [self setPlayButton:nil];
    [self setBottomView:nil];
    [self setDescriptionWebView:nil];
    [self setFavoriteBarButtonItem:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // 再生状況に合わせて再生ボタンの内容を切り替える
    [self updatePlayButton];
    
    // お気に入りボタンを更新
    [self updateFavoriteButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (CHANNEL_VIEW_AD_ENABLE) {
        // WebViewの初期位置を設定
        // 広告のアニメーション前に初期位置を設定する必要有り
        descriptionWebView_.frame = CGRectMake(0, 0, 320, 366);
        
        // 広告を表示する
        ADBannerView *adBannerView = [AdBannerManager sharedInstance].adBannerView;
        [adBannerView setFrame:CGRectMake(0, 366, 320, 50)];
        if (adBannerView.bannerLoaded) {
            [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION 
                                  delay:0
                                options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 adBannerView.frame = CGRectMake(0, 316, 320, 50);
                             }
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     descriptionWebView_.frame = CGRectMake(0, 0, 320, 316);
                                 }
                             }];
            isVisibleAdBanner_ = YES;
#if AD_HIDE_DEBUG
            [NSTimer scheduledTimerWithTimeInterval:4.0
                                             target:self
                                           selector:@selector(hideAdBanner:)
                                           userInfo:nil
                                            repeats:NO];
#endif /* #if AD_HIDE_DEBUG */
        }
        adBannerView.delegate = self;
        [self.view insertSubview:adBannerView belowSubview:bottomView_];
    }

    // WebViewのデリゲートを設定する
    descriptionWebView_.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (CHANNEL_VIEW_AD_ENABLE) {
        // WebViewの初期位置を設定
        // Viewを消す前に大きさを元に戻しておくことで、ちらつくのを防ぐ
        descriptionWebView_.frame = CGRectMake(0, 0, 320, 366);
        
        // 広告の表示を消す
        ADBannerView *adBannerView = [AdBannerManager sharedInstance].adBannerView;
        adBannerView.delegate = nil;
    }

    // WebViewのデリゲートを削除する
    descriptionWebView_.delegate = nil;

    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (CHANNEL_VIEW_AD_ENABLE) {
    // 広告Viewを削除
        ADBannerView *adBannerView = [AdBannerManager sharedInstance].adBannerView;
        [adBannerView removeFromSuperview];
    }

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
            ((WebPageViewController *) viewCon).url = [ChannelsHtml urlForSmartphone:openUrl_];
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
            if (OPEN_SAFARI_WHEN_CLICK_LINK) {
                // リンクをクリック時、Safariを起動する
                [[UIApplication sharedApplication] openURL:[ChannelsHtml urlForSmartphone:[request URL]]];
                return NO;
            } else {
                openUrl_ = [request URL];
                [self performSegueWithIdentifier:@"OpenUrl" sender:self];
                return NO;
            }
        }
    }
    return YES;
}

#pragma mark - Player notification

- (void)playStateChanged:(NSNotification *)notification
{
    // 再生状況に合わせて再生ボタンの内容を切り替える
    [self updatePlayButton];
}

#pragma mark - ADBannerViewDelegate methods

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    if (CHANNEL_VIEW_AD_ENABLE) {
        // 広告をはいつでも表示可能
        return YES;
    } else {
        return NO;
    }
}

// iADバナーが読み込み終わった
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"iAD banner load complated.");

    if (isVisibleAdBanner_ == NO) {
        ADBannerView *adBannerView = [AdBannerManager sharedInstance].adBannerView;
        adBannerView.hidden = NO;
        [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut 
                         animations:^{
                             adBannerView.frame = CGRectMake(0, 316, 320, 50);
                         }
                         completion:^(BOOL finished) {
                             if (finished) {
                                 descriptionWebView_.frame = CGRectMake(0, 0, 320, 316);
                             }
                         }];
        isVisibleAdBanner_ = YES;
    }
}

// iADバナーの読み込みに失敗
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"Received iAD banner error. Error : %@", [error localizedDescription]);

    if (isVisibleAdBanner_) {
        ADBannerView *adBannerView = [AdBannerManager sharedInstance].adBannerView;
        descriptionWebView_.frame = CGRectMake(0, 0, 320, 366);
        [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut 
                         animations:^{
                             adBannerView.frame = CGRectMake(0, 366, 320, 50);
                         }
                         completion:nil];
        isVisibleAdBanner_ = NO;
    }
}

@end
