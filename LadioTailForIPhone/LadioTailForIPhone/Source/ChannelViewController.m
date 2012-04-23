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
#import "Player.h"
#import "AdBannerManager.h"
#import "ChannelsHtml.h"
#import "WebPageViewController.h"
#import "ChannelViewController.h"

/// リンクをクリックするとSafariが開く
#define OPEN_SAFARI_WHEN_CLICK_LINK 0

/// 戻るボタンの色
#define BACK_BUTTON_COLOR [UIColor darkGrayColor]
/// お気に入りボタンの色
#define FAVORITE_BUTTON_COLOR [UIColor darkGrayColor]
/// 詳細表示画面の背景色
#define DESCRIPTION_BACKGROUND_COLOR "#3C3C3C"
/// 詳細表示画面のテキスト色
#define DESCRIPTION_TEXT_COLOR "#FFFFFF"
/// 詳細表示画面のリンクテキスト色
#define DESCRIPTION_LINK_TEXT_COLOR "#FFBE1E"

@implementation ChannelViewController
{
@private
    /// バナーが表示済みか
    BOOL isBannerVisible_;
}

@synthesize channel = channel_;
@synthesize topNavigationItem = topNavigationItem_;
@synthesize favoriteBarButtonItem = favoriteBarButtonItem_;
@synthesize descriptionWebView = descriptionWebView_;
@synthesize playButton = playButton_;
@synthesize bottomView = bottomView_;

- (void)dealloc
{
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
            (id) [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1].CGColor,
            (id) [UIColor colorWithRed:0 green:0 blue:0 alpha:1].CGColor,
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
            ((WebPageViewController *) viewCon).url = channel_.url;
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

#pragma mark - Player notification

- (void)playStateChanged:(NSNotification *)notification
{
    // 再生状況に合わせて再生ボタンの内容を切り替える
    [self updatePlayButton];
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
