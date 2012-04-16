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

#import "SVProgressHUD/SVProgressHUD.h"
#import "FBNetworkReachability/FBNetworkReachability.h"
#import "LadioLib/LadioLib.h"
#import "SearchWordManager.h"
#import "Player.h"
#import "ChannelViewController.h"
#import "HeadlineViewController.h"

/// 更新ボタンの色
#define UPDATE_BUTTON_COLOR [UIColor darkGrayColor]
/// 戻るボタンの色
#define BACK_BUTTON_COLOR [UIColor darkGrayColor]
/// 再生中ボタンの色
#define PLAYING_BUTTON_COLOR [[UIColor alloc]initWithRed:(191 / 255.0) green:(126 / 255.0) blue:(0 / 255.0) alpha:1]
/// 検索バーの色
#define SEARCH_BAR_COLOR [UIColor colorWithRed:(10 / 255.0) green:(10 / 255.0) blue:(10 / 255.0) alpha:1]
/// テーブルの背景の色
#define HEADLINE_TABLE_BACKGROUND_COLOR [[UIColor alloc]initWithRed:(40 / 255.0) green:(40 / 255.0) blue:(40 / 255.0) alpha:1]
/// テーブルの境界線の色
#define HEADLINE_TABLE_SEPARATOR_COLOR [[UIColor alloc]initWithRed:(75 / 255.0) green:(75 / 255.0) blue:(75 / 255.0) alpha:1]
/// テーブルセルの暗い側の色
#define HEADLINE_TABLE_CELL_BACKGROUND_COLOR_DARK [[UIColor alloc]initWithRed:(40 / 255.0) green:(40 / 255.0) blue:(40 / 255.0) alpha:1]
/// テーブルセルの明るい側の色
#define HEADLINE_TABLE_CELL_BACKGROUND_COLOR_LIGHT [[UIColor alloc]initWithRed:(60 / 255.0) green:(60 / 255.0) blue:(60 / 255.0) alpha:1]
/// テーブルセルのタイトルのテキストカラー
#define HEADLINE_CELL_TITLE_TEXT_COLOR [UIColor whiteColor]
/// テーブルセルのDJのテキストカラー
#define HEADLINE_CELL_DJ_TEXT_COLOR [[UIColor alloc]initWithRed:(255 / 255.0) green:(190 / 255.0) blue:(30 / 255.0) alpha:1]
/// テーブルセルのリスナー数のテキストカラー
#define HEADLINE_CELL_LISTENERS_TEXT_COLOR [UIColor whiteColor]
/// テーブルセルの選択の色
#define HEADLINE_CELL_SELECTED_BACKGROUND_COLOR [[UIColor alloc]initWithRed:(255 / 255.0) green:(190 / 255.0) blue:(30 / 255.0) alpha:1]
/// テーブルセルのタイトルのテキスト選択時カラー
#define HEADLINE_CELL_TITLE_TEXT_SELECTED_COLOR [UIColor blackColor]
/// テーブルセルのDJのテキスト選択時カラー
#define HEADLINE_CELL_DJ_TEXT_SELECTED_COLOR [UIColor blackColor]
/// テーブルセルのリスナー数のテキスト選択時カラー
#define HEADLINE_CELL_LISTENERS_TEXT_SELECTED_COLOR [UIColor blackColor]

/// ヘッドライン取得失敗時にエラーを表示する秒数
#define DELAY_FETCH_HEADLINE_MESSAGE 3

@implementation HeadlineViewController
{
@private
    /// テーブルに表示している番組
    NSArray *showedChannels;

    /// 再生中ボタンのインスタンスを一時的に格納しておく領域
    UIBarButtonItem *tempPlayingBarButtonItem;
}

@synthesize navigateionItem;
@synthesize updateBarButtonItem;
@synthesize playingBarButtonItem;
@synthesize headlineSearchBar;
@synthesize headlineTableView;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // ヘッドラインの取得開始と終了をハンドリングし、ヘッドライン更新ボタンの有効無効の切り替えや
    // テーブル更新を行う
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(fetchHeadlineStarted:)
     name:NOTIFICATION_NAME_FETCH_HEADLINE_STARTED
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(fetchHeadlineSuceed:)
     name:NOTIFICATION_NAME_FETCH_HEADLINE_SUCEED
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(fetchHeadlineFailed:)
     name:NOTIFICATION_NAME_FETCH_HEADLINE_FAILED
     object:nil];
