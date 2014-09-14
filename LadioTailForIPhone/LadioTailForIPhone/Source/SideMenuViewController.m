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

#import <ViewDeck/IIViewDeckController.h>
#import "LadioTailConfig.h"
#import "Views/SideMenuTableViewCell.h"
#import "Views/SideMenuTableViewSectionLabel.h"
#import "HeadlineNaviViewController.h"
#import "HeadlineViewController.h"
#import "FavoriteNaviViewController.h"
#import "FavoritesTableViewController.h"
#import "HistoryNaviViewController.h"
#import "HistoryTableViewController.h"
#import "SleepTimer.h"
#import "SideMenuViewController.h"

@implementation SideMenuViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailSleepTimerUpdate object:nil];
}

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

- (void)sleepTimerUpdate:(NSNotification *)timer
{
    [self.tableView reloadData];
}

#pragma mark - UIView methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 背景色の色を変える（この背景は見えないはずだが一応色を塗っておく）
    self.view.backgroundColor = SIDEMENU_BACKGROUND_COLOR;

    // テーブルの背景の色を変える
    self.tableView.backgroundColor = SIDEMENU_TABLE_BACKGROUND_COLOR;
    // テーブルの境界線の色を変える
    self.tableView.separatorColor = SIDEMENU_TABLE_SEPARATOR_COLOR;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sleepTimerUpdate:)
                                                 name:LadioTailSleepTimerUpdate
                                               object:nil];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setTableView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    // 選択を解除する
    [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:animated];
    
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
            return 3;
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
                case 1: // History
                {
                    cell = [[self class] tableView:tableView withCellWithIdentifier:@"HistoryCell"];
                    
                    UILabel *historyLabel = (UILabel *) [cell viewWithTag:2];
                    historyLabel.text = NSLocalizedString(@"History", @"履歴");
                    
                    // テーブルセルのテキスト等の色を変える
                    historyLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    historyLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;
                    
                    cell.accessibilityLabel = NSLocalizedString(@"History", @"履歴");
                    cell.accessibilityHint = NSLocalizedString(@"Open the history view", @"履歴画面を開く");
                    break;
                }
                case 2: // Sleep timer
                {
                    cell = [[self class] tableView:tableView withCellWithIdentifier:@"SleepTimerCell"];
                    
                    UILabel *sleepTimerTitleLabel = (UILabel *) [cell viewWithTag:2];
                    sleepTimerTitleLabel.text = NSLocalizedString(@"Sleep Timer", @"スリープタイマー");
                    
                    UILabel *sleepTimerDateLabel = (UILabel *) [cell viewWithTag:3];
                    NSDate *sleepTimerFireDate = [[SleepTimer sharedInstance] fireDate];
                    // スリープタイマーの設定がある場合
                    if (sleepTimerFireDate) {
                        static NSDateFormatter *dateFormatter = nil;
                        static dispatch_once_t onceToken = 0;
                        dispatch_once(&onceToken, ^{
                            dateFormatter = [[NSDateFormatter alloc] init];
                            [dateFormatter setDateStyle:NSDateFormatterShortStyle];
                            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                        });
                        sleepTimerDateLabel.text = [dateFormatter stringFromDate:sleepTimerFireDate];
                        
                        sleepTimerDateLabel.hidden = NO;
                    }
                    // スリープタイマーの設定が無い場合
                    else {
                        sleepTimerDateLabel.hidden = YES;
                    }
                    
                    // テーブルセルのテキスト等の色を変える
                    sleepTimerTitleLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    sleepTimerTitleLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;
                    sleepTimerDateLabel.textColor = SIDEMENU_CELL_MAIN_TEXT_COLOR;
                    sleepTimerDateLabel.highlightedTextColor = SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;
                    
                    cell.accessibilityLabel = NSLocalizedString(@"Sleep Timer", @"スリープタイマー");
                    cell.accessibilityHint = NSLocalizedString(@"Set the sleep timer", @"スリープタイマーを設定する");
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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Others - Sleep Timer
    if (indexPath.section == 2 && indexPath.row == 2) {
        // スリープタイマーの設定がある場合
        if ([[SleepTimer sharedInstance] fireDate]) {
            return 60;
        }
    }
    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // セクションの色を変える
    const CGFloat sectionHeight = UITableViewAutomaticDimension;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, sectionHeight)];
    headerView.backgroundColor = SIDEMENU_TABLE_SECTION_BACKGROUND_COLOR;
    SideMenuTableViewSectionLabel *label =
        [[SideMenuTableViewSectionLabel alloc] initWithFrame:CGRectMake(0, 0, headerView.frame.size.width, 22)];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.font = [UIFont boldSystemFontOfSize:16.0];
    label.shadowOffset = CGSizeMake(0.0, 1.0);
    label.shadowColor = SIDEMENU_TABLE_SECTION_TEXT_SHADOW_COLOR;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = SIDEMENU_TABLE_SECTION_TEXT_COLOR;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
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
                            SideMenuViewController *strongSelf = weakSelf;
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
                    SideMenuViewController *strongSelf = weakSelf;
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
                            SideMenuViewController *strongSelf = weakSelf;
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
                case 1: // History
                {
                    // CenterControllerがHistoryNaviViewControllerで、かつHistoryTableViewControllerが表示中の場合
                    // サイドメニューを閉じる
                    if ([self isCenterControllerClass:[HistoryNaviViewController class]
                                 andTopViewController:[HistoryTableViewController class]]) {
                        [self.viewDeckController closeLeftViewAnimated:YES];
                    }
                    // CenterControllerがHistoryNaviViewControllerでない、またはHistoryTableViewControllerが表示中でない
                    // 場合、サイドメニューをバウンドしセンターを変更
                    else {
                        __weak id weakSelf = self;
                        [self.viewDeckController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                            SideMenuViewController *strongSelf = weakSelf;
                            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                            HistoryNaviViewController *historyNaviViewController = (HistoryNaviViewController *)
                                [storyboard instantiateViewControllerWithIdentifier:@"HistoryNaviViewController"];
                            strongSelf.viewDeckController.centerController = historyNaviViewController;
                            
                            // チェックマーク位置変更のためテーブルを更新
                            [tableView reloadData];
                        }];
                    }
                    break;
                }
                case 2: // Sleep timer
                {
                    // 再生停止までの時間を選択してくださいダイアログを表示
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                                   message:NSLocalizedString(@"Select a time to stop playing.", @"再生停止までの時間を選択してください")
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Off", @"オフ")
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [[SleepTimer sharedInstance] stop];
                                                                [self.viewDeckController closeLeftViewAnimated:YES];
                                                            }]];
                    [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%d mins after", @"xx分後"), 15]
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [[SleepTimer sharedInstance] setSleepTimerWithInterval:15 * 60];
                                                                [self.viewDeckController closeLeftViewAnimated:YES];
                                                            }]];
                    [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%d mins after", @"xx分後"), 30]
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [[SleepTimer sharedInstance] setSleepTimerWithInterval:30 * 60];
                                                                [self.viewDeckController closeLeftViewAnimated:YES];
                                                            }]];
                    [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%d mins after", @"xx分後"), 60]
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [[SleepTimer sharedInstance] setSleepTimerWithInterval:60 * 60];
                                                                [self.viewDeckController closeLeftViewAnimated:YES];
                                                            }]];
                    [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%d mins after", @"xx分後"), 120]
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [[SleepTimer sharedInstance] setSleepTimerWithInterval:120 * 60];
                                                                [self.viewDeckController closeLeftViewAnimated:YES];
                                                            }]];
                    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"キャンセル")
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction *action) {
                                                                [self.viewDeckController closeLeftViewAnimated:YES];
                                                            }]];
                    [self presentViewController:alert animated:YES completion:nil];
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
