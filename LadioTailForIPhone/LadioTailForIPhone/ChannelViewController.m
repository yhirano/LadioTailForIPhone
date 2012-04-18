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

#import "Player.h"
#import "AdBannerManager.h"
#import "FavoriteManager.h"
#import "LadioLib/LadioLib.h"
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

- (void)updateFavoriteButton
{
    UIBarButtonItem *favoriteButton = self.navigationItem.rightBarButtonItem;
    FavoriteManager *favoriteManager = [FavoriteManager sharedInstance];
    if ([favoriteManager isFavorite:channel_.mnt]) {
        [favoriteButton setImage:[UIImage imageNamed:@"navbar_favorite_yellow.png"]];
    } else {
        [favoriteButton setImage:[UIImage imageNamed:@"navbar_favorite_white.png"]];
    }
}

- (void)playButtonChange
{
    // 再生ボタンの画像を切り替える
    NSURL *url = [channel_ playUrl];
    Player *player = [Player sharedInstance];
    if ([player isPlaying:url]) {
        [playButton_ setImage:[UIImage imageNamed:@"playback_stop.png"] forState:UIControlStateNormal];
    } else {
        [playButton_ setImage:[UIImage imageNamed:@"playback_play.png"] forState:UIControlStateNormal];
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
    
    static NSString *htmlBase = @"<html>"
    "  <head>"
    "    <style type=\"text/css\">"
    "      body {"
    "        background-color:" DESCRIPTION_BACKGROUND_COLOR ";"
    "        color:" DESCRIPTION_TEXT_COLOR ";"
    "      }"
    "      a {"
    "        color:" DESCRIPTION_LINK_TEXT_COLOR ";"
    "      }"
    "      div.content {"
    "        margin-bottom:0.5em;"
    "      }"
    "      div.tag {"
    "        font-size:small;"
    "      }"
    "      div.value {"
    "        margin-left:0.5em;"
    "        font-weight:bold;"
    "        word-break:break-all;"
    "      }"
    "    </style>"
    "  </head>"
    "  <body>"
    "    %@"
    "  </body>"
    "</html>";
    static NSString *htmlContent = @"%@"
    "<div class=\"content\">"
    "  <div class=\"tag\">"
    "    %@"
    "  </div>"
    "  <div class=\"value\">"
    "    %@"
    "  </div>"
    "</div>";
    static NSString *htmlLink = @"<a href=\"%@\">%@</a>";
    
    NSString *html = @"";
    
    // タイトル
    if (!([channel_.nam length] == 0)) {
        NSString *t = NSLocalizedString(@"Title", @"番組タイトル");
        NSString *v = channel_.nam;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // DJ
    if (!([channel_.dj length] == 0)) {
        NSString *t = NSLocalizedString(@"DJ", @"番組DJ");
        NSString *v = channel_.dj;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // ジャンル
    if (!([channel_.gnl length] == 0)) {
        NSString *t = NSLocalizedString(@"Genre", @"番組ジャンル");
        NSString *v = channel_.gnl;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // 詳細
    if (!([channel_.desc length] == 0)) {
        NSString *t = NSLocalizedString(@"Description", @"番組詳細");
        NSString *v = channel_.desc;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // 曲
    if (!([channel_.song length] == 0)) {
        NSString *t = NSLocalizedString(@"Song", @"番組曲");
        NSString *v = channel_.song;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // URL
    NSString *urlStr = [channel_.url absoluteString];
    if (!([urlStr length] == 0)) {
        NSString *t = NSLocalizedString(@"Site", @"番組サイト");
        NSString *v = [[NSString alloc] initWithFormat:htmlLink, urlStr, urlStr];
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // リスナー数
    if (channel_.cln != CHANNEL_UNKNOWN_LISTENER_NUM
        || channel_.clns != CHANNEL_UNKNOWN_LISTENER_NUM
        || channel_.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
        // リスナー数
        NSString *t = NSLocalizedString(@"Listener num", @"番組リスナー数");
        NSString *v;
        if (channel_.cln != CHANNEL_UNKNOWN_LISTENER_NUM) {
            v = [NSString stringWithFormat:@"%@ %d",
                 NSLocalizedString(@"Listener num", @"番組リスナー数"),
                 channel_.cln];
            if (channel_.clns != CHANNEL_UNKNOWN_LISTENER_NUM || channel_.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
                v = [NSString stringWithFormat:@"%@%@", v, @" / "];
            }
        }
        
        // 述べリスナー数
        if (channel_.clns != CHANNEL_UNKNOWN_LISTENER_NUM) {
            v = [NSString stringWithFormat:@"%@%@ %d",
                 v,
                 NSLocalizedString(@"Total num", @"番組述べリスナー数"),
                 channel_.clns];
            if (channel_.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
                v = [NSString stringWithFormat:@"%@%@", v, @" / "];
            }
        }
        
        // 最大リスナー数
        if (channel_.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
            v = [NSString stringWithFormat:@"%@%@ %d",
                 v,
                 NSLocalizedString(@"Max num", @"番組最大リスナー数"),
                 channel_.max];
        }
        
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // 開始時刻
    if (channel_.tims != nil) {
        NSString *t = NSLocalizedString(@"StartTime", @"番組開始時刻");
        NSString *v = [channel_ timsToString];
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // フォーマット
    if (channel_.bit != CHANNEL_UNKNOWN_BITRATE_NUM
        || channel_.chs != CHANNEL_UNKNOWN_CHANNEL_NUM
        || channel_.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM
        || !([channel_.type length] == 0)) {
        NSString *t = NSLocalizedString(@"Format", @"番組フォーマット");
        NSString *v;
        // ビットレート
        if (channel_.bit != CHANNEL_UNKNOWN_BITRATE_NUM) {
            v = [NSString stringWithFormat:@"%dkbps", channel_.bit];
            if (channel_.chs != CHANNEL_UNKNOWN_CHANNEL_NUM
                || channel_.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM
                || !([channel_.type length] == 0)) {
                v = [NSString stringWithFormat:@"%@%@", v, @" / "];
            }
        }
        
        // チャンネル数
        if (channel_.chs != CHANNEL_UNKNOWN_CHANNEL_NUM) {
            NSString *chsStr;
            switch (channel_.chs) {
                case 1:
                    chsStr = NSLocalizedString(@"Mono", @"モノラル");
                    break;
                case 2:
                    chsStr = NSLocalizedString(@"Stereo", @"ステレオ");
                    break;
                default:
                    chsStr = [NSString stringWithFormat:@"%dch", channel_.chs];
                    break;
            }
            
            v = [NSString stringWithFormat:@"%@%@", v, chsStr];
            if (channel_.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM || !([channel_.type length] == 0)) {
                v = [NSString stringWithFormat:@"%@%@", v, @" / "];
            }
        }
        
        // サンプリングレート数
        if (channel_.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM) {
            v = [NSString stringWithFormat:@"%@%dHz", v, channel_.smpl];
            if (!([channel_.type length] == 0)) {
                v = [NSString stringWithFormat:@"%@%@", v, @" / "];
            }
        }
        
        // 種類
        if (!([channel_.type length] == 0)) {
            v = [NSString stringWithFormat:@"%@%@", v, channel_.type];
        }
        
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    
    html = [[NSString alloc] initWithFormat:htmlBase, html];
    
    // WebViewへのhtmlの書き込みは loadHTMLString:baseURL: だと遅い（ビューが表示されてからワンテンポ後に表示）ので
    // JavaScriptの document.write() で直接書き込む
    // http://d.hatena.ne.jp/PoohKid/20110920/1316523493
    html = [html stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *jsString = [NSString stringWithFormat:@"document.write(\"%@\"); document.close();", html];
    [self.descriptionWebView stringByEvaluatingJavaScriptFromString:jsString];
}

#pragma mark -
#pragma mark Actions

- (IBAction)play:(id)sender
{
    NSURL *url = [channel_ playUrl];
    Player *player = [Player sharedInstance];
    if ([player isPlaying:url]) {
        [player stop];
    } else {
        [player play:url];
    }
}

- (IBAction)favorite:(id)sender
{
    FavoriteManager *favoriteManager = [FavoriteManager sharedInstance];
    [favoriteManager switchFavorite:channel_.mnt];
    
    // お気に入りボタンを更新
    [self updateFavoriteButton];
}

#pragma mark -
#pragma mark UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 再生状況に合わせて再生ボタンの内容を切り替える
    [self playButtonChange];

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

    // ナビゲーションタイトルを表示する
    // タイトルが存在する場合はタイトルを表示する
    if (!([channel_.nam length] == 0)) {
        topNavigationItem_.title = channel_.nam;
    }
    // DJが存在する場合はDJを表示する
    else if (!([channel_.dj length] == 0)) {
        topNavigationItem_.title = channel_.dj;
    }

    // お気に入りボタンの色を変える
    favoriteBarButtonItem_.tintColor = FAVORITE_BUTTON_COLOR;

    // Web画面からの戻るボタンのテキストと色を書き換える
    NSString *backButtonStr = channel_.nam;
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:backButtonStr
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

    // お気に入りボタンを更新
    [self updateFavoriteButton];

    // 表示情報を生成する
    [self writeDescription];
}

- (void)viewDidUnload
{
    // 再生状況変化の通知を受け取らなくする
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerPrepareNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidPlayNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidStopNotification object:nil];

    [self setTopNavigationItem:nil];
    [self setPlayButton:nil];
    [self setBottomView:nil];
    [self setDescriptionWebView:nil];
    [self setFavoriteBarButtonItem:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // リモコン対応
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];

    // WebViewのデリゲートを設定する
    descriptionWebView_.delegate = self;

    // 広告を表示する
    AdBannerManager *adBannerManager = [AdBannerManager sharedInstance];
    [adBannerManager setShowPosition:CGPointMake(0, 316) hiddenPosition:CGPointMake(320, 316)];
    adBannerManager.bannerSibling = self.view;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // WebViewのデリゲートを削除する
    descriptionWebView_.delegate = nil;

    // リモコン対応
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];

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
        // URLを繊維先のViewに設定
        UIViewController *viewCon = [segue destinationViewController];
        if ([viewCon isKindOfClass:[WebPageViewController class]]) {
            ((WebPageViewController *) viewCon).url = channel_.url;
        }
    }
}

#pragma mark -
#pragma mark UIResponder methods

- (BOOL)canBecomeFirstResponder
{
    // リモコン対応
    return YES;
}


- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    // リモコンからのボタンクリック
    [[Player sharedInstance] playFromRemoteControl:event];
}

#pragma mark -
#pragma mark UIWebViewDelegate methods

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

#pragma mark -
#pragma mark Player notification

- (void)playStateChanged:(NSNotification *)notification
{
    // 再生状況に合わせて再生ボタンの内容を切り替える
    [self playButtonChange];
}

#pragma mark -

@end
