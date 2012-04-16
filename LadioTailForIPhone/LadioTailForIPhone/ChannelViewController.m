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
#import "FavoriteManager.h"
#import "LadioLib/LadioLib.h"
#import "ChannelViewController.h"

/// リンクをクリックするとSafariが開く
#define OPEN_SAFARI_WHEN_CLICK_LINK 1

/// お気に入りボタンの色
#define FAVORITE_BUTTON_COLOR [UIColor darkGrayColor]
/// 詳細表示画面の背景色
#define DESCRIPTION_BACKGROUND_COLOR "#3C3C3C"
/// 詳細表示画面のテキスト色
#define DESCRIPTION_TEXT_COLOR "#FFFFFF"
/// 詳細表示画面のリンクテキスト色
#define DESCRIPTION_LINK_TEXT_COLOR "#FFBE1E"

/// iADビューの表示アニメーションの時間
#define AD_VIEW_ANIMATION_DURATION 1.0

@implementation ChannelViewController
{
@private
    /// バナーが表示済みか
    BOOL isBannerVisible;
}

@synthesize channel;
@synthesize topNavigationItem;
@synthesize favoriteBarButtonItem;
@synthesize descriptionWebView;
@synthesize playButton;
@synthesize bottomView;
@synthesize adBannerView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        channel = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 再生状況に合わせて再生ボタンの内容を切り替える
    [self playButtonChange:nil];

    // 再生状況の変化を受け取って再生ボタンの内容を切り替える
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playButtonChange:) name:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:nil];

    // ナビゲーションタイトルを表示する
    // タイトルが存在する場合はタイトルを
    if (!([channel.nam length] == 0)) {
        topNavigationItem.title = channel.nam;
    }
            // DJが存在する場合はDJを
    else if (!([channel.dj length] == 0)) {
        topNavigationItem.title = channel.dj;
    }

    // お気に入りボタンの色を変える
    favoriteBarButtonItem.tintColor = FAVORITE_BUTTON_COLOR;

    // 下部Viewの背景色をグラデーションに
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = bottomView.bounds;
    gradient.colors = [NSArray arrayWithObjects:
            (id) [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1].CGColor,
            (id) [UIColor colorWithRed:0 green:0 blue:0 alpha:1].CGColor,
            nil];
    [bottomView.layer insertSublayer:gradient atIndex:0];

    // お気に入りボタンを更新
    [self updateFavoriteButton];

    // 表示情報を生成する
    [self writeDescription];
}

- (void)viewDidUnload
{
    // 再生状況変化の通知を受け取らなくする
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:nil];

    [self setTopNavigationItem:nil];
    [self setPlayButton:nil];
    [self setBottomView:nil];
    [self setDescriptionWebView:nil];
    [self setFavoriteBarButtonItem:nil];
    [self setAdBannerView:nil];
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // リモコン対応
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];

    // 初期状態ではバナーを表示していないのでフラグを下げる
    isBannerVisible = NO;

    // Ad BannerViewのデリゲートを設定
    // 本画面の終了時にデリゲートを削除したいために、StoryBoard上ではなく
    // コード上で定義した
    adBannerView.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Ad BannerViewのデリゲートを削除
    // 本画面が消えた後にAd BannerViewが読み込み終わった場合に反応しないようにしている
    adBannerView.delegate = nil;

    // リモコン対応
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];

    [super viewWillDisappear:animated];
}

- (BOOL)canBecomeFirstResponder
{
    // リモコン対応
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
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
            return YES;
#endif /* OPEN_SAFARI_WHEN_CLICK_LINK */
        }
    }
    return YES;
}


- (void)updateFavoriteButton
{
    UIBarButtonItem *favoriteButton = self.navigationItem.rightBarButtonItem;
    FavoriteManager *favoriteManager = [FavoriteManager sharedInstance];
    if ([favoriteManager isFavorite:channel.mnt]) {
        [favoriteButton setImage:[UIImage imageNamed:@"navbar_favorite_yellow.png"]];
    } else {
        [favoriteButton setImage:[UIImage imageNamed:@"navbar_favorite_white.png"]];
    }
}

