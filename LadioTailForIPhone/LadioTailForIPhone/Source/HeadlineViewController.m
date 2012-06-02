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

#import "FBNetworkReachability/FBNetworkReachability.h"
#import "LadioLib/LadioLib.h"
#import "LadioTailConfig.h"
#import "SearchWordManager.h"
#import "Player.h"
#import "IAdBannerManager.h"
#import "ChannelViewController.h"
#import "HeadlineViewController.h"

/// 広告を表示後に隠すか。デバッグ用。
#define AD_HIDE_DEBUG 0

@implementation HeadlineViewController
{
@private
    /// 再生中ボタンのインスタンスを一時的に格納しておく領域
    UIBarButtonItem *tempPlayingBarButtonItem_;

    /// PullRefreshView
    EGORefreshTableHeaderView *refreshHeaderView_;

    /// 広告が表示されているか
    BOOL isVisibleAdBanner_;
}

@synthesize showedChannels = showedChannels_;
@synthesize navigateionItem = navigateionItem_;
@synthesize updateBarButtonItem = updateBarButtonItem_;
@synthesize playingBarButtonItem = playingBarButtonItem_;
@synthesize headlineSearchBar = headlineSearchBar_;
@synthesize headlineTableView = headlineTableView_;

- (void)dealloc
{
    tempPlayingBarButtonItem_ = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioLibHeadlineDidStartLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioLibHeadlineDidFinishLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioLibHeadlineFailLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioLibHeadlineChannelChangedNotification object:nil];
#ifdef DEBUG
    NSLog(@"%@ unregisted headline update notifications.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidPlayNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidStopNotification object:nil];
}

#pragma mark - Private methods

- (ChannelSortType)channelSortType
{
    return ChannelSortTypeNone;
}

- (void)fetchHeadline
{
    Headline *headline = [Headline sharedInstance];
    [headline fetchHeadline];
}

/// 渡された日付と現在の日付から、日付ラベルの背景色を算出する
- (UIColor *)dateLabelBackgroundColor:(NSDate *)date
{
    UIColor *result;

    NSTimeInterval diffTime = [[NSDate date] timeIntervalSinceDate:date];

    // 渡された日付が現在よりも新しい場合（ないはずだが一応）
    if (diffTime <= 0) {
        // 最も明るい色にする
        result = HEADLINE_CELL_DATE_BACKGROUND_COLOR_LIGHT;
    }
    // 6時間以上前
    else if (diffTime >= (6 * 60 * 60)) {
        // 最も暗い色にする
        result = HEADLINE_CELL_DATE_BACKGROUND_COLOR_DARK;
    } else {
        // 時間が経過するごとに暗い色にする
        // 0分：最も明るい 6時間：最も暗い
        double lighty = 1 - (diffTime / (6 * 60 * 60)); // 明るさ
        CGFloat lightRed, lightGreen, lightBlue, lightAlpha, darkRed, darkGreen, darkBlue, darkAlpha;
        [HEADLINE_CELL_DATE_BACKGROUND_COLOR_LIGHT getRed:&lightRed green:&lightGreen blue:&lightBlue alpha:&lightAlpha];
        [HEADLINE_CELL_DATE_BACKGROUND_COLOR_DARK getRed:&darkRed green:&darkGreen blue:&darkBlue alpha:&darkAlpha];
        CGFloat red = ((lightRed - darkRed) * lighty) + darkRed;
        CGFloat green = ((lightGreen - darkGreen) * lighty) + darkGreen;
        CGFloat blue = ((lightBlue - darkBlue) * lighty) + darkBlue;
        CGFloat alpha = ((lightAlpha - darkAlpha) * lighty) + darkAlpha;
        result = [[UIColor alloc] initWithRed:red green:green blue:blue alpha:alpha];
    }

    return result;
}

- (void)updateHeadlineTable
{
    Headline *headline = [Headline sharedInstance];
    showedChannels_ = [headline channels:[self channelSortType]
                              searchWord:[SearchWordManager sharedInstance].searchWord];

    // ナビゲーションタイトルを更新
    NSString *navigationTitleStr = @"";
    if ([showedChannels_ count] == 0) {
        navigationTitleStr = NSLocalizedString(@"ON AIR", @"番組一覧にトップに表示されるONAIR 番組が無い場合/番組画面から戻るボタン");
    } else {
        navigationTitleStr = NSLocalizedString(@"ON AIR %dch", @"番組一覧にトップに表示されるONAIR 番組がある場合");
    }
    navigateionItem_.title = [[NSString alloc] initWithFormat:navigationTitleStr, [showedChannels_ count]];

    // ヘッドラインテーブルを更新
    [self.headlineTableView reloadData];
}

