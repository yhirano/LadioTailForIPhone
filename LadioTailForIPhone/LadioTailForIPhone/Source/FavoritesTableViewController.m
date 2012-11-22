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
#import "RadioLib/RadioLib.h"
#import "LadioTailConfig.h"
#import "Player.h"
#import "ICloudStrorage.h"
#import "FavoriteViewController.h"
#import "FavoritesTableViewController.h"

@implementation FavoritesTableViewController
{
@private
    NSMutableArray *favorites_;
}

- (void)dealloc
{
    favorites_ = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LadioTailICloudStorageChangedFavoritesNotification
                                                  object:nil];
}

#pragma mark - Private methods

/// お気に入りとfavorites_の内容を同期する
- (void)updateFavolitesArray
{
    // お気に入りを取得し、新しい順にならべてfavorites_に格納
    NSDictionary *favoritesGlobal = [FavoriteManager sharedInstance].favorites;
    favorites_ = [[NSMutableArray alloc] initWithCapacity:[favoritesGlobal count]];
    NSArray *sortedKeyList = [favoritesGlobal keysSortedByValueUsingSelector:@selector(compareNewly:)];
    for (NSString *key in sortedKeyList) {
        [favorites_ addObject:favoritesGlobal[key]];
    }
}

#pragma mark - UIView methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 番組のお気に入りの変化通知を受け取る
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(channelFavoritesChanged:)
                                                 name:LadioTailICloudStorageChangedFavoritesNotification
                                               object:nil];

    [self updateFavolitesArray];

    self.navigationItem.title = NSLocalizedString(@"Favorites", @"お気に入り 複数");

    // メニューボタンの色を変更する
    _sideMenuBarButtonItem.tintColor = SIDEMENU_BUTTON_COLOR;

    // Preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
 
    // Display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    // StoryBoard上でセルの高さを設定しても有効にならないので、ここで高さを設定する
    // http://stackoverflow.com/questions/7214739/uitableview-cells-height-is-not-working-in-a-empty-table
    self.tableView.rowHeight = 54;
    // テーブルの背景の色を変える
    self.tableView.backgroundColor = FAVORITES_TABLE_BACKGROUND_COLOR;
    // テーブルの境界線の色を変える
    self.tableView.separatorColor = FAVORITES_TABLE_SEPARATOR_COLOR;

    // 番組画面からの戻るボタンのテキストと色を書き換える
    NSString *backButtonString = NSLocalizedString(@"Favorites", @"お気に入り 複数");
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:backButtonString
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
    backButtonItem.tintColor = BACK_BUTTON_COLOR;
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
    // テーブルからお気に入りを選択した
    if ([[segue identifier] isEqualToString:@"SelectFavorite"]) {
        // お気に入り情報を遷移先のViewに設定
        UIViewController *viewCon = [segue destinationViewController];
        if ([viewCon isKindOfClass:[FavoriteViewController class]]) {
            NSInteger favoriteIndex = [self.tableView indexPathForSelectedRow].row;
            Favorite *favorite = favorites_[favoriteIndex];
            ((FavoriteViewController *) viewCon).favorite = favorite;
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
    return [favorites_ count];
}

#if defined(LADIO_TAIL)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Favorite *favorite = (Favorite *)favorites_[indexPath.row];
    Headline *headline = [Headline sharedInstance];
    Player *player = [Player sharedInstance];
    Channel *channel = favorite.channel;
    
    NSString *cellIdentifier;
    
    // タイトルとDJが存在する場合
    if (!([channel.nam length] == 0) && !([channel.dj length] == 0)) {
        cellIdentifier = @"FavoriteCell";
    }
    // タイトルのみが存在する場合
    else if (!([channel.nam length] == 0) && [channel.dj length] == 0) {
        cellIdentifier = @"FavoriteTitleOnlyCell";
    }
    // DJのみが存在する場合
    else if ([channel.nam length] == 0 && !([channel.dj length] == 0)) {
        cellIdentifier = @"FavoriteDjOnlyCell";
    } else {
        cellIdentifier = @"FavoriteMountOnlyCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    UILabel *titleLabel = (UILabel *) [cell viewWithTag:1];
    UILabel *djLabel = (UILabel *) [cell viewWithTag:2];
    UILabel *mountTagLabel = (UILabel *) [cell viewWithTag:3];
    UILabel *mountLabel = (UILabel *) [cell viewWithTag:4];
    UIImageView *broadcastImageView = (UIImageView *) [cell viewWithTag:5];
    
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
    mountTagLabel.text = NSLocalizedString(@"Mount", @"マウント");
    if (!([channel.mnt length] == 0)) {
        mountLabel.text = channel.mnt;
    } else {
        mountLabel.text = @"";
    }
    // 再生中
    if ([[player playingChannel] isSameMount:channel]) {
        broadcastImageView.hidden = NO;
        [broadcastImageView setImage:[UIImage imageNamed:@"tablecell_play_white.png"]];
        [broadcastImageView setHighlightedImage:[UIImage imageNamed:@"tablecell_play_black.png"]];
    }
    // 配信中
    else if ([headline channelFromMount:channel.mnt] != nil) {
        broadcastImageView.hidden = NO;
        [broadcastImageView setImage:[UIImage imageNamed:@"tablecell_broadcast_white.png"]];
        [broadcastImageView setHighlightedImage:[UIImage imageNamed:@"tablecell_broadcast_black.png"]];
    }
    // 配信されていない
    else {
        broadcastImageView.hidden = YES;
    }
    
    
    // テーブルセルのテキスト等の色を変える
    titleLabel.textColor = FAVORITES_CELL_MAIN_TEXT_COLOR;
    titleLabel.highlightedTextColor = FAVORITES_CELL_MAIN_TEXT_SELECTED_COLOR;
    
    djLabel.textColor = FAVORITES_CELL_SUB_TEXT_COLOR;
    djLabel.highlightedTextColor = FAVORITES_CELL_SUB_TEXT_SELECTED_COLOR;
    
    mountTagLabel.textColor = FAVORITES_CELL_TAG_TEXT_COLOR;
    mountTagLabel.highlightedTextColor = FAVORITES_CELL_TAG_TEXT_SELECTED_COLOR;
    
    mountLabel.textColor = FAVORITES_CELL_MAIN_TEXT_COLOR;
    mountLabel.highlightedTextColor = FAVORITES_CELL_MAIN_TEXT_SELECTED_COLOR;
    
    return cell;
}
#elif defined(RADIO_EDGE)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Favorite *favorite = (Favorite *)favorites_[indexPath.row];
    Headline *headline = [Headline sharedInstance];
    Player *player = [Player sharedInstance];
    Channel *channel = favorite.channel;
    
    NSString *cellIdentifier;
    
    // Server NameとGenreが存在する場合
    if (!([channel.serverName length] == 0) && !([channel.genre length] == 0)) {
        cellIdentifier = @"FavoriteCell";
    }
    // Server Nameのみが存在する場合
    else if (!([channel.serverName length] == 0) && [channel.genre length] == 0) {
        cellIdentifier = @"FavoriteTitleOnlyCell";
    }
    // Genreのみが存在する場合
    else if ([channel.serverName length] == 0 && !([channel.genre length] == 0)) {
        cellIdentifier = @"FavoriteDjOnlyCell";
    } else {
        cellIdentifier = @"FavoriteCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    UILabel *serverNameLabel = (UILabel *) [cell viewWithTag:1];
    UILabel *genreLabel = (UILabel *) [cell viewWithTag:2];
    UIImageView *broadcastImageView = (UIImageView *) [cell viewWithTag:5];
    
    if (!([channel.serverName length] == 0)) {
        serverNameLabel.text = channel.serverName;
    } else {
        serverNameLabel.text = @"";
    }
    if (!([channel.genre length] == 0)) {
        genreLabel.text = channel.genre;
    } else {
        genreLabel.text = @"";
    }
    // 再生中
    if ([[player playingChannel] isSameListenUrl:channel]) {
        broadcastImageView.hidden = NO;
        [broadcastImageView setImage:[UIImage imageNamed:@"tablecell_play_white.png"]];
        [broadcastImageView setHighlightedImage:[UIImage imageNamed:@"tablecell_play_black.png"]];
    }
    // 配信中
    else if ([headline channelFromListenUrl:channel.listenUrl] != nil) {
        broadcastImageView.hidden = NO;
        [broadcastImageView setImage:[UIImage imageNamed:@"tablecell_broadcast_white.png"]];
        [broadcastImageView setHighlightedImage:[UIImage imageNamed:@"tablecell_broadcast_black.png"]];
    }
    // 配信されていない
    else {
        broadcastImageView.hidden = YES;
    }
    
    
    // テーブルセルのテキスト等の色を変える
    serverNameLabel.textColor = FAVORITES_CELL_MAIN_TEXT_COLOR;
    serverNameLabel.highlightedTextColor = FAVORITES_CELL_MAIN_TEXT_SELECTED_COLOR;
    
    genreLabel.textColor = FAVORITES_CELL_SUB_TEXT_COLOR;
    genreLabel.highlightedTextColor = FAVORITES_CELL_SUB_TEXT_SELECTED_COLOR;

    return cell;
}
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif

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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // すべて削除可能
    return YES;
}

-   (void)tableView:(UITableView *)tableView
 commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
  forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Favorite *removeFavorite = (Favorite *)favorites_[indexPath.row];
        Channel *removeChannel = removeFavorite.channel;
        [[FavoriteManager sharedInstance] removeFavorite:removeChannel];
        
        [self updateFavolitesArray];

        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"SelectFavorite" sender:self];
}

#pragma mark - iCloud notification

- (void)channelFavoritesChanged:(NSNotification *)notification
{
    // iCloudとお気に入りが同期した際はいったん編集モードを解除する
    // 編集モード中にお気に入りが増減するのはマズいため
    [self setEditing:NO];

    [self updateFavolitesArray];
    [self.tableView reloadData];
}

@end
