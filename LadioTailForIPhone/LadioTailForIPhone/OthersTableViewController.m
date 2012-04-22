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
#import "ChannelViewController.h"
#import "OthersTableViewController.h"

/// 再生中ボタンの色
#define PLAYING_BUTTON_COLOR [[UIColor alloc]initWithRed:(191 / 255.0) green:(126 / 255.0) blue:(0 / 255.0) alpha:1]
/// 戻るボタンの色
#define BACK_BUTTON_COLOR [UIColor darkGrayColor]
/// テーブルの背景の色
#define OTHERS_TABLE_BACKGROUND_COLOR \
    [[UIColor alloc]initWithRed:(40 / 255.0) green:(40 / 255.0) blue:(40 / 255.0) alpha:1]
/// テーブルの境界線の色
#define OTHERS_TABLE_SEPARATOR_COLOR \
    [[UIColor alloc]initWithRed:(75 / 255.0) green:(75 / 255.0) blue:(75 / 255.0) alpha:1]
/// テーブルセルの暗い側の色
#define OTHERS_TABLE_CELL_BACKGROUND_COLOR_DARK \
    [[UIColor alloc]initWithRed:(40 / 255.0) green:(40 / 255.0) blue:(40 / 255.0) alpha:1]
/// テーブルセルの明るい側の色
#define OTHERS_TABLE_CELL_BACKGROUND_COLOR_LIGHT \
    [[UIColor alloc]initWithRed:(60 / 255.0) green:(60 / 255.0) blue:(60 / 255.0) alpha:1]
/// テーブルセルの選択の色
#define OTHERS_CELL_SELECTED_BACKGROUND_COLOR \
    [[UIColor alloc]initWithRed:(255 / 255.0) green:(190 / 255.0) blue:(30 / 255.0) alpha:1]
/// テーブルセルのメインのテキストカラー
#define OTHERS_CELL_MAIN_TEXT_COLOR [UIColor whiteColor]
/// テーブルセルのメインのテキスト選択時カラー
#define OTHERS_CELL_MAIN_TEXT_SELECTED_COLOR [UIColor blackColor]

@implementation OthersTableViewController
{
    /// 再生中ボタンのインスタンスを一時的に格納しておく領域
    UIBarButtonItem *tempPlayingBarButtonItem_;
}

@synthesize playingBarButtonItem = playingBarButtonItem_;

- (void)dealloc
{
    tempPlayingBarButtonItem_ = nil;
}

- (void)updatePlayingButton
{
    // 再生状態に逢わせて再生ボタンの表示を切り替える
    if ([[Player sharedInstance] state] == PlayerStatePlay) {
        self.navigationItem.rightBarButtonItem = tempPlayingBarButtonItem_;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark UIView methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;

    // 再生中ボタンの装飾を変更する
    playingBarButtonItem_.title = NSLocalizedString(@"Playing", @"再生中ボタン");
    playingBarButtonItem_.tintColor = PLAYING_BUTTON_COLOR;
    // 再生中ボタンを保持する
    tempPlayingBarButtonItem_ = playingBarButtonItem_;

    // テーブルの背景の色を変える
    self.tableView.backgroundColor = OTHERS_TABLE_BACKGROUND_COLOR;
    // テーブルの境界線の色を変える
    self.tableView.separatorColor = OTHERS_TABLE_SEPARATOR_COLOR;

    // お気に入り・About画面からの戻るボタンのテキストと色を書き換える
    NSString *backButtonString = @"Others";
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:backButtonString
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
    backButtonItem.tintColor = BACK_BUTTON_COLOR;
    self.navigationItem.backBarButtonItem = backButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    // 再生状態が切り替わるごとに再生ボタンなどの表示を切り替える
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playStateChanged:)
                                                 name:LadioTailPlayerDidPlayNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playStateChanged:)
                                                 name:LadioTailPlayerDidStopNotification
                                               object:nil];

    // 再生状態に逢わせて再生ボタンの表示を切り替える
    [self updatePlayingButton];

    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidPlayNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidStopNotification object:nil];

    [super viewDidDisappear:animated];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setPlayingBarButtonItem:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // 再生中ボタンを選択した
    if ([[segue identifier] isEqualToString:@"PlayingChannel"]) {
        // 番組情報を遷移先のViewに設定
        UIViewController *viewCon = [segue destinationViewController];
        if ([viewCon isKindOfClass:[ChannelViewController class]]) {
            NSURL *playingUrl = [[Player sharedInstance] playingUrl];
            Headline *headline = [Headline sharedInstance];
            Channel *channel = [headline channel:playingUrl];
            ((ChannelViewController *) viewCon).channel = channel;
        }
    }
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.row == 0) {
        NSString *cellIdentifier = @"FavoritesCell";

        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }

        UILabel *favoritesLabel = (UILabel *) [cell viewWithTag:2];
        favoritesLabel.text = NSLocalizedString(@"Favorites", @"お気に入り 複数");

        // テーブルセルのテキスト等の色を変える
        favoritesLabel.textColor = OTHERS_CELL_MAIN_TEXT_COLOR;
        favoritesLabel.highlightedTextColor = OTHERS_CELL_MAIN_TEXT_SELECTED_COLOR;
    } else if (indexPath.row == 1) {
        NSString *cellIdentifier = @"AboutCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }

        UILabel *aboutLabel = (UILabel *) [cell viewWithTag:2];
        aboutLabel.text = NSLocalizedString(@"About Ladio Tail", @"Ladio Tailについて");
        
        // テーブルセルのテキスト等の色を変える
        aboutLabel.textColor = OTHERS_CELL_MAIN_TEXT_COLOR;
        aboutLabel.highlightedTextColor = OTHERS_CELL_MAIN_TEXT_SELECTED_COLOR;
    }

    return cell;
}

-  (void)tableView:(UITableView *)tableView
   willDisplayCell:(UITableViewCell *)cell
 forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // テーブルセルの背景の色を変える
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = OTHERS_TABLE_CELL_BACKGROUND_COLOR_DARK;
    } else {
        cell.backgroundColor = OTHERS_TABLE_CELL_BACKGROUND_COLOR_LIGHT;
    }
    
    // テーブルセルの選択色を変える
    UIView *selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = OTHERS_CELL_SELECTED_BACKGROUND_COLOR;
    cell.selectedBackgroundView = selectedBackgroundView;
}

#pragma mark - Player notifications

- (void)playStateChanged:(NSNotification *)notification
{
    [self updatePlayingButton];
}

@end