- (void)updateUpdateBarButton
{
    updateBarButtonItem_.enabled = ![[Headline sharedInstance] isFetchingHeadline];
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

#if AD_HIDE_DEBUG
// 広告を隠す。デバッグ用。
- (void)hideAdBanner:(NSTimer *)timer
{
    [self bannerView:nil didFailToReceiveAdWithError:nil];
}
#endif /* #if AD_HIDE_DEBUG */

#pragma mark - Actions

- (IBAction)update:(id)sender
{
    [self fetchHeadline];
}

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // ヘッドラインの取得開始と終了をハンドリングし、ヘッドライン更新ボタンの有効無効の切り替えやテーブル更新を行う
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineDidStartLoad:)
                                                 name:LadioLibHeadlineDidStartLoadNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineDidFinishLoad:)
                                                 name:LadioLibHeadlineDidFinishLoadNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineFailLoad:)
                                                 name:LadioLibHeadlineFailLoadNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineChannelChanged:)
                                                 name:LadioLibHeadlineChannelChangedNotification
                                               object:nil];
#ifdef DEBUG
    NSLog(@"%@ registed headline update notifications.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    // 再生状態が切り替わるごとに再生ボタンなどの表示を切り替える
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playStateChanged:)
                                                 name:LadioTailPlayerDidPlayNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playStateChanged:)
                                                 name:LadioTailPlayerDidStopNotification
                                               object:nil];

    // 番組画面からの戻るボタンのテキストと色を書き換える
    NSString *backButtonString = NSLocalizedString(@"ON AIR", @"番組一覧にトップに表示されるONAIR 番組が無い場合/番組画面から戻るボタン");
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:backButtonString
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
    backButtonItem.tintColor = BACK_BUTTON_COLOR;
    self.navigationItem.backBarButtonItem = backButtonItem;

    // 更新ボタンの色を変更する
    updateBarButtonItem_.tintColor = UPDATE_BUTTON_COLOR;

    // 再生中ボタンの装飾を変更する
    playingBarButtonItem_.title = NSLocalizedString(@"Playing", @"再生中ボタン");
    playingBarButtonItem_.tintColor = PLAYING_BUTTON_COLOR;
    // 再生中ボタンを保持する
    tempPlayingBarButtonItem_ = playingBarButtonItem_;

    // 検索バーの色を変える
    headlineSearchBar_.tintColor = SEARCH_BAR_COLOR;

    // 検索バーが空でもサーチキーを押せるようにする
    // http://stackoverflow.com/questions/3846917/iphone-uisearchbar-how-to-search-for-string
    for (UIView *subview in headlineSearchBar_.subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            ((UITextField *) subview).enablesReturnKeyAutomatically = NO;
            break;
        }
    }

    // StoryBoard上でセルの高さを設定しても有効にならないので、ここで高さを設定する
    // http://stackoverflow.com/questions/7214739/uitableview-cells-height-is-not-working-in-a-empty-table
    headlineTableView_.rowHeight = 54;
    // テーブルの背景の色を変える
    headlineTableView_.backgroundColor = HEADLINE_TABLE_BACKGROUND_COLOR;
    // テーブルの境界線の色を変える
    headlineTableView_.separatorColor = HEADLINE_TABLE_SEPARATOR_COLOR;

    if (PULL_REFRESH_HEADLINE) {
        // PullRefreshViewの生成
        if (refreshHeaderView_ == nil) {
            CGRect pullRefreshViewRect = CGRectMake(
                                                    0.0f,
                                                    0.0f - headlineTableView_.bounds.size.height,
                                                    self.view.frame.size.width,
                                                    headlineTableView_.bounds.size.height);
            EGORefreshTableHeaderView *view =
            [[EGORefreshTableHeaderView alloc] initWithFrame:pullRefreshViewRect
                                              arrowImageName:PULL_REFRESH_ARROW_IMAGE
                                                   textColor:PULL_REFRESH_TEXT_COLOR];
            view.backgroundColor = PULL_REFRESH_TEXT_BACKGROUND_COLOR;
            
            view.delegate = self;
            [headlineTableView_ addSubview:view];
            refreshHeaderView_ = view;
        }
    }
}