#ifdef DEBUG
    NSLog(@"%@ registed headline update notifications.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    // 番組画面からの戻るボタンのテキストと色を書き換える
    NSString *backButtonStr = NSLocalizedString(@"ON AIR", @"番組一覧にトップに表示されるONAIR 番組が無い場合/番組画面から戻るボタン");
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc]
                                       initWithTitle:backButtonStr
                                       style:UIBarButtonItemStyleBordered
                                       target:nil action:nil];
    backButtonItem.tintColor = BACK_BUTTON_COLOR;
    self.navigationItem.backBarButtonItem = backButtonItem;

    // 更新ボタンの色を変更する
    updateBarButtonItem.tintColor = UPDATE_BUTTON_COLOR;

    // 再生中ボタンの装飾を変更する
    playingBarButtonItem.title = NSLocalizedString(@"Playing", @"再生中ボタン");
    playingBarButtonItem.tintColor = PLAYING_BUTTON_COLOR;
    // 再生中ボタンを保持する
    tempPlayingBarButtonItem = playingBarButtonItem;
    // 再生状態に逢わせて再生ボタンの表示を切り替える
    [self updatePlayingButton];

    // 検索バーの色を変える
    headlineSearchBar.tintColor = SEARCH_BAR_COLOR;

    // 検索バーが空でもサーチキーを押せるようにする
    // http://stackoverflow.com/questions/3846917/iphone-uisearchbar-how-to-search-for-string
    for (UIView *subview in headlineSearchBar.subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            ((UITextField *) subview).enablesReturnKeyAutomatically = NO;
            break;
        }
    }

    // 再生状態が切り替わるごとに再生ボタンの表示を切り替える
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(playStateChanged:)
     name:NOTIFICATION_NAME_PLAY_STATE_CHANGED
     object:nil];

    // テーブルの背景の色を変える
    headlineTableView.backgroundColor = HEADLINE_TABLE_BACKGROUND_COLOR;
    // テーブルの境界線の色を変える
    headlineTableView.separatorColor = HEADLINE_TABLE_SEPARATOR_COLOR;
}

- (void)viewDidUnload
{
    showedChannels = nil;
    tempPlayingBarButtonItem = nil;

    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:NOTIFICATION_NAME_FETCH_HEADLINE_STARTED
     object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:NOTIFICATION_NAME_FETCH_HEADLINE_SUCEED
     object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:NOTIFICATION_NAME_FETCH_HEADLINE_FAILED
     object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:NOTIFICATION_NAME_PLAY_STATE_CHANGED
     object:nil];
#ifdef DEBUG
    NSLog(@"%@ unregisted headline update notifications.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    [self setUpdateBarButtonItem:nil];
    [self setNavigateionItem:nil];
    [self setPlayingBarButtonItem:nil];
    [self setHeadlineSearchBar:nil];
    [self setHeadlineTableView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    // タブの切り替えごとにヘッドラインテーブルを更新する
    // 別タブで更新したヘッドラインをこのタブのテーブルでも使うため
    [self updateHeadlineTable];

    // タブの切り替えごとに検索バーを更新する
    // 別タブで入力した検索バーのテキストをこのタブでも使うため
    NSString *searchWord = [SearchWordManager sharedInstance].searchWord;
    if (searchWord == nil) {
        searchWord = @"";
    }
    headlineSearchBar.text = searchWord;

    // viewWillAppear:animated はsuperを呼び出す必要有り
    // テーブルの更新前に呼ぶらしい
    // http://d.hatena.ne.jp/kimada/20090917/1253187128
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // リモコン対応
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];

    // ネットワークが接続済みの場合で、かつ番組表を取得していない場合
    if ([FBNetworkReachability sharedInstance].reachable && [[Headline sharedInstance] getChannels] == 0) {
        // 番組表を取得する
        // 進捗ウィンドウを正しく表示させるため、viewDidAppear:animated で番組表を取得する
        [self fetchHeadline];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
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
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [showedChannels count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Channel *channel = (Channel *) [showedChannels objectAtIndex:indexPath.row];

    NSString *cellIdentifier;

    // タイトルのみが存在する場合
    if (!([channel.nam length] == 0) && ([channel.dj length] == 0)) {
        cellIdentifier = @"ChannelTitleOnlyCell";
    }
    // DJのみが存在する場合
    else if (([channel.nam length] == 0) && !([channel.dj length] == 0)) {
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
    UIImageView *playImageView = (UIImageView *) [cell viewWithTag:4];
    UIImageView *favoriteImageView = (UIImageView *) [cell viewWithTag:5];

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

    playImageView.hidden = ![[Player sharedInstance] isPlaying:[channel getPlayUrl]];
    favoriteImageView.hidden = !channel.favorite;

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // テーブルセルの背景の色を変える
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = HEADLINE_TABLE_CELL_BACKGROUND_COLOR_DARK;
    } else {
        cell.backgroundColor = HEADLINE_TABLE_CELL_BACKGROUND_COLOR_LIGHT;
    }

    // テーブルセルのテキストの色を変える
    UILabel *titleLabel = (UILabel *) [cell viewWithTag:1];
    UILabel *djLabel = (UILabel *) [cell viewWithTag:2];
    UILabel *listenersLabel = (UILabel *) [cell viewWithTag:3];
    titleLabel.textColor = HEADLINE_CELL_TITLE_TEXT_COLOR;
    djLabel.textColor = HEADLINE_CELL_DJ_TEXT_COLOR;
    listenersLabel.textColor = HEADLINE_CELL_LISTENERS_TEXT_COLOR;

    // テーブルセルの選択時の色を変える
    titleLabel.highlightedTextColor = HEADLINE_CELL_TITLE_TEXT_SELECTED_COLOR;
    djLabel.highlightedTextColor = HEADLINE_CELL_DJ_TEXT_SELECTED_COLOR;
    listenersLabel.highlightedTextColor = HEADLINE_CELL_LISTENERS_TEXT_SELECTED_COLOR;

    // テーブルセルの選択色を変える
    UIView *selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = HEADLINE_CELL_SELECTED_BACKGROUND_COLOR;
    cell.selectedBackgroundView = selectedBackgroundView;
}

// StoryBoard上でセルの高さを設定しても有効にならないので、ここで高さを設定する
// http://blog.suz-lab.com/2010/03/uitableviewcell.html
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54.0;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // テーブルから番組を選択した
    if ([[segue identifier] isEqualToString:@"SelectChannel"]) {
        // 番組情報を繊維先のViewに設定
        UIViewController *viewCon = [segue destinationViewController];
        if ([viewCon isKindOfClass:[ChannelViewController class]]) {
            Channel *channel = [showedChannels objectAtIndex:[headlineTableView indexPathForSelectedRow].row];
            ((ChannelViewController *) viewCon).channel = channel;
        }
    }
    // 再生中ボタンを選択した
    else if ([[segue identifier] isEqualToString:@"PlayingChannel"]) {
        // 番組情報を繊維先のViewに設定
        UIViewController *viewCon = [segue destinationViewController];
        if ([viewCon isKindOfClass:[ChannelViewController class]]) {
            NSURL *playingUrl = [[Player sharedInstance] getPlayUrl];
            Headline *headline = [Headline sharedInstance];
            Channel *channel = [headline getChannel:playingUrl];
            ((ChannelViewController *) viewCon).channel = channel;
        }
    }
}

- (void)remoteControlReceivedWithEvent:(UIEvent*)event
{
    // リモコンからのボタンクリック
    [[Player sharedInstance] playFromRemoteControl:event];
}

- (void)fetchHeadlineStarted:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update started notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    // 進捗ウィンドウを表示する
    [SVProgressHUD show];

    // ヘッドラインの取得開始時に更新ボタンを無効にする
    updateBarButtonItem.enabled = NO;

    // ヘッドラインテーブルを更新する
    [self updateHeadlineTable];
}

