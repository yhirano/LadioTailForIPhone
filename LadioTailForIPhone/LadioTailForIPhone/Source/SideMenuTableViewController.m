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

#import "ViewDeck/IIViewDeckController.h"
#import "LadioTailConfig.h"
#import "HeadlineNaviViewController.h"
#import "HeadlineViewController.h"
#import "SideMenuTableViewController.h"

@implementation SideMenuTableViewController

#pragma mark - Private methods

/// CellIdentifireから該当のセルを取得する
+ (UITableViewCell *)tableView:(UITableView *)tableView withCellWithIdentifier:(NSString *)cellIdentifier
{
    UITableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }
    return cell;
}

/// IIViewDeckControllerのセンタービューのHeadlineViewControllerを取得する
+ (HeadlineViewController *)headlineViewControllerFromViewDeckCenter:(IIViewDeckController *)controller
{
    if ([controller.centerController isKindOfClass:[HeadlineNaviViewController class]]) {
        HeadlineNaviViewController *headlineNaviViewController =
        (HeadlineNaviViewController*)controller.centerController;
        if ([headlineNaviViewController.topViewController isKindOfClass:[HeadlineViewController class]]){
            return (HeadlineViewController *)headlineNaviViewController.topViewController;
        }
    }
    return nil;
}

#pragma mark - UIView methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;

    // テーブルの背景の色を変える
    self.tableView.backgroundColor = SIDEMENU_TABLE_BACKGROUND_COLOR;
    // テーブルの境界線の色を変える
    self.tableView.separatorColor = SIDEMENU_TABLE_SEPARATOR_COLOR;

    // お気に入り・About画面からの戻るボタンのテキストと色を書き換える
    NSString *backButtonString = @"Others";
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:backButtonString
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
    backButtonItem.tintColor = BACK_BUTTON_COLOR;
    self.navigationItem.backBarButtonItem = backButtonItem;
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: // Update Section
            return 1;
        case 1: // Sort Section
            return 4;
        case 2: // Others Section
            return 2;
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: // Update Section
            return @"Update";
        case 1: // Sort Section
            return @"Sort";
        case 2: // Others Section
            return @"Others";
        default:
            return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;

    ChannelSortType channelSortType = ChannelSortTypeNone;
    HeadlineViewController* headlineViewController =
        [SideMenuTableViewController headlineViewControllerFromViewDeckCenter:self.viewDeckController];
    if (headlineViewController) {
        channelSortType = headlineViewController.channelSortType;
    }
    
    switch (indexPath.section) {
        case 0: // Update Section
            switch (indexPath.row) {
                case 0: // Update
                {
                    cell = [SideMenuTableViewController tableView:tableView
                                                            withCellWithIdentifier:@"UpdateCell"];
                    
                    UILabel *updateLabel = (UILabel *) [cell viewWithTag:2];
                    updateLabel.text = NSLocalizedString(@"Update", @"更新");
                    
                    // テーブルセルのテキスト等の色を変える
                    updateLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    updateLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;
                    break;
                }
                default:
                    break;
            }
            break;
        case 1: // Sort Section
            switch (indexPath.row) {
                case 0: // Newly
                {
                    cell = [SideMenuTableViewController tableView:tableView
                                                            withCellWithIdentifier:@"NewlyCell"];
                    
                    UILabel *newlyLabel = (UILabel *) [cell viewWithTag:2];
                    newlyLabel.text = NSLocalizedString(@"Newly", @"新規");
                    
                    // テーブルセルのテキスト等の色を変える
                    newlyLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    newlyLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;

                    // チェックマークの表示
                    UIImageView *checkImage = (UIImageView *) [cell viewWithTag:3];
                    checkImage.hidden = (channelSortType != ChannelSortTypeNewly);
                    break;
                }
                case 1: // Listeners
                {
                    cell = [SideMenuTableViewController tableView:tableView
                                                            withCellWithIdentifier:@"ListenersCell"];

                    UILabel *listenersLabel = (UILabel *) [cell viewWithTag:2];
                    listenersLabel.text = NSLocalizedString(@"Listeners", @"リスナー数");
                        
                    // テーブルセルのテキスト等の色を変える
                    listenersLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    listenersLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;

                    // チェックマークの表示
                    UIImageView *checkImage = (UIImageView *) [cell viewWithTag:3];
                    checkImage.hidden = (channelSortType != ChannelSortTypeListeners);
                    break;
                }
                case 2: // Title
                {
                    cell = [SideMenuTableViewController tableView:tableView
                                                            withCellWithIdentifier:@"TitleCell"];

                    UILabel *titleLabel = (UILabel *) [cell viewWithTag:2];
                    titleLabel.text = NSLocalizedString(@"Title", @"タイトル");

                    // テーブルセルのテキスト等の色を変える
                    titleLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    titleLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;

                    // チェックマークの表示
                    UIImageView *checkImage = (UIImageView *) [cell viewWithTag:3];
                    checkImage.hidden = (channelSortType != ChannelSortTypeTitle);
                    break;
                }
                case 3: // DJ
                {
                    cell = [SideMenuTableViewController tableView:tableView
                                                            withCellWithIdentifier:@"DjCell"];

                    UILabel *djLabel = (UILabel *) [cell viewWithTag:2];
                    djLabel.text = NSLocalizedString(@"DJ", @"DJ");

                    // テーブルセルのテキスト等の色を変える
                    djLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    djLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;

                    // チェックマークの表示
                    UIImageView *checkImage = (UIImageView *) [cell viewWithTag:3];
                    checkImage.hidden = (channelSortType != ChannelSortTypeDj);
                    break;
                }
                default:
                    break;
            }
            break;
        case 2: // Others Section
            switch (indexPath.row) {
                case 0: // Favorite
                {
                    cell = [SideMenuTableViewController tableView:tableView
                                                            withCellWithIdentifier:@"FavoritesCell"];
                    
                    UILabel *favoritesLabel = (UILabel *) [cell viewWithTag:2];
                    favoritesLabel.text = NSLocalizedString(@"Favorites", @"お気に入り 複数");

                    // テーブルセルのテキスト等の色を変える
                    favoritesLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    favoritesLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;

                    break;
                }
                case 1: // About
                {
                    cell = [SideMenuTableViewController tableView:tableView
                                                            withCellWithIdentifier:@"AboutCell"];

                    UILabel *aboutLabel = (UILabel *) [cell viewWithTag:2];
                    aboutLabel.text = NSLocalizedString(@"About Ladio Tail", @"Ladio Tailについて");
                    
                    // テーブルセルのテキスト等の色を変える
                    aboutLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    aboutLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;

                    break;
                }
                default:
                    break;
            }
            break;
        default:
            break;
    }

    return cell;
}

