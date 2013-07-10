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
#import "Views/SideMenuTableViewCell.h"
#import "HeadlineNaviViewController.h"
#import "HeadlineViewController.h"
#import "FavoriteNaviViewController.h"
#import "FavoritesTableViewController.h"
#import "SideMenuTableViewController.h"

@implementation SideMenuTableViewController

#pragma mark - Private methods

/// CellIdentifireから該当のセルを取得する
+ (SideMenuTableViewCell *)tableView:(UITableView *)tableView withCellWithIdentifier:(NSString *)cellIdentifier
{
    SideMenuTableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[SideMenuTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:cellIdentifier];
    }
    return cell;
}

/// IIViewDeckControllerのセンタービューのHeadlineViewControllerを取得する
- (HeadlineViewController *)headlineViewControllerFromViewDeckCenterControllerTop
{
    // ViewDeckControllerのCenterControllerを取得する
    UIViewController* centerController = self.viewDeckController.centerController;
    if ([centerController isKindOfClass:[HeadlineNaviViewController class]]) {
        HeadlineNaviViewController *headlineNaviViewController =
            (HeadlineNaviViewController*)self.viewDeckController.centerController;
        if ([headlineNaviViewController.topViewController isKindOfClass:[HeadlineViewController class]]){
            return (HeadlineViewController *)headlineNaviViewController.topViewController;
        }
    }
    return nil;
}

