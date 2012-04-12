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

#import "LadioLib/LadioLib.h"
#import "FetchHeadline.h"
#import "ChannelViewController.h"
#import "HeadlineViewController.h"

@interface HeadlineViewController ()
- (void)fetchHeadlineStarted:(NSNotification *)notification;

- (void)fetchHeadlineSuceed:(NSNotification *)notification;

- (void)fetchHeadlineFailed:(NSNotification *)notification;

- (int)getSortType;
@end

@implementation HeadlineViewController
{
    NSArray *channels;
}
@synthesize updateBarButtonItem;
@synthesize headlineTableView;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // ヘッドラインの取得開始と終了をハンドリングし、ヘッドライン更新ボタンの有効無効の切り替えや
    // テーブル更新を行う
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchHeadlineStarted:) name:NOTIFICATION_NAME_FETCH_HEADLINE_STARTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchHeadlineSuceed:) name:NOTIFICATION_NAME_FETCH_HEADLINE_SUCEED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchHeadlineFailed:) name:NOTIFICATION_NAME_FETCH_HEADLINE_FAILED object:nil];
}

- (void)viewDidUnload
{
    [self setHeadlineTableView:nil];
    [self setUpdateBarButtonItem:nil];
    [super viewDidUnload];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NAME_FETCH_HEADLINE_STARTED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NAME_FETCH_HEADLINE_SUCEED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NAME_FETCH_HEADLINE_FAILED object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    // タブの切り替えごとにヘッドラインテーブルを更新する
    // 別タブで更新したヘッドラインをこのタブのテーブルでも使うため
    [self updateHeadlineTable];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (channels != nil) {
        return [channels count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ChannelCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    Channel *channel = (Channel *) [channels objectAtIndex:indexPath.row];

    UILabel *titleLabel = (UILabel *) [cell viewWithTag:1];
    UILabel *djLabel = (UILabel *) [cell viewWithTag:2];
    UILabel *listenersLabel = (UILabel *) [cell viewWithTag:3];
    UILabel *dateLabel = (UILabel *) [cell viewWithTag:4];

    if (channel != nil) {
        titleLabel.text = channel.nam;
        djLabel.text = channel.dj;
        if (channel.cln == CHANNEL_UNKNOWN_LISTENER_NUM) {
            listenersLabel.text = @"";
        } else if (channel.cln == 1) {
            listenersLabel.text = [[NSString alloc] initWithFormat:@"%d listener", channel.cln];
        } else {
            listenersLabel.text = [[NSString alloc] initWithFormat:@"%d listeners", channel.cln];
        }
        dateLabel.text = [channel getTimsToString];
    }

    return cell;
}

// StoryBoard上でセルの高さを設定しても有効にならないので、ここで高さを設定する
// http://blog.suz-lab.com/2010/03/uitableviewcell.html
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54.0;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // 番組情報を繊維先のViewに設定
    if ([[segue identifier] isEqualToString:@"ChannelView"]) {
        UIViewController *viewCon = [segue destinationViewController];
        if ([viewCon isKindOfClass:[ChannelViewController class]]) {
            Channel *channel = [channels objectAtIndex:[headlineTableView indexPathForSelectedRow].row];
            ((ChannelViewController *) viewCon).channel = channel;
        }
    }
}

- (void)fetchHeadlineStarted:(NSNotification *)notification
{
    updateBarButtonItem.enabled = NO;
}

- (void)fetchHeadlineSuceed:(NSNotification *)notification
{
    updateBarButtonItem.enabled = YES;
    [self updateHeadlineTable];
}

- (void)fetchHeadlineFailed:(NSNotification *)notification
{
    updateBarButtonItem.enabled = YES;
    [self updateHeadlineTable];
}

- (int)getSortType
{
    return CHANNEL_SORT_TYPE_NONE;
}

- (void)updateHeadlineTable
{
    Headline *headline = [HeadlineManager getHeadline];
    channels = [headline getChannels:self.getSortType];
    [self.headlineTableView reloadData];
}

- (IBAction)update:(id)sender
{
    [FetchHeadline fetchHeadline];
}
@end