- (void)writeDescription
{
    if (channel == nil) {
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
    if (!([channel.nam length] == 0)) {
        NSString *t = NSLocalizedString(@"Title", @"番組タイトル");
        NSString *v = channel.nam;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // DJ
    if (!([channel.dj length] == 0)) {
        NSString *t = NSLocalizedString(@"DJ", @"番組DJ");
        NSString *v = channel.dj;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // ジャンル
    if (!([channel.gnl length] == 0)) {
        NSString *t = NSLocalizedString(@"Genre", @"番組ジャンル");
        NSString *v = channel.gnl;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // 詳細
    if (!([channel.desc length] == 0)) {
        NSString *t = NSLocalizedString(@"Description", @"番組詳細");
        NSString *v = channel.desc;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // 曲
    if (!([channel.song length] == 0)) {
        NSString *t = NSLocalizedString(@"Song", @"番組曲");
        NSString *v = channel.song;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // URL
    NSString *urlStr = [channel.url absoluteString];
    if (!([urlStr length] == 0)) {
        NSString *t = NSLocalizedString(@"Site", @"番組サイト");
        NSString *v = [[NSString alloc] initWithFormat:htmlLink, urlStr, urlStr];
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // リスナー数
    if (channel.cln != CHANNEL_UNKNOWN_LISTENER_NUM || channel.clns != CHANNEL_UNKNOWN_LISTENER_NUM || channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
        // リスナー数
        NSString *t = NSLocalizedString(@"Listener num", @"番組リスナー数");
        NSString *v;
        if (channel.cln != CHANNEL_UNKNOWN_LISTENER_NUM) {
            v = [NSString
                 stringWithFormat:@"%@ %d",
                 NSLocalizedString(@"Listener num", @"番組リスナー数"), channel.cln];
            if (channel.clns != CHANNEL_UNKNOWN_LISTENER_NUM || channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
                v = [NSString stringWithFormat:@"%@%@", v, @" / "];
            }
        }

        // 述べリスナー数
        if (channel.clns != CHANNEL_UNKNOWN_LISTENER_NUM) {
            v = [NSString
                 stringWithFormat:@"%@%@ %d",
                 v, NSLocalizedString(@"Total num", @"番組述べリスナー数"), channel.clns];
            if (channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
                v = [NSString stringWithFormat:@"%@%@", v, @" / "];
            }
        }

        // 最大リスナー数
        if (channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
            v = [NSString
                 stringWithFormat:@"%@%@ %d",
                 v, NSLocalizedString(@"Max num", @"番組最大リスナー数"), channel.max];
        }

        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // 開始時刻
    if (channel.tims != nil) {
        NSString *t = NSLocalizedString(@"StartTime", @"番組開始時刻");
        NSString *v = [channel getTimsToString];
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // フォーマット
    if (channel.bit != CHANNEL_UNKNOWN_BITRATE_NUM || channel.chs != CHANNEL_UNKNOWN_CHANNEL_NUM || channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM || !([channel.type length] == 0)) {
        NSString *t = NSLocalizedString(@"Format", @"番組フォーマット");
        NSString *v;
        // ビットレート
        if (channel.bit != CHANNEL_UNKNOWN_BITRATE_NUM) {
            v = [NSString stringWithFormat:@"%dkbps", channel.bit];
            if (channel.chs != CHANNEL_UNKNOWN_CHANNEL_NUM || channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM || !([channel.type length] == 0)) {
                v = [NSString stringWithFormat:@"%@%@", v, @" / "];
            }
        }

        // チャンネル数
        if (channel.chs != CHANNEL_UNKNOWN_CHANNEL_NUM) {
            NSString *chsStr;
            switch (channel.chs) {
                case 1:
                    chsStr = NSLocalizedString(@"Mono", @"モノラル");
                    break;
                case 2:
                    chsStr = NSLocalizedString(@"Stereo", @"ステレオ");
                    break;
                default:
                    chsStr = [NSString stringWithFormat:@"%dch", channel.chs];
                    break;
            }

            v = [NSString stringWithFormat:@"%@%@", v, chsStr];
            if (channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM || !([channel.type length] == 0)) {
                v = [NSString stringWithFormat:@"%@%@", v, @" / "];
            }
        }

        // サンプリングレート数
        if (channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM) {
            v = [NSString stringWithFormat:@"%@%dHz", v, channel.smpl];
            if (!([channel.type length] == 0)) {
                v = [NSString stringWithFormat:@"%@%@", v, @" / "];
            }
        }

        // 種類
        if (!([channel.type length] == 0)) {
            v = [NSString stringWithFormat:@"%@%@", v, channel.type];
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

- (void)remoteControlReceivedWithEvent:(UIEvent*)event
{
    // リモコンからのボタンクリック
    [[Player sharedInstance] playFromRemoteControl:event];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView*)banner willLeaveApplication:(BOOL)willLeave
{
    // 広告を表示するかどうか判断するメソッド。
    // いつでも表示OKの場合はYESを返却します。
    return YES;
}

// iADバナーが読み込み終わった
- (void)bannerViewDidLoadAd:(ADBannerView*)banner
{
    // iADバナー未表示状態の場合
    if (isBannerVisible == NO) {
        NSLog(@"Show iAD banner.");


        [UIView
         animateWithDuration:AD_VIEW_ANIMATION_DURATION
         animations:^{
             // AdBannerViewの高さ分だけ左に移動
             adBannerView.frame = CGRectOffset(banner.frame, -adBannerView.frame.size.width, 0);
         }
         ];

        isBannerVisible = YES;
    }
}

// iADバナーの読み込みに失敗
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError*)error
{
    // iADバナー表示済み状態の場合
    if (isBannerVisible == YES) {
        NSLog(@"Hide iAD banner by iAD error.");

        [UIView
         animateWithDuration:AD_VIEW_ANIMATION_DURATION
         animations:^{
             // AdBannerViewの高さ分だけ右に移動
             adBannerView.frame = CGRectOffset(banner.frame, adBannerView.frame.size.width, 0);
         }
         ];

        isBannerVisible = NO;
    }
}

- (IBAction)play:(id)sender
{
    NSURL *url = [channel getPlayUrl];
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
    [favoriteManager switchFavorite:channel.mnt];

    // お気に入りボタンを更新
    [self updateFavoriteButton];
}

- (IBAction)toggleDisplayOfBanner:(id)sender
{
    if (isBannerVisible) {
        [self bannerView:adBannerView didFailToReceiveAdWithError:nil];
    } else {
        [self bannerViewDidLoadAd:adBannerView];
    }
}

- (void)playButtonChange:(NSNotification *)notification
{
    NSURL *url = [channel getPlayUrl];
    Player *player = [Player sharedInstance];
    if ([player isPlaying:url]) {
        [playButton setImage:[UIImage imageNamed:@"playback_stop.png"] forState:UIControlStateNormal];
    } else {
        [playButton setImage:[UIImage imageNamed:@"playback_play.png"] forState:UIControlStateNormal];
    }

    if ([player getState] == PlayerStatePrepare) {
        playButton.enabled = NO;
    } else {
        playButton.enabled = YES;
    }
}

@end