- (void)viewDidUnload
{
    [self setUpdateBarButtonItem:nil];
    [self setNavigateionItem:nil];
    [self setPlayingBarButtonItem:nil];
    [self setHeadlineSearchBar:nil];
    [self setHeadlineTableView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    // 更新ボタンの有効無効を切り替え
    [self updateUpdateBarButton];

    // タブの切り替えごとにヘッドラインテーブルを更新する
    // 別タブで更新したヘッドラインをこのタブのテーブルでも使うため
    [self updateHeadlineTable];

    // タブの切り替えごとに検索バーを更新する
    // 別タブで入力した検索バーのテキストをこのタブでも使うため
    NSString *searchWord = [SearchWordManager sharedInstance].searchWord;
    headlineSearchBar_.text = searchWord;

    // 再生状態に逢わせて再生ボタンの表示を切り替える
    [self updatePlayingButton];

    // viewWillAppear:animated はsuperを呼び出す必要有り
    // テーブルの更新前に呼ぶらしい
    // http://d.hatena.ne.jp/kimada/20090917/1253187128
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (HEADLINE_VIEW_IAD_ENABLE) {
        // テーブルの初期位置を設定
        // 広告のアニメーション前に初期位置を設定する必要有り
        headlineTableView_.frame = CGRectMake(0, 44, 320, 323);
        
        // 広告を表示する
        ADBannerView *adBannerView = [IAdBannerManager sharedInstance].adBannerView;
        isVisibleAdBanner_ = NO;
        [adBannerView setFrame:CGRectMake(0, 377, 320, 50)];
        if (adBannerView.bannerLoaded) {
            [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION 
                                  delay:0
                                options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 adBannerView.frame = CGRectMake(0, 317, 320, 50);
                             }
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     headlineTableView_.frame = CGRectMake(0, 44, 320, 273);
                                 }
                             }];
            isVisibleAdBanner_ = YES;
#if AD_HIDE_DEBUG
            [NSTimer scheduledTimerWithTimeInterval:4.0
                                             target:self
                                           selector:@selector(hideAdBanner:)
                                           userInfo:nil
                                            repeats:NO];
#endif /* #if AD_HIDE_DEBUG */
        }
        adBannerView.delegate = self;
        [self.view insertSubview:adBannerView aboveSubview:headlineTableView_];
    }

    // ネットワークが接続済みの場合で、かつ番組表を取得していない場合
    if ([FBNetworkReachability sharedInstance].reachable && [[Headline sharedInstance] channels] == 0) {
        // 番組表を取得する
        // 進捗ウィンドウを正しく表示させるため、viewDidAppear:animated で番組表を取得する
        [self fetchHeadline];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (HEADLINE_VIEW_IAD_ENABLE) {
        // テーブルの初期位置を設定
        // Viewを消す前に大きさを元に戻しておくことで、タブの切り替え時にちらつくのを防ぐ
        headlineTableView_.frame = CGRectMake(0, 44, 320, 323);
        
        // 広告の表示を消す
        ADBannerView *adBannerView = [IAdBannerManager sharedInstance].adBannerView;
        adBannerView.delegate = nil;
    }

    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (HEADLINE_VIEW_IAD_ENABLE) {
        // 広告Viewを削除
        ADBannerView *adBannerView = [IAdBannerManager sharedInstance].adBannerView;
        [adBannerView removeFromSuperview];
    }

    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // テーブルから番組を選択した
    if ([[segue identifier] isEqualToString:@"SelectChannel"]) {
        // 番組情報を遷移先のViewに設定
        UIViewController *viewCon = [segue destinationViewController];
        if ([viewCon isKindOfClass:[ChannelViewController class]]) {
            Channel *channel = [showedChannels_ objectAtIndex:[headlineTableView_ indexPathForSelectedRow].row];
            ((ChannelViewController *) viewCon).channel = channel;
        }
    }
    // 再生中ボタンを選択した
    else if ([[segue identifier] isEqualToString:@"PlayingChannel"]) {
        // 番組情報を遷移先のViewに設定
        UIViewController *viewCon = [segue destinationViewController];
        if ([viewCon isKindOfClass:[ChannelViewController class]]) {
            NSURL *playingUrl = [[Player sharedInstance] playingUrl];
            Headline *headline = [Headline sharedInstance];
            Channel *channel = [headline channelFromPlayUrl:playingUrl];
            ((ChannelViewController *) viewCon).channel = channel;
        }
    }
}

