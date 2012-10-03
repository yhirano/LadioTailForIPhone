/*
 * Copyright (c) 2012 Yuichi Hirano
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
#import <Twitter/Twitter.h>
#import "LadioTailConfig.h"
#import "Player.h"
#import "ChannelsHtml.h"
#import "WebPageViewController.h"
#import "ChannelViewController.h"

@implementation ChannelViewController
{
@private
    /// 開くURL
    NSURL *openUrl_;
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

    // お気に入りの変化通知を受け取らなくする
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LadioLibChannelChangedFavoritesNotification
                                                  object:nil];
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

    [descriptionWebView_ loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
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

- (IBAction)tweet:(id)sender {
    TWTweetComposeViewController *tweetView = [[TWTweetComposeViewController alloc] init];
    NSString *tweetText = [[NSString alloc]
                           initWithFormat:NSLocalizedString(@"TweetDefaultText", @"Twitterデフォルト投稿文"),
                           channel_.nam, [channel_.surl absoluteString]];
    [tweetView setInitialText:tweetText];
    [self presentModalViewController:tweetView animated:YES];
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

    // 番組のお気に入りの変化通知を受け取る
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(channelFavoritesChanged:)
                                                 name:LadioLibChannelChangedFavoritesNotification
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

    // WebViewのデリゲートを設定する
    descriptionWebView_.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // WebViewのデリゲートを削除する
    descriptionWebView_.delegate = nil;

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

#pragma mark - Favorites notification

- (void)channelFavoritesChanged:(NSNotification *)notification
{
    // お気に入りの変化にあわせてボタンを切り替える
    [self updateFavoriteButton];
}

#pragma mark - Player notification

- (void)playStateChanged:(NSNotification *)notification
{
    // 再生状況に合わせて再生ボタンの内容を切り替える
    [self updatePlayButton];
}

@end