#pragma mark - UITableViewDelegate methods

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // セクションの色を変える
    const CGFloat sectionHeight = [self tableView:tableView heightForHeaderInSection:section];
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, sectionHeight)];
    headerView.backgroundColor = SIDEMENU_TABLE_SECTION_BACKGROUND_COLOR;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, headerView.frame.size.width - 20, 22)];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.font = [UIFont boldSystemFontOfSize:16.0];
    label.shadowOffset = CGSizeMake(0.0, 1.0);
    label.shadowColor = SIDEMENU_TABLE_SECTION_TEXT_SHADOW_COLOR;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = SIDEMENU_TABLE_SECTION_TEXT_COLOR;
    
    [headerView addSubview:label];
    return headerView;
}

-  (void)tableView:(UITableView *)tableView
   willDisplayCell:(UITableViewCell *)cell
 forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // テーブルセルの背景の色を変える
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = SIDEMENU_TABLE_CELL_BACKGROUND_COLOR_DARK;
    } else {
        cell.backgroundColor = SIDEMENU_TABLE_CELL_BACKGROUND_COLOR_LIGHT;
    }
    
    // テーブルセルの選択色を変える
    UIView *selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = SIDEMENU_CELL_SELECTED_BACKGROUND_COLOR;
    cell.selectedBackgroundView = selectedBackgroundView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case 0: // Update Section
        {
            switch (indexPath.row) {
                case 0: // Update
                    [self.viewDeckController closeLeftViewAnimated:YES completion:^(IIViewDeckController *controller) {
                        HeadlineViewController *headlineViewController =
                            [SideMenuTableViewController headlineViewControllerFromViewDeckCenter:controller];
                        if (headlineViewController) {
                            [headlineViewController fetchHeadline];
                        }
                    }];
                    break;
                default:
                    break;
            }
            break;
        }
        case 1: // Sort Section
        {
            [self.viewDeckController closeLeftViewAnimated:YES completion:^(IIViewDeckController *controller) {
                HeadlineViewController *headlineViewController =
                    [SideMenuTableViewController headlineViewControllerFromViewDeckCenter:controller];
                if (headlineViewController) {
                    ChannelSortType channelSortType = ChannelSortTypeNone;
                    switch (indexPath.row) {
                        case 0: // Newly
                            channelSortType = ChannelSortTypeNewly;
                            break;
                        case 1: // Listeners
                            channelSortType = ChannelSortTypeListeners;
                            break;
                        case 2: // Title
                            channelSortType = ChannelSortTypeTitle;
                            break;
                        case 3: // DJ
                            channelSortType = ChannelSortTypeDj;
                            break;
                        default:
                            break;
                    }

                    [headlineViewController setChannelSortType:channelSortType];

                    // チェックマーク位置変更のためテーブルを更新
                    [tableView reloadData];
                }
            }];
            break;
        }
        case 2: // Others Section
            switch (indexPath.row) {
                case 0: // Favorite
                {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                    UIViewController *controller = (UIViewController *)
                        [storyboard instantiateViewControllerWithIdentifier:@"FavoriteNaviViewController"];
                    [self presentModalViewController:controller animated:YES];
                    break;
                }
                case 1: // About
                {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                    UIViewController *controller = (UIViewController *)
                    [storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"];
                    [self presentModalViewController:controller animated:YES];
                    break;
                }
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

@end
