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

/// 詳細表示画面の背景色
#define DESCRIPTION_BACKGROUND_COLOR "#3C3C3C"
/// 詳細表示画面のテキスト色
#define DESCRIPTION_TEXT_COLOR "#FFFFFF"
/// 詳細表示画面のリンクテキスト色
#define DESCRIPTION_LINK_TEXT_COLOR "#FFBE1E"

@implementation ChannelViewController

@synthesize channel;
@synthesize topNavigationItem;
@synthesize descriptionWebView;
@synthesize playButton;
@synthesize bottomView;

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

    // 下部Viewの背景色をグラデーションに
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = bottomView.bounds;
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1].CGColor,
                       (id)[UIColor colorWithRed:0 green:0 blue:0 alpha:1].CGColor,
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
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// リンクをクリック時、Safariを起動する為の処理
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeOther)
    {
        NSString* scheme = [[request URL] scheme];
        if([scheme compare:@"about"] == NSOrderedSame) {
            return YES;
        }
        if([scheme compare:@"http"] == NSOrderedSame) {
            [[UIApplication sharedApplication] openURL: [request URL]];
            return NO;
        }
    }
    return YES;
}

- (void)updateFavoriteButton
{
    UIBarButtonItem *favoriteButton = self.navigationItem.rightBarButtonItem;
    FavoriteManager *favoriteManager = [FavoriteManager getFavoriteManager];
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
        NSString* t = NSLocalizedString(@"Title", @"番組タイトル");
        NSString* v = channel.nam;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // DJ
    if (!([channel.dj length] == 0)) {
        NSString* t = NSLocalizedString(@"DJ", @"番組DJ");
        NSString* v = channel.dj;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // ジャンル
    if (!([channel.gnl length] == 0)) {
        NSString* t = NSLocalizedString(@"Genre", @"番組ジャンル");
        NSString* v = channel.gnl;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // 詳細
    if (!([channel.desc length] == 0)) {
        NSString* t = NSLocalizedString(@"Description", @"番組詳細");
        NSString* v = channel.desc;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // 曲
    if (!([channel.song length] == 0)) {
        NSString* t = NSLocalizedString(@"Song", @"番組曲");
        NSString* v = channel.song;
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // URL
    NSString *urlStr = [channel.url absoluteString];
    if (!([urlStr length] == 0)) {
        NSString* t = NSLocalizedString(@"Site", @"番組サイト");
        NSString* v = [[NSString alloc] initWithFormat:htmlLink, urlStr, urlStr];
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // リスナー数
    if (channel.cln != CHANNEL_UNKNOWN_LISTENER_NUM
        || channel.clns != CHANNEL_UNKNOWN_LISTENER_NUM
        || channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
        // リスナー数
        NSString* t = NSLocalizedString(@"Listener num", @"番組リスナー数");
        NSString* v;
        if (channel.cln != CHANNEL_UNKNOWN_LISTENER_NUM) {
            v = [NSString
                 stringWithFormat:@"%@ %d",
                 NSLocalizedString(@"Listener num", @"番組リスナー数"), channel.cln];
            if (channel.clns != CHANNEL_UNKNOWN_LISTENER_NUM
                || channel.max != CHANNEL_UNKNOWN_LISTENER_NUM) {
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
        NSString* t = NSLocalizedString(@"StartTime", @"番組開始時刻");
        NSString* v = [channel getTimsToString];
        html = [[NSString alloc] initWithFormat:htmlContent, html, t, v];
    }
    // フォーマット
    if (channel.bit != CHANNEL_UNKNOWN_BITRATE_NUM
        || channel.chs != CHANNEL_UNKNOWN_CHANNEL_NUM
        || channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM
        || !([channel.type length] == 0)) {
        NSString* t = NSLocalizedString(@"Format", @"番組フォーマット");
        NSString* v;
        // ビットレート
        if (channel.bit != CHANNEL_UNKNOWN_BITRATE_NUM) {
            v = [NSString stringWithFormat:@"%dkbps", channel.bit];
            if (channel.chs != CHANNEL_UNKNOWN_CHANNEL_NUM
                || channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM
                || !([channel.type length] == 0)) {
                v = [NSString stringWithFormat:@"%@%@", v, @" / "];
            }
        }
        
        // チャンネル数
        if (channel.chs != CHANNEL_UNKNOWN_CHANNEL_NUM) {
            NSString* chsStr;
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
            if (channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM
                || !([channel.type length] == 0)) {
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
    [self.descriptionWebView loadHTMLString:html baseURL:nil];
}

- (IBAction)play:(id)sender
{

    NSURL *url = [channel getPlayUrl];
    Player *player = [Player getPlayer];
    if ([player isPlaying:url]) {
        [player stop];
    } else {
        [player play:url];
    }
}

- (IBAction)favorite:(id)sender {
    FavoriteManager *favoriteManager = [FavoriteManager getFavoriteManager];
    [favoriteManager switchFavorite:channel.mnt];
    
    // お気に入りボタンを更新
    [self updateFavoriteButton];
}

- (void)playButtonChange:(NSNotification *)notification
{
    NSURL *url = [channel getPlayUrl];
    Player *player = [Player getPlayer];
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
