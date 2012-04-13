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
#import "ChannelInfo.h"
#import "LadioLib/LadioLib.h"
#import "ChannelViewController.h"

@interface ChannelViewController()
{
    NSMutableArray* channelInfoList;
}
@end
@implementation ChannelViewController

@synthesize channel;
@synthesize topNavigationItem;
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
    if (channel.nam != nil && ![channel.nam isEqual:@""]) {
        topNavigationItem.title = channel.nam;
    }
    // DJが存在する場合はDJを
    else if (channel.dj != nil && ![channel.dj isEqual:@""]) {
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
    
    // 表示情報を生成する
    channelInfoList = [[NSMutableArray alloc] init];
    if (channel != nil) {
        // タイトル
        if (channel.nam != nil && ![channel.nam isEqual:@""]) {
            NSString* t = NSLocalizedString(@"Title", @"番組タイトル");
            NSString* v = channel.nam;
            ChannelInfo* ci = [[ChannelInfo alloc] initWithTitle:t value:v];
            [channelInfoList addObject:ci];
        }
        // DJ
        if (channel.dj != nil && ![channel.dj isEqual:@""]) {
            NSString* t = NSLocalizedString(@"DJ", @"番組DJ");
            NSString* v = channel.dj;
            ChannelInfo* ci = [[ChannelInfo alloc] initWithTitle:t value:v];
            [channelInfoList addObject:ci];
        }
        // ジャンル
        if (channel.gnl != nil && ![channel.gnl isEqual:@""]) {
            NSString* t = NSLocalizedString(@"Genre", @"番組ジャンル");
            NSString* v = channel.gnl;
            ChannelInfo* ci = [[ChannelInfo alloc] initWithTitle:t value:v];
            [channelInfoList addObject:ci];
        }
        // 詳細
        if (channel.desc != nil && ![channel.desc isEqual:@""]) {
            NSString* t = NSLocalizedString(@"Description", @"番組詳細");
            NSString* v = channel.desc;
            ChannelInfo* ci = [[ChannelInfo alloc] initWithTitle:t value:v];
            [channelInfoList addObject:ci];
        }
        // 曲
        if (channel.song != nil && ![channel.song isEqual:@""]) {
            NSString* t = NSLocalizedString(@"Song", @"番組曲");
            NSString* v = channel.song;
            ChannelInfo* ci = [[ChannelInfo alloc] initWithTitle:t value:v];
            [channelInfoList addObject:ci];
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
                     v, NSLocalizedString(@"Max num", @"番組最大リスナー数"), channel.clns];
            }

            ChannelInfo* ci = [[ChannelInfo alloc] initWithTitle:t value:v];
            [channelInfoList addObject:ci];
        }
        // 開始時刻
        if (channel.tims != nil) {
            NSString* t = NSLocalizedString(@"StartTime", @"番組開始時刻");
            NSString* v = [channel getTimsToString];
            ChannelInfo* ci = [[ChannelInfo alloc] initWithTitle:t value:v];
            [channelInfoList addObject:ci];
        }
        // フォーマット
        if (channel.bit != CHANNEL_UNKNOWN_BITRATE_NUM
            || channel.chs != CHANNEL_UNKNOWN_CHANNEL_NUM
            || channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM
            || (channel.type != nil && ![channel.type isEqual:@""])) {
            NSString* t = NSLocalizedString(@"Format", @"番組フォーマット");
            NSString* v;
            // ビットレート
            if (channel.bit != CHANNEL_UNKNOWN_BITRATE_NUM) {
                v = [NSString stringWithFormat:@"%dkbps", channel.bit];
                if (channel.chs != CHANNEL_UNKNOWN_CHANNEL_NUM
                    || channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM
                    || (channel.type != nil && ![channel.type isEqual:@""])) {
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
                    || (channel.type != nil && ![channel.type isEqual:@""])) {
                    v = [NSString stringWithFormat:@"%@%@", v, @" / "];
                }
            }
            
            // サンプリングレート数
            if (channel.smpl != CHANNEL_UNKNOWN_SAMPLING_RATE_NUM) {
                v = [NSString stringWithFormat:@"%@%dHz", v, channel.smpl];
                if (channel.type != nil && ![channel.type isEqual:@""]) {
                    v = [NSString stringWithFormat:@"%@%@", v, @" / "];
                }
            }

            // 種類
            if (channel.type != nil && ![channel.type isEqual:@""]) {
                v = [NSString stringWithFormat:@"%@%@", v, channel.type];
            }

            ChannelInfo* ci = [[ChannelInfo alloc] initWithTitle:t value:v];
            [channelInfoList addObject:ci];
        }
    }
}

- (void)viewDidUnload
{
    // 再生状況変化の通知を受け取らなくする
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:nil];

    [self setTopNavigationItem:nil];
    [self setPlayButton:nil];
    [self setBottomView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [channelInfoList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"InfoCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    UILabel *titleLabel = (UILabel *) [cell viewWithTag:1];
    UILabel *valueLabel = (UILabel *) [cell viewWithTag:2];

    ChannelInfo* channelInfo = [channelInfoList objectAtIndex:indexPath.row];
    titleLabel.text = channelInfo.title;
    valueLabel.text = channelInfo.value;
    
    return cell;
}

- (IBAction)play:(id)sender
{

    NSURL *url = [channel getPlayUrl];
    Player *player = [Player getPlayer];
    if ([player isPlayUrl:url]) {
        [player stop];
    } else {
        [player play:url];
    }
}

- (void)playButtonChange:(NSNotification *)notification
{
    NSURL *url = [channel getPlayUrl];
    Player *player = [Player getPlayer];
    if ([player isPlayUrl:url]) {
        [playButton setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [playButton setTitle:@"Play" forState:UIControlStateNormal];
    }
}
@end