- (void)fetchHeadlineSuceed:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update suceed notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    // ヘッドラインの取得終了時に更新ボタンを有効にする
    updateBarButtonItem.enabled = YES;

    // ヘッドラインテーブルを更新する
    [self updateHeadlineTable];

    // 進捗ウィンドウを消す
    [SVProgressHUD dismiss];
}

- (void)fetchHeadlineFailed:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update faild notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    // ヘッドラインの取得終了時に更新ボタンを有効にする
    updateBarButtonItem.enabled = YES;

    // ヘッドラインテーブルを更新する
    [self updateHeadlineTable];

    // 進捗ウィンドウにエラー表示
    NSString *errorStr = NSLocalizedString(@"Channel information could not be obtained.", @"番組表の取得に失敗");
    [SVProgressHUD dismissWithError:errorStr afterDelay:DELAY_FETCH_HEADLINE_MESSAGE];
}

- (void)playStateChanged:(NSNotification *)notification
{
    [self updatePlayingButton];
}

- (ChannelSortType)getSortType
{
    return ChannelSortTypeNone;
}

- (void)fetchHeadline
{
    Headline *headline = [Headline sharedInstance];
    [headline fetchHeadline];
}

- (void)updateHeadlineTable
{
    Headline *headline = [Headline sharedInstance];
    showedChannels = [headline getChannels:self.getSortType searchWord:[SearchWordManager sharedInstance].searchWord];

    // ナビゲーションタイトルを更新
    NSString *navigationTitleStr = @"";
    if ([showedChannels count] == 0) {
        navigationTitleStr = NSLocalizedString(@"ON AIR", @"番組一覧にトップに表示されるONAIR 番組が無い場合/番組画面から戻るボタン");
    } else {
        navigationTitleStr = NSLocalizedString(@"ON AIR %dch", @"番組一覧にトップに表示されるONAIR 番組がある場合");
    }
    navigateionItem.title = [[NSString alloc] initWithFormat:navigationTitleStr, [showedChannels count]];

    // ヘッドラインテーブルを更新
    [self.headlineTableView reloadData];
}

- (void)updatePlayingButton
{
    // 再生状態に逢わせて再生ボタンの表示を切り替える
    if ([[Player sharedInstance] getState] == PlayerStatePlay) {
        self.navigationItem.rightBarButtonItem = tempPlayingBarButtonItem;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (IBAction)update:(id)sender
{
    [self fetchHeadline];
}

@end