/// 再生している番組をテーブルの一番上になるようにスクロールする
- (void)scrollToTopAtPlayingCell
{
    Channel *playingChannel = [[Player sharedInstance] playingChannel];
    if (playingChannel == nil) {
        return;
    }

    NSInteger playingChannelIndex;
    BOOL found = NO;
    // 再生している番組がの何番目かを探索する
    for (playingChannelIndex = 0; playingChannelIndex < [showedChannels_ count]; ++playingChannelIndex) {
        Channel *channel = [showedChannels_ objectAtIndex:playingChannelIndex];
        if ([channel isSameMount:playingChannel]) {
            found = YES; // 見つかったことを示す
            break;
        }
    }

    // 見つかった場合はスクロール
    if (found){
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:playingChannelIndex inSection:0];  
        [headlineTableView_ scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // 検索バーに入力された文字列を保持
    [SearchWordManager sharedInstance].searchWord = searchText;

    [self updateHeadlineTable];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [showedChannels_ count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Channel *channel = (Channel *) [showedChannels_ objectAtIndex:indexPath.row];

    NSString *cellIdentifier;

    // DJのみが存在する場合
    if (([channel.nam length] == 0) && !([channel.dj length] == 0)) {
        cellIdentifier = @"ChannelDjOnlyCell";
    } else {
        cellIdentifier = @"ChannelCell";
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    UILabel *titleLabel = (UILabel *) [cell viewWithTag:1];
    UILabel *djLabel = (UILabel *) [cell viewWithTag:2];
    UILabel *listenersLabel = (UILabel *) [cell viewWithTag:3];
    UILabel *dateLabel = (UILabel *) [cell viewWithTag:6];

    if (!([channel.nam length] == 0)) {
        titleLabel.text = channel.nam;
    } else {
        titleLabel.text = @"";
    }
    if (!([channel.dj length] == 0)) {
        djLabel.text = channel.dj;
    } else {
        djLabel.text = @"";
    }
    if (channel.cln != CHANNEL_UNKNOWN_LISTENER_NUM) {
        listenersLabel.text = [[NSString alloc] initWithFormat:@"%d", channel.cln];
    } else {
        listenersLabel.text = @"";
    }

    NSInteger diffTime = (NSInteger)[[NSDate date] timeIntervalSinceDate:channel.tims];
    NSInteger diffDay = diffTime / (24 * 60 * 60);
    NSInteger diffHour = (diffTime % (24 * 60 * 60)) / (60 * 60);
    NSInteger diffMin = (diffTime % (60 * 60)) / 60;
    // 1分未満
    if (diffDay < 1 && diffHour < 1 && diffMin < 1) {
        dateLabel.text = [[NSString alloc] initWithFormat:NSLocalizedString(@"%dmin", @"分"), 1];
    }
    // 1日以上前
    else if (diffDay >= 1) {
        NSString *daySuffix;
        if (diffDay == 1) {
            daySuffix = NSLocalizedString(@"%dday", @"日");
        } else {
            daySuffix = NSLocalizedString(@"%ddays", @"日");
        }
        dateLabel.text = [[NSString alloc] initWithFormat:daySuffix, diffDay];
    } else {
        NSString *diffTimeString = @"";
        if (diffHour >= 1) {
            NSString *hourSuffix;
            if (diffHour == 1) {
                hourSuffix = NSLocalizedString(@"%dhr ", @"時間");
            } else {
                hourSuffix = NSLocalizedString(@"%dhrs ", @"時間");
            }
            diffTimeString = [[NSString alloc] initWithFormat:hourSuffix, diffHour];
        }

        if (diffMin >= 1) {
            NSString *minSuffix;
            if (diffMin == 1) {
                minSuffix = NSLocalizedString(@"%dmin", @"分");
            } else {
                minSuffix = NSLocalizedString(@"%dmins", @"分");
            }
            NSString *diffMinStr = [[NSString alloc] initWithFormat:minSuffix, diffMin];
            diffTimeString = [[NSString alloc] initWithFormat:@"%@%@", diffTimeString, diffMinStr];
        }
        dateLabel.text = diffTimeString;
    }

    // テーブルセルのテキスト等の色を変える
    titleLabel.textColor = HEADLINE_CELL_TITLE_TEXT_COLOR;
    titleLabel.highlightedTextColor = HEADLINE_CELL_TITLE_TEXT_SELECTED_COLOR;
    
    djLabel.textColor = HEADLINE_CELL_DJ_TEXT_COLOR;
    djLabel.highlightedTextColor = HEADLINE_CELL_DJ_TEXT_SELECTED_COLOR;
    
    listenersLabel.textColor = HEADLINE_CELL_LISTENERS_TEXT_COLOR;
    listenersLabel.highlightedTextColor = HEADLINE_CELL_LISTENERS_TEXT_SELECTED_COLOR;
    
    dateLabel.layer.cornerRadius = HEADLINE_CELL_DATE_CORNER_RADIUS;
    dateLabel.clipsToBounds = YES;
    dateLabel.backgroundColor = [self dateLabelBackgroundColor:channel.tims];
    dateLabel.textColor = HEADLINE_CELL_DATE_TEXT_COLOR;
    dateLabel.highlightedTextColor = HEADLINE_CELL_DATE_TEXT_SELECTED_COLOR;
    
    UIImageView *playImageView = (UIImageView *) [cell viewWithTag:4];
    playImageView.hidden = ![[Player sharedInstance] isPlaying:[channel playUrl]];
    
    UIImageView *favoriteImageView = (UIImageView *) [cell viewWithTag:5];
    favoriteImageView.hidden = !channel.favorite;

    return cell;
}

#pragma mark - UITableViewDelegate methods

-  (void)tableView:(UITableView *)tableView
   willDisplayCell:(UITableViewCell *)cell
 forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // テーブルセルの背景の色を変える
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = HEADLINE_TABLE_CELL_BACKGROUND_COLOR_DARK;
    } else {
        cell.backgroundColor = HEADLINE_TABLE_CELL_BACKGROUND_COLOR_LIGHT;
    }

    // テーブルセルの選択色を変える
    UIView *selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = HEADLINE_CELL_SELECTED_BACKGROUND_COLOR;
    cell.selectedBackgroundView = selectedBackgroundView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"SelectChannel" sender:self];
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // EGOTableViewPullRefreshに必要
    [refreshHeaderView_ egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // EGOTableViewPullRefreshに必要
    [refreshHeaderView_ egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView *)view
{
    [self fetchHeadline];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView *)view
{
    // should return if data source model is reloading
    return [[Headline sharedInstance] isFetchingHeadline];
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView *)view
{
    return [NSDate date]; // should return date data source was last changed
}

#pragma mark - ADBannerViewDelegate methods

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    if (HEADLINE_VIEW_IAD_ENABLE) {
        // 広告をはいつでも表示可能
        return YES;
    } else {
        return NO;
    }
}

// iADバナーが読み込み終わった
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"iAD banner load complated.");

    if (isVisibleAdBanner_ == NO) {
        ADBannerView *adBannerView = [IAdBannerManager sharedInstance].adBannerView;
        adBannerView.hidden = NO;
        [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut 
                         animations:^{
                             adBannerView.frame = CGRectMake(0, 317, 320, 50);
                         }
                         completion:^(BOOL finished) {
                             if (finished) {
                                 headlineTableView_.frame = CGRectMake(0, 44, 320, 273);
                             }
                         }];
        isVisibleAdBanner_ = YES;
    }
}