/// ViewDeckControllerのCenterControllerのクラスが指定のクラスで、かつそのTopViewControllerが指定のクラスかを取得する
- (BOOL)isCenterControllerClass:(Class)centerControllerClass andTopViewController:(Class)topViewControllerClass
{
    // ViewDeckControllerのCenterControllerを取得する
    UIViewController* centerController = self.viewDeckController.centerController;
    // CenterControllerが指定のクラスの場合
    if ([centerController isKindOfClass:centerControllerClass]) {
        // CenterControllerがUINavigationControllerクラスの場合でかつCenterControllerのtopViewControllerが指定のクラスの場合
        if ([centerController isKindOfClass:[UINavigationController class]]) {
            UIViewController* topViewController = ((UINavigationController *)centerController).topViewController;
            if ([topViewController isKindOfClass:topViewControllerClass]) {
                return YES;
            }
        }
    }
    return NO;
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

    // お気に入り画面からの戻るボタンのテキストと色を書き換える
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
            return 1;
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
    SideMenuTableViewCell *cell = nil;

    ChannelSortType channelSortType = ChannelSortTypeNone;
    HeadlineViewController* headlineViewController = [self headlineViewControllerFromViewDeckCenterControllerTop];
    if (headlineViewController) {
        channelSortType = headlineViewController.channelSortType;
    }
    
    switch (indexPath.section) {
        case 0: // Update Section
            switch (indexPath.row) {
                case 0: // Update
                {
                    cell = [[self class] tableView:tableView withCellWithIdentifier:@"UpdateCell"];
                    
                    UILabel *updateLabel = (UILabel *) [cell viewWithTag:2];
                    updateLabel.text = NSLocalizedString(@"Update", @"更新");
                    
                    // テーブルセルのテキスト等の色を変える
                    updateLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    updateLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;

                    cell.accessibilityLabel = NSLocalizedString(@"Update", @"更新");
                    cell.accessibilityHint = NSLocalizedString(@"Update the channel list", @"番組表を更新");
                    break;
                }
                default:
                    break;
            }
            break;
        case 1: // Sort Section
#if defined(LADIO_TAIL)
            switch (indexPath.row) {
                case 0: // Newly
                {
                    cell = [[self class] tableView:tableView withCellWithIdentifier:@"NewlyCell"];
                    
                    UILabel *newlyLabel = (UILabel *) [cell viewWithTag:2];
                    newlyLabel.text = NSLocalizedString(@"Newly", @"新規");
                    
                    // テーブルセルのテキスト等の色を変える
                    newlyLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    newlyLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;
                    
                    // チェックマークの表示
                    UIImageView *checkImage = (UIImageView *) [cell viewWithTag:3];
                    checkImage.hidden = (channelSortType != ChannelSortTypeNewly);

                    cell.accessibilityLabel = NSLocalizedString(@"Newly", @"新規");
                    cell.accessibilityHint = NSLocalizedString(@"Sort in newly order the channel list", @"番組表を新しい順でソート");
                    break;
                }
                case 1: // Listeners
                {
                    cell = [[self class] tableView:tableView withCellWithIdentifier:@"ListenersCell"];
                    
                    UILabel *listenersLabel = (UILabel *) [cell viewWithTag:2];
                    listenersLabel.text = NSLocalizedString(@"Listeners", @"リスナー数");
                    
                    // テーブルセルのテキスト等の色を変える
                    listenersLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    listenersLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;
                    
                    // チェックマークの表示
                    UIImageView *checkImage = (UIImageView *) [cell viewWithTag:3];
                    checkImage.hidden = (channelSortType != ChannelSortTypeListeners);

                    cell.accessibilityLabel = NSLocalizedString(@"Listeners", @"リスナー数");
                    cell.accessibilityHint = NSLocalizedString(@"Sort in listeners order the channel list", @"番組表をリスナー数でソート");
                    break;
                }
                case 2: // Title
                {
                    cell = [[self class] tableView:tableView withCellWithIdentifier:@"TitleCell"];
                    
                    UILabel *titleLabel = (UILabel *) [cell viewWithTag:2];
                    titleLabel.text = NSLocalizedString(@"Title", @"タイトル");
                    
                    // テーブルセルのテキスト等の色を変える
                    titleLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    titleLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;
                    
                    // チェックマークの表示
                    UIImageView *checkImage = (UIImageView *) [cell viewWithTag:3];
                    checkImage.hidden = (channelSortType != ChannelSortTypeTitle);

                    cell.accessibilityLabel = NSLocalizedString(@"Title", @"タイトル");
                    cell.accessibilityHint = NSLocalizedString(@"Sort by title the channel list", @"番組表をタイトルでソート");
                    break;
                }
                case 3: // DJ
                {
                    cell = [[self class] tableView:tableView withCellWithIdentifier:@"DjCell"];
                    
                    UILabel *djLabel = (UILabel *) [cell viewWithTag:2];
                    djLabel.text = NSLocalizedString(@"DJ", @"DJ");
                    
                    // テーブルセルのテキスト等の色を変える
                    djLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    djLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;
                    
                    // チェックマークの表示
                    UIImageView *checkImage = (UIImageView *) [cell viewWithTag:3];
                    checkImage.hidden = (channelSortType != ChannelSortTypeDj);

                    cell.accessibilityLabel = NSLocalizedString(@"DJ", @"DJ");
                    cell.accessibilityHint = NSLocalizedString(@"Sort by DJ the channel list", @"番組表をDJでソート");
                    break;
                }
                default:
                    break;
            }
            break;
#elif defined(RADIO_EDGE)
            switch (indexPath.row) {
                case 0: // None
                {
                    cell = [[self class] tableView:tableView withCellWithIdentifier:@"NoneCell"];
                    
                    UILabel *noneLabel = (UILabel *) [cell viewWithTag:2];
                    noneLabel.text = NSLocalizedString(@"NoneSort", @"並べ替えない");
                    
                    // テーブルセルのテキスト等の色を変える
                    noneLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    noneLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;
                    
                    // チェックマークの表示
                    UIImageView *checkImage = (UIImageView *) [cell viewWithTag:3];
                    checkImage.hidden = (channelSortType != ChannelSortTypeNewly);

                    cell.accessibilityLabel = NSLocalizedString(@"NoneSort", @"並べ替えない");
                    cell.accessibilityHint = NSLocalizedString(@"Do not sort the channel list", @"並べ替えない");
                    break;
                }
                case 1: // Server Name
                {
                    cell = [[self class] tableView:tableView withCellWithIdentifier:@"TitleCell"];
                    
                    UILabel *titleLabel = (UILabel *) [cell viewWithTag:2];
                    titleLabel.text = NSLocalizedString(@"Title", @"タイトル");
                    
                    // テーブルセルのテキスト等の色を変える
                    titleLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    titleLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;
                    
                    // チェックマークの表示
                    UIImageView *checkImage = (UIImageView *) [cell viewWithTag:3];
                    checkImage.hidden = (channelSortType != ChannelSortTypeServerName);

                    cell.accessibilityLabel = NSLocalizedString(@"Title", @"タイトル");
                    cell.accessibilityHint = NSLocalizedString(@"Sort by title the channel list", @"番組表をタイトルでソート");
                    break;
                }
                case 2: // Genre
                {
                    cell = [[self class] tableView:tableView withCellWithIdentifier:@"GenreCell"];
                    
                    UILabel *genreLabel = (UILabel *) [cell viewWithTag:2];
                    genreLabel.text = NSLocalizedString(@"Genre", @"ジャンル");
                    
                    // テーブルセルのテキスト等の色を変える
                    genreLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    genreLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;
                    
                    // チェックマークの表示
                    UIImageView *checkImage = (UIImageView *) [cell viewWithTag:3];
                    checkImage.hidden = (channelSortType != ChannelSortTypeGenre);

                    cell.accessibilityLabel = NSLocalizedString(@"Genre", @"ジャンル");
                    cell.accessibilityHint = NSLocalizedString(@"Sort by genre the channel list", @"番組表をジャンルでソート");
                    break;
                }
                case 3: // Bitrate
                {
                    cell = [[self class] tableView:tableView withCellWithIdentifier:@"BitrateCell"];
                    
                    UILabel *djLabel = (UILabel *) [cell viewWithTag:2];
                    djLabel.text = NSLocalizedString(@"Bitrate", @"ビットレート");
                    
                    // テーブルセルのテキスト等の色を変える
                    djLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    djLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;
                    
                    // チェックマークの表示
                    UIImageView *checkImage = (UIImageView *) [cell viewWithTag:3];
                    checkImage.hidden = (channelSortType != ChannelSortTypeBitrate);
                    
                    cell.accessibilityLabel = NSLocalizedString(@"Bitrate", @"ビットレート");
                    cell.accessibilityHint = NSLocalizedString(@"Sort by bitrate the channel list", @"番組表をビットレートでソート");
                    break;
                }
                default:
                    break;
            }
            break;
#else
            #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif
        case 2: // Others Section
            switch (indexPath.row) {
                case 0: // Favorite
                {
                    cell = [[self class] tableView:tableView withCellWithIdentifier:@"FavoritesCell"];
                    
                    UILabel *favoritesLabel = (UILabel *) [cell viewWithTag:2];
                    favoritesLabel.text = NSLocalizedString(@"Favorites", @"お気に入り 複数");

                    // テーブルセルのテキスト等の色を変える
                    favoritesLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    favoritesLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;

                    cell.accessibilityLabel = NSLocalizedString(@"Favorites", @"お気に入り 複数");
                    cell.accessibilityHint = NSLocalizedString(@"Open the favorites view", @"お気に入り画面を開く");
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
                    // CenterControllerがHeadlineNaviViewControllerでｍかつHeadlineViewControllerが表示中の場合は
                    // サイドメニューを閉じ、閉じ終わった後に更新
                    if ([self isCenterControllerClass:[HeadlineNaviViewController class]
                                 andTopViewController:[HeadlineViewController class]]) {
                        __weak id weakSelf = self;
                        [self.viewDeckController closeLeftViewAnimated:YES
                                                            completion:^(IIViewDeckController *controller, BOOL success) {
                            id strongSelf = weakSelf;
                            [[strongSelf headlineViewControllerFromViewDeckCenterControllerTop] fetchHeadline];
                        }];
                    }
                    // CenterControllerがHeadlineNaviViewControllerでない、またはHeadlineViewControllerが表示中でない場合は
                    // サイドメニューをバウンドしセンターを変更しつつ、閉じ終わった後に更新
                    else {
                        __weak id weakSelf = self;
                        [self.viewDeckController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                            SideMenuTableViewController *strongSelf = weakSelf;
                            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                            HeadlineNaviViewController *headlineNaviViewController = (HeadlineNaviViewController *)
                                [storyboard instantiateViewControllerWithIdentifier:@"HeadlineNaviViewController"];
                            strongSelf.viewDeckController.centerController = headlineNaviViewController;

                            // チェックマーク位置変更のためテーブルを更新
                            [tableView reloadData];
                        }
                                                            completion:^(IIViewDeckController *controller, BOOL success) {
                            id strongSelf = weakSelf;
                            [[strongSelf headlineViewControllerFromViewDeckCenterControllerTop] fetchHeadline];
                        }];
                    }
                    break;
                default:
                    break;
            }
            break;
        }
        case 1: // Sort Section
        {
            // CenterControllerがHeadlineNaviViewControllerで、かつHeadlineViewControllerが表示中の場合
            // サイドメニューを閉じつつ、番組の並び順を変更
            if ([self isCenterControllerClass:[HeadlineNaviViewController class]
                         andTopViewController:[HeadlineViewController class]]) {
                ChannelSortType channelSortType = ChannelSortTypeNone;
#if defined(LADIO_TAIL)
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
#elif defined(RADIO_EDGE)
                switch (indexPath.row) {
                    case 0: // None
                        channelSortType = ChannelSortTypeNewly;
                        break;
                    case 1: // Server Name
                        channelSortType = ChannelSortTypeServerName;
                        break;
                    case 2: // Genre
                        channelSortType = ChannelSortTypeGenre;
                        break;
                    case 3: // Bitrate
                        channelSortType = ChannelSortTypeBitrate;
                        break;
                    default:
                        break;
                }
#else
                #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif

                [[self headlineViewControllerFromViewDeckCenterControllerTop] setChannelSortType:channelSortType];

                // ヘッドラインテーブルをトップに移動
                [[self headlineViewControllerFromViewDeckCenterControllerTop] scrollToTopAnimated:YES];

                // チェックマーク位置変更のためテーブルを更新
                [tableView reloadData];

                [self.viewDeckController closeLeftViewAnimated:YES];
            }
            // CenterControllerがHeadlineNaviViewControllerでない、またはHeadlineViewControllerが表示中でない場合は
            // サイドメニューをバウンドしセンターを変更しつつ、番組の並び順を変更
            else {
                __weak id weakSelf = self;
                [self.viewDeckController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                    SideMenuTableViewController *strongSelf = weakSelf;
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                    HeadlineNaviViewController *headlineNaviViewController = (HeadlineNaviViewController *)
                        [storyboard instantiateViewControllerWithIdentifier:@"HeadlineNaviViewController"];
                    strongSelf.viewDeckController.centerController = headlineNaviViewController;

                    ChannelSortType channelSortType = ChannelSortTypeNone;
#if defined(LADIO_TAIL)
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
#elif defined(RADIO_EDGE)
                    switch (indexPath.row) {
                        case 0: // None
                            channelSortType = ChannelSortTypeNewly;
                            break;
                        case 1: // Server Name
                            channelSortType = ChannelSortTypeServerName;
                            break;
                        case 2: // Genre
                            channelSortType = ChannelSortTypeGenre;
                            break;
                        case 3: // Bitrate
                            channelSortType = ChannelSortTypeBitrate;
                            break;
                        default:
                            break;
                    }
#else
#error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif
                    
                    [[strongSelf headlineViewControllerFromViewDeckCenterControllerTop] setChannelSortType:channelSortType];

                    // チェックマーク位置変更のためテーブルを更新
                    [tableView reloadData];
                }];
            }
            break;
        }
        case 2: // Others Section
            switch (indexPath.row) {
                case 0: // Favorite
                {
                    // CenterControllerがFavoriteNaviViewControllerで、かつFavoritesTableViewControllerが表示中の場合
                    // サイドメニューを閉じる
                    if ([self isCenterControllerClass:[FavoriteNaviViewController class]
                                 andTopViewController:[FavoritesTableViewController class]]) {
                        [self.viewDeckController closeLeftViewAnimated:YES];
                    }
                    // CenterControllerがFavoriteNaviViewControllerでない、またはFavoritesTableViewControllerが表示中でない
                    // 場合、サイドメニューをバウンドしセンターを変更
                    else {
                        __weak id weakSelf = self;
                        [self.viewDeckController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                            SideMenuTableViewController *strongSelf = weakSelf;
                            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                            FavoriteNaviViewController *favoriteNaviViewController = (FavoriteNaviViewController *)
                                [storyboard instantiateViewControllerWithIdentifier:@"FavoriteNaviViewController"];
                            strongSelf.viewDeckController.centerController = favoriteNaviViewController;

                            // チェックマーク位置変更のためテーブルを更新
                            [tableView reloadData];
                        }];
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

@end
