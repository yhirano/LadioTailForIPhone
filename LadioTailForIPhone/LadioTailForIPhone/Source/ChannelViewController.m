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
#import "GoogleAdMobAds/GADBannerView.h"
#import "OpenInChrome/OpenInChromeController.h"
#import "LadioTailConfig.h"
#import "RadioLib/ReplaceUrlUtil.h"
#import "Player.h"
#import "LINEActivity.h"
#import "WebPageViewController.h"
#import "ChannelViewController.h"

@interface ChannelViewController () <UIWebViewDelegate, GADBannerViewDelegate>

@end

@implementation ChannelViewController
{
    /// 広告の背景
    __weak UIView *adBackgroundView_;
    
    /// AdMob View
    __weak GADBannerView *adMobView_;

    /// 開くURL
    NSURL *openUrl_;
}

- (void)dealloc
{
    openUrl_ = nil;
    
    adMobView_.rootViewController = nil;
    adMobView_.delegate = nil;
    [adMobView_ removeFromSuperview];
    adMobView_ = nil;

    // 再生状況変化の通知を受け取らなくする
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerPrepareNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidPlayNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidStopNotification object:nil];

    // お気に入りの変化通知を受け取らなくする
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:RadioLibChannelChangedFavoritesNotification
                                                  object:nil];
}

#pragma mark - Private methods

- (void)updateFavoriteButton
{
    UIBarButtonItem *favoriteButton = self.navigationItem.rightBarButtonItem;
    if ([_channel favorite]) {
        [favoriteButton setImage:[UIImage imageNamed:@"navbarbtn_favorite_yellow"]];
        favoriteButton.accessibilityLabel = NSLocalizedString(@"Remove Favorite", @"お気に入り削除");
        favoriteButton.accessibilityHint = NSLocalizedString(@"Remove from favorite this channel", @"この番組をお気に入りから削除");
    } else {
        [favoriteButton setImage:[UIImage imageNamed:@"navbarbtn_favorite_white"]];
        favoriteButton.accessibilityLabel = NSLocalizedString(@"Add Favorite", @"お気に入り追加");
        favoriteButton.accessibilityHint = NSLocalizedString(@"Add to favorite this channel", @"この番組をお気に入りに追加");
    }
}

- (void)updatePlayButton
{
    // 再生ボタンの画像を切り替える
#if defined(LADIO_TAIL)
    NSURL *url = [_channel playUrl];
#elif defined(RADIO_EDGE)
    NSURL *url = [_channel listenUrl];
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif

    Player *player = [Player sharedInstance];
    // 再生中
    if ([player isPlaying:url]) {
        [_playButton setImage:[UIImage imageNamed:@"button_playback_stop"] forState:UIControlStateNormal];
        _playButton.accessibilityLabel = NSLocalizedString(@"Stop", @"停止");
        _playButton.accessibilityHint = NSLocalizedString(@"Stop this channel", @"この番組を停止");

        // 再生ボタンの有効無効を切り替える
        if ([player state] == PlayerStatePrepare) {
            _playButton.enabled = NO;
        } else {
            _playButton.enabled = YES;
        }
    }
    // 再生中以外
    else {
        [_playButton setImage:[UIImage imageNamed:@"button_playback_play"] forState:UIControlStateNormal];
        _playButton.accessibilityLabel = NSLocalizedString(@"Play", @"再生");
        _playButton.accessibilityHint = NSLocalizedString(@"Play this channel", @"この番組を再生");

        // 再生ボタンの有効無効を切り替える
        if ([player state] == PlayerStatePrepare || [_channel isPlaySupported] == NO) {
            _playButton.enabled = NO;
        } else {
            _playButton.enabled = YES;
        }
    }
}

- (void)writeDescription
{
    if (_channel == nil) {
        return;
    }

    NSString *html = [_channel descriptionHtml];

    // HTMLが取得できない場合（実装エラーと思われる）は何もしない
    if (html == nil) {
        return;
    }

    [_descriptionWebView loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}

/** シェアするテキストの内容を取得する
 
 @return シェアするテキストの内容
 */
- (NSString *)shareText
{
    NSString *result;

#if defined(LADIO_TAIL)
    if ([_channel.nam length] > 0) {
        result = [[NSString alloc]
                  initWithFormat:NSLocalizedString(@"TweetDefaultTextForLadioTail", @"Twitterデフォルト投稿文"),
                  _channel.nam, [_channel.surl absoluteString]];
    } else {
        result = [[NSString alloc]
                  initWithFormat:NSLocalizedString(@"TweetNoTitleDefaultTextForLadioTail",
                                                   @"Twitterデフォルト投稿文（タイトルが無い場合）"),
                  [_channel.surl absoluteString]];
    }
#elif defined(RADIO_EDGE)
    if ([_channel.serverName length] > 0) {
        result = [[NSString alloc]
                  initWithFormat:NSLocalizedString(@"TweetDefaultTextForRadioEdge", @"Twitterデフォルト投稿文"),
                  _channel.serverName, [_channel.listenUrl absoluteString]];
    } else {
        result = [[NSString alloc]
                  initWithFormat:NSLocalizedString(@"TweetNoTitleDefaultTextForRadioEdge",
                                                   @"Twitterデフォルト投稿文（タイトルが無い場合）"),
                  [_channel.listenUrl absoluteString]];
    }
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif

    return result;
}

#pragma mark - Actions

- (IBAction)play:(id)sender
{
#if defined(LADIO_TAIL)
    NSURL *url = [_channel playUrl];
#elif defined(RADIO_EDGE)
    NSURL *url = [_channel listenUrl];
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif

    Player *player = [Player sharedInstance];
    if ([player isPlaying:url]) {
        [player stop];
    } else {
        [player playChannel:_channel];
    }
}

- (IBAction)favorite:(id)sender
{
    [self.channel switchFavorite];
    
    // お気に入りボタンを更新
    [self updateFavoriteButton];
}

- (IBAction)shareChannel:(id)sender {
    NSArray *activityItems = @[[self shareText]];
    NSArray *applicationActivities = @[[[LINEActivity alloc] init]];

    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]
                                                        initWithActivityItems:activityItems
                                                        applicationActivities:applicationActivities];
    activityViewController.excludedActivityTypes = @[UIActivityTypeMail, UIActivityTypeMessage,
                                                     UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact,
                                                     UIActivityTypePrint, UIActivityTypeSaveToCameraRoll];
    [self presentViewController:activityViewController animated:YES completion:nil];
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
                                                 name:RadioLibChannelChangedFavoritesNotification
                                               object:nil];

    // ナビゲーションタイトルを表示する
    NSString *titleString;