// iADバナーの読み込みに失敗
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"Received iAD banner error. Error : %@", [error localizedDescription]);

    if (isVisibleAdBanner_) {
        ADBannerView *adBannerView = [IAdBannerManager sharedInstance].adBannerView;
        headlineTableView_.frame = CGRectMake(0, 44, 320, 323);
        [UIView animateWithDuration:AD_VIEW_ANIMATION_DURATION
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut 
                         animations:^{
                             adBannerView.frame = CGRectMake(0, 377, 320, 50);
                         }
                         completion:nil];
        isVisibleAdBanner_ = NO;
    }
}

#pragma mark - Headline notifications

- (void)headlineDidStartLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update started notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */
    
    // ヘッドラインの取得開始時に更新ボタンを無効にする
    [self updateUpdateBarButton];
}

- (void)headlineDidFinishLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update suceed notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    // ヘッドラインの取得終了時に更新ボタンを有効にする
    [self updateUpdateBarButton];

    if (PULL_REFRESH_HEADLINE) {
        // Pull refreshを終了する
        [refreshHeaderView_ egoRefreshScrollViewDataSourceDidFinishedLoading:headlineTableView_];
    }
}

- (void)headlineFailLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update faild notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    // ヘッドラインの取得終了時に更新ボタンを有効にする
    [self updateUpdateBarButton];

    if (PULL_REFRESH_HEADLINE) {
        // Pull refreshを終了する
        [refreshHeaderView_ egoRefreshScrollViewDataSourceDidFinishedLoading:headlineTableView_];
    }
}

- (void)headlineChannelChanged:(NSNotification *)notification
{
    // ヘッドラインテーブルを更新する
    [self updateHeadlineTable];
}


#pragma mark - Player notifications

- (void)playStateChanged:(NSNotification *)notification
{
    [self updatePlayingButton];
    [self updateHeadlineTable];

    if (SCROLL_TO_TOP_AT_PLAYING_CHANNEL_CELL) {
        // 再生が開始した際に、再生している番組をテーブルの一番上になるようにスクロールする
        if ([[Player sharedInstance] state] == PlayerStatePlay) {
            [self scrollToTopAtPlayingCell];
        }
    }
}

@end
