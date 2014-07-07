/*
 * Copyright (c) 2012-2014 Yuichi Hirano
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

#import "ViewDeck/IIViewDeckController.h"
#import "RadioLib/RadioLib.h"
#import "LadioTailConfig.h"
#import "HistoryTableViewCell.h"
#import "HistoryViewController.h"
#import "HistoryTableViewController.h"

@implementation HistoryTableViewController
{
    NSArray *history_;
}

- (void)dealloc
{
    history_ = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:RadioLibHistoryChangedNotification
                                                  object:nil];
}

#pragma mark - Private methods

/// お気に入りとhistory_の内容を同期する
- (void)updateHistoryArray
{
    // お気に入りを取得し、新しい順にならべてfavorites_に格納
    NSArray *historyGlobal = [HistoryManager sharedInstance].history;
    history_ = [historyGlobal sortedArrayUsingSelector:@selector(compareNewly:)];
}

#pragma mark - UIView methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 履歴の変化通知を受け取る
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(channelHistoryChange:)
                                                 name:RadioLibHistoryChangedNotification
                                               object:nil];

    [self updateHistoryArray];
    
    self.navigationItem.title = NSLocalizedString(@"History", @"履歴");
    
    // Accessibility
    _sideMenuBarButtonItem.accessibilityLabel = NSLocalizedString(@"Main menu", @"メインメニューボタン");
    _sideMenuBarButtonItem.accessibilityHint = NSLocalizedString(@"Open the main menu", @"メインメニューを開く");
    
    // Preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
    
    // StoryBoard上でセルの高さを設定しても有効にならないので、ここで高さを設定する
    // http://stackoverflow.com/questions/7214739/uitableview-cells-height-is-not-working-in-a-empty-table
    self.tableView.rowHeight = 54;
    // テーブルの背景の色を変える
    self.tableView.backgroundColor = HISTORY_TABLE_BACKGROUND_COLOR;
    // テーブルの境界線の色を変える
    self.tableView.separatorColor = HISTORY_TABLE_SEPARATOR_COLOR;
    
    // 番組画面からの戻るボタンのテキストを書き換える
    NSString *backButtonString = NSLocalizedString(@"History", @"履歴");
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:backButtonString
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
    self.navigationItem.backBarButtonItem = backButtonItem;
}

- (void)viewDidUnload
{
    [self setSideMenuBarButtonItem:nil];
    [super viewDidUnload];
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
    // テーブルから履歴を選択した
    if ([[segue identifier] isEqualToString:@"SelectHistory"]) {
        // 履歴情報を遷移先のViewに設定
        UIViewController *viewCon = [segue destinationViewController];
        if ([viewCon isKindOfClass:[HistoryViewController class]]) {
            NSInteger historyIndex = [self.tableView indexPathForSelectedRow].row;
            HistoryItem *history = history_[historyIndex];
            ((HistoryViewController *) viewCon).history = history;
        }
    }
}

#pragma mark - Actions

- (IBAction)openSideMenu:(id)sender {
    [self.viewDeckController toggleLeftViewAnimated:YES];
}

#pragma mark - TableViewControllerDelegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [history_ count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    HistoryItem *historyItem = (HistoryItem *)history_[indexPath.row];
    Channel *channel = historyItem.channel;
        
    NSMutableString *accessibilityLabel = [NSMutableString string];
        
    NSString *cellIdentifier = @"FavoriteCell";
        
    cell = (HistoryTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
    if (cell == nil) {
        cell = [[HistoryTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:cellIdentifier];
    }
        
    UILabel *titleLabel = (UILabel *) [cell viewWithTag:1];
    UILabel *djLabel = (UILabel *) [cell viewWithTag:2];

#if defined(LADIO_TAIL)
    if (titleLabel != nil && [channel.nam length] > 0) {
        titleLabel.text = channel.nam;
        [accessibilityLabel appendFormat:@" %@ %@", NSLocalizedString(@"Title", @"タイトル"), channel.nam];
    } else {
        titleLabel.text = @"";
    }
    if (djLabel != nil && [channel.dj length] > 0) {
        djLabel.text = channel.dj;
        [accessibilityLabel appendFormat:@" %@ %@", NSLocalizedString(@"DJ", @"DJ"), channel.dj];
    } else {
        djLabel.text = @"";
    }
#elif defined(RADIO_EDGE)
        if ([channel.serverName length] > 0) {
            titleLabel.text = channel.serverName;
            [accessibilityLabel appendFormat:@" %@ %@", NSLocalizedString(@"Title", @"タイトル"), channel.serverName];
        } else {
            titleLabel.text = @"";
        }
        if ([channel.genre length] > 0) {
            djLabel.text = channel.genre;
            [accessibilityLabel appendFormat:@" %@ %@", NSLocalizedString(@"Genre", @"ジャンル"), channel.genre];
        } else {
            djLabel.text = @"";
        }
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif

    // テーブルセルのテキスト等の色を変える
    titleLabel.textColor = HISTORY_CELL_MAIN_TEXT_COLOR;
    titleLabel.highlightedTextColor = HISTORY_CELL_MAIN_TEXT_SELECTED_COLOR;

    djLabel.textColor = HISTORY_CELL_SUB_TEXT_COLOR;
    djLabel.highlightedTextColor = HISTORY_CELL_SUB_TEXT_SELECTED_COLOR;

    cell.accessibilityLabel = accessibilityLabel;
    cell.accessibilityHint = NSLocalizedString(@"Open the description view of this channel",
                                                       @"この番組の番組詳細画面を開く");

    return cell;
}

-  (void)tableView:(UITableView *)tableView
   willDisplayCell:(UITableViewCell *)cell
 forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // テーブルセルの背景の色を変える
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = FAVORITES_TABLE_CELL_BACKGROUND_COLOR_DARK;
    } else {
        cell.backgroundColor = FAVORITES_TABLE_CELL_BACKGROUND_COLOR_LIGHT;
    }
    
    // テーブルセルの選択色を変える
    UIView *selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = FAVORITES_CELL_SELECTED_BACKGROUND_COLOR;
    cell.selectedBackgroundView = selectedBackgroundView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"SelectHistory" sender:self];
}

- (void)channelFavoritesChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

@end