#if defined(LADIO_TAIL)
    // タイトルが存在する場合はタイトルを表示する
    if ([_channel.nam length] > 0) {
        titleString = _channel.nam;
    }
    // DJが存在する場合はDJを表示する
    else if ([_channel.dj length] > 0) {
        titleString = _channel.dj;
    } else {
        titleString = @"";
    }
#elif defined(RADIO_EDGE)
    // Server Nameが存在する場合はServer Nameを表示する
    if ([_channel.serverName length] > 0) {
        titleString = _channel.serverName;
    }
    // Genreが存在する場合はGenreを表示する
    else if ([_channel.genre length] > 0) {
        titleString = _channel.genre;
    } else {
        titleString = @"";
    }
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif

    // 広告を表示
    if ([LadioTailConfig admobUnitId] != nil) {
        // 広告のサイズを決める
        GADAdSize adMobViewSize;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            adMobViewSize = kGADAdSizeLeaderboard;
        } else {
            adMobViewSize = kGADAdSizeBanner;
        }
        
        // WebView部分を縮める
        CGRect descriptionWebViewFrame = _descriptionWebView.frame;
        descriptionWebViewFrame.size.height -= adMobViewSize.size.height;
        _descriptionWebView.frame = descriptionWebViewFrame;
        
        // 広告の下敷きとなるViewを生成する
        CGRect adBackgroundViewFrame = CGRectMake(0,
                                                  CGRectGetMaxY(_descriptionWebView.frame),
                                                  self.view.frame.size.width,
                                                  adMobViewSize.size.height);
        UIView *adBackgroundView = [[UIView alloc] initWithFrame:adBackgroundViewFrame];
        adBackgroundView_ = adBackgroundView;
        adBackgroundView_.backgroundColor = AD_VIRE_BACKGROUND_COLOR;
        adBackgroundView_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:adBackgroundView_];

        // 広告Viewを生成する
        GADBannerView *adMobView = [[GADBannerView alloc] initWithAdSize:adMobViewSize];
        adMobView_ = adMobView;
        CGRect adMobViewFrame = adMobView_.frame;
        adMobViewFrame.origin.x = (adBackgroundView_.frame.size.width - adMobView_.frame.size.width) / 2;
        adMobView_.frame = adMobViewFrame;
        adMobView_.adUnitID = [LadioTailConfig admobUnitId];
        adMobView_.delegate = self;
        adMobView_.rootViewController = self;
        [adBackgroundView addSubview:adMobView_];
    }
    
    _topNavigationItem.title = titleString;

    // お気に入りボタンの色を変える
    _favoriteBarButtonItem.tintColor = FAVORITE_BUTTON_COLOR;

    // iOS6未満の場合はシェアボタンをのアイコンをTwitterにする
    if (!NSClassFromString(@"UIActivityViewController")) {
        [_shareButton setImage:[UIImage imageNamed:@"button_twitter"] forState:UIControlStateNormal];
        _shareButton.accessibilityLabel = NSLocalizedString(@"Twitter", @"Twitter");
    } else {
        _shareButton.accessibilityLabel = NSLocalizedString(@"Share", @"共有");
    }

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
    [self setTopNavigationItem:nil];
    [self setPlayButton:nil];
    [self setBottomView:nil];
    [self setDescriptionWebView:nil];
    [self setFavoriteBarButtonItem:nil];
    [self setShareButton:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // 再生状況に合わせて再生ボタンの内容を切り替える
    [self updatePlayButton];

    // お気に入りボタンを更新
    [self updateFavoriteButton];

    // 広告背景の位置と大きさを調整
    CGRect frame = adBackgroundView_.frame;
    frame.origin.x = 0;
    frame.size.width = self.view.frame.size.width;
    adBackgroundView_.frame = frame;

    // 広告の位置を調整
    CGRect adMobViewFrame = adMobView_.frame;
    adMobViewFrame.origin.x = (adBackgroundView_.frame.size.width - adMobView_.frame.size.width) / 2;
    adMobView_.frame = adMobViewFrame;

    // 広告のロード
    [adMobView_ loadRequest:[GADRequest request]];
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

#pragma mark - GADBannerViewDelegate method

- (void)adViewDidReceiveAd:(GADBannerView *)view
{
#if DEBUG
    NSLog(@"adMobView succeed loading.");
#endif // #if DEBUG
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
#if DEBUG
    NSLog(@"adMobView failed loading. error:%@", [error localizedDescription]);
#endif // #if DEBUG
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
