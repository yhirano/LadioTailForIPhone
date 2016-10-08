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
#import "RadioLib/RadioLib.h"
#import "Views/FavoriteTableViewCell.h"
#import "LadioTailConfig.h"
#import "Player.h"
#import "ICloudStorage.h"
#import "FavoriteViewController.h"
#import "FavoritesTableViewController.h"

@implementation FavoritesTableViewController
{
    NSMutableArray<Favorite*> *favorites_;
    UITextField *addFavoriteTextField_;
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
    NSDictionary<NSString*, Favorite*> *favoritesGlobal = [FavoriteManager sharedInstance].favorites;
    favorites_ = [[NSMutableArray alloc] initWithCapacity:[favoritesGlobal count]];
    NSArray<NSString*> *sortedKeyList = [favoritesGlobal keysSortedByValueUsingSelector:@selector(compareNewly:)];
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

    // Accessibility
    _sideMenuBarButtonItem.accessibilityLabel = NSLocalizedString(@"Main menu", @"メインメニューボタン");
    _sideMenuBarButtonItem.accessibilityHint = NSLocalizedString(@"Open the main menu", @"メインメニューを開く");

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

    // 番組画面からの戻るボタンのテキストを書き換える
    NSString *backButtonString = NSLocalizedString(@"Favorites", @"お気に入り 複数");
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
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
#if defined(LADIO_TAIL)
    return [favorites_ count] + 1; // 追加セルを足す
#elif defined(RADIO_EDGE)
    return [favorites_ count];
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif
}

#if defined(LADIO_TAIL)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;

    // Add Favorite
    if (indexPath.row == [favorites_ count]) {
        NSString *cellIdentifier = @"AddFavoriteCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }

        UILabel *addFavoriteLabel = (UILabel *) [cell viewWithTag:2];
        addFavoriteLabel.text = NSLocalizedString(@"Add Favorite", @"お気に入り追加");
        addFavoriteLabel.textColor = FAVORITES_CELL_MAIN_TEXT_COLOR;
        addFavoriteLabel.highlightedTextColor = FAVORITES_CELL_MAIN_TEXT_SELECTED_COLOR;
        [addFavoriteLabel sizeToFit];
        UIView *addFavoriteView = (UIView *) [cell viewWithTag:1];
        [addFavoriteView sizeToFit];
        addFavoriteView.center = cell.contentView.center;
    }
    // Favorite
    else {
        Favorite *favorite = (Favorite *)favorites_[indexPath.row];
        Headline *headline = [Headline sharedInstance];
        Player *player = [Player sharedInstance];
        Channel *channel = favorite.channel;
        
        NSMutableString *accessibilityLabel = [NSMutableString string];

        NSString *cellIdentifier;
        
        // タイトルかDJが存在する場合
        if (([channel.nam length] > 0) || ([channel.dj length] > 0)) {
            cellIdentifier = @"FavoriteCell";
        } else {
            cellIdentifier = @"FavoriteMountOnlyCell";
        }
        
        FavoriteTableViewCell *favoriteCell =
            (FavoriteTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (favoriteCell == nil) {
            favoriteCell = [[FavoriteTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                        reuseIdentifier:cellIdentifier];
        }
        
        UILabel *titleLabel = (UILabel *) [favoriteCell viewWithTag:1];
        UILabel *djLabel = (UILabel *) [favoriteCell viewWithTag:2];
        UILabel *mountTagLabel = (UILabel *) [favoriteCell viewWithTag:3];
        UILabel *mountLabel = (UILabel *) [favoriteCell viewWithTag:4];
        UIImageView *broadcastImageView = (UIImageView *) [favoriteCell viewWithTag:5];
        
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
        mountTagLabel.text = NSLocalizedString(@"Mount", @"マウント");
        if (mountLabel != nil && [channel.mnt length] > 0) {
            mountLabel.text = channel.mnt;
            [accessibilityLabel appendFormat:@" %@ %@", NSLocalizedString(@"Mount", @"マウント"), channel.mnt];
        } else {
            mountLabel.text = @"";
        }
        // 再生中
        if ([[player playingChannel] isSameMount:channel]) {
            broadcastImageView.hidden = NO;
            [broadcastImageView setImage:[UIImage imageNamed:@"tablecell_play_white"]];
            [broadcastImageView setHighlightedImage:[UIImage imageNamed:@"tablecell_play_black"]];
        }
        // 配信中
        else if ([headline channelFromMount:channel.mnt] != nil) {
            broadcastImageView.hidden = NO;
            [broadcastImageView setImage:[UIImage imageNamed:@"tablecell_broadcast_white"]];
            [broadcastImageView setHighlightedImage:[UIImage imageNamed:@"tablecell_broadcast_black"]];
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
        
        favoriteCell.accessibilityLabel = accessibilityLabel;
        favoriteCell.accessibilityHint = NSLocalizedString(@"Open the description view of this channel",
                                                           @"この番組の番組詳細画面を開く");

        cell = favoriteCell;
    }
    
    return cell;
}
#elif defined(RADIO_EDGE)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;

    // Add Favorite
    if (indexPath.row == [favorites_ count]) {
        NSString *cellIdentifier = @"AddFavoriteCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        
        UILabel *addFavoriteLabel = (UILabel *) [cell viewWithTag:1];
        addFavoriteLabel.text = NSLocalizedString(@"Add Favorite", @"お気に入り追加");
        addFavoriteLabel.textColor = FAVORITES_CELL_MAIN_TEXT_COLOR;
        addFavoriteLabel.highlightedTextColor = FAVORITES_CELL_MAIN_TEXT_SELECTED_COLOR;
        [addFavoriteLabel sizeToFit];
        UIView *addFavoriteView = (UIView *) [cell viewWithTag:1];
        [addFavoriteView sizeToFit];
        addFavoriteView.center = cell.center;
    }
    // Favorite
    else {
        Favorite *favorite = (Favorite *)favorites_[indexPath.row];
        Headline *headline = [Headline sharedInstance];
        Player *player = [Player sharedInstance];
        Channel *channel = favorite.channel;
        
        NSMutableString *accessibilityLabel = [NSMutableString string];

        NSString *cellIdentifier = @"FavoriteCell";
        
        FavoriteTableViewCell *favoriteCell =
            (FavoriteTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (favoriteCell == nil) {
            favoriteCell = [[FavoriteTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                        reuseIdentifier:cellIdentifier];
        }
        
        UILabel *serverNameLabel = (UILabel *) [favoriteCell viewWithTag:1];
        UILabel *genreLabel = (UILabel *) [favoriteCell viewWithTag:2];
        UIImageView *broadcastImageView = (UIImageView *) [favoriteCell viewWithTag:5];
        
        if ([channel.serverName length] > 0) {
            serverNameLabel.text = channel.serverName;
            [accessibilityLabel appendFormat:@" %@ %@", NSLocalizedString(@"Title", @"タイトル"), channel.serverName];
        } else {
            serverNameLabel.text = @"";
        }
        if ([channel.genre length] > 0) {
            genreLabel.text = channel.genre;
            [accessibilityLabel appendFormat:@" %@ %@", NSLocalizedString(@"Genre", @"ジャンル"), channel.genre];
        } else {
            genreLabel.text = @"";
        }
        // 再生中
        if ([[player playingChannel] isSameListenUrl:channel]) {
            broadcastImageView.hidden = NO;
            [broadcastImageView setImage:[UIImage imageNamed:@"tablecell_play_white"]];
            [broadcastImageView setHighlightedImage:[UIImage imageNamed:@"tablecell_play_black"]];
        }
        // 配信中
        else if ([headline channelFromListenUrl:channel.listenUrl] != nil) {
            broadcastImageView.hidden = NO;
            [broadcastImageView setImage:[UIImage imageNamed:@"tablecell_broadcast_white"]];
            [broadcastImageView setHighlightedImage:[UIImage imageNamed:@"tablecell_broadcast_black"]];
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

        favoriteCell.accessibilityLabel = accessibilityLabel;
        favoriteCell.accessibilityHint = NSLocalizedString(@"Open the description view of this channel",
                                                           @"この番組の番組詳細画面を開く");

        cell = favoriteCell;
    }

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
#if defined(LADIO_TAIL)
    // Add Favorite
    if (indexPath.row == [favorites_ count]) {
        return NO;
    }
    // お気に入りは削除可能
    else {
        return YES;
    }
#elif defined(RADIO_EDGE)
    // すべて削除可能
    return YES;
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
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
#if defined(LADIO_TAIL)
    // Add Favorite
    if (indexPath.row == [favorites_ count]) {
        // iOS8
        if (NSClassFromString(@"UIAlertController")) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Favorite", @"お気に入り追加")
                                                                           message:NSLocalizedString(@"Please enter the mount name.", @"お気に入りに追加するマウントを入力してください")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                addFavoriteTextField_ = textField;
            }];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"キャンセル")
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add", @"追加")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                                                        NSString *input = addFavoriteTextField_.text;
                                                        if (input.length <= 0) {
                                                            return;
                                                        }
                                                        
                                                        NSError *error = nil;
                                                        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"^(/*)(\\w*)"
                                                                                                                                    options:0
                                                                                                                                      error:&error];
                                                        if (error != nil) {
                                                            NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
                                                            return;
                                                        }
                                                        
                                                        NSString *mount = nil;
                                                        NSTextCheckingResult *match = [expression firstMatchInString:input
                                                                                                             options:0
                                                                                                               range:NSMakeRange(0, input.length)];
                                                        if (match.numberOfRanges >= 2) {
                                                            mount = [input substringWithRange:[match rangeAtIndex:2]];
                                                        }
                                                        if (mount.length > 0) {
                                                            // お気に入り登録
                                                            Channel *channel = [[Channel alloc] init];
                                                            channel.mnt = [[NSString alloc] initWithFormat:@"/%@", mount];
                                                            [channel setFavorite:YES];
                                                        }
                                                        
                                                        [self updateFavolitesArray];
                                                        [self.tableView reloadData];
                                                    }]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        // iOS7
        else {
            NSString* title = NSLocalizedString(@"Add Favorite", @"お気に入り追加");
            NSString* message = NSLocalizedString(@"Please enter the mount name.", @"お気に入りに追加するマウントを入力してください");
            NSString* cancel = NSLocalizedString(@"Cancel", @"キャンセル");
            NSString* add = NSLocalizedString(@"Add", @"追加");
            
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:title
                                                             message:message
                                                            delegate:self
                                                   cancelButtonTitle:cancel
                                                   otherButtonTitles:add, nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField *alertTextField = [alert textFieldAtIndex:0];
            alertTextField.keyboardType = UIKeyboardTypeASCIICapable;
            alertTextField.placeholder = @"/mountname";
            [alert show];
        }
    }
    // Select a favorite
    else {
        [self performSegueWithIdentifier:@"SelectFavorite" sender:self];
    }
#elif defined(RADIO_EDGE)
    [self performSegueWithIdentifier:@"SelectFavorite" sender:self];
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif
}

#pragma mark - UIAlertViewDelegate methods

#if defined(LADIO_TAIL)
- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0: // Cancel
            break;
        case 1: // Add
        {
            UITextField *alertTextField = [alertView textFieldAtIndex:0];
            NSString *input = alertTextField.text;
            if (input.length <= 0) {
                break;
            }
            
            NSError *error = nil;
            NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"^(/*)(\\w*)"
                                                                                        options:0
                                                                                          error:&error];
            if (error != nil) {
                NSLog(@"NSRegularExpression regularExpressionWithPattern. Error:%@", [error localizedDescription]);
                break;
            }
            
            NSString *mount = nil;
            NSTextCheckingResult *match = [expression firstMatchInString:input
                                                                 options:0
                                                                   range:NSMakeRange(0, input.length)];
            if (match.numberOfRanges >= 2) {
                mount = [input substringWithRange:[match rangeAtIndex:2]];
            }
            if (mount.length > 0) {
                // お気に入り登録
                Channel *channel = [[Channel alloc] init];
                channel.mnt = [[NSString alloc] initWithFormat:@"/%@", mount];
                [channel setFavorite:YES];
            }
            
            [self updateFavolitesArray];
            [self.tableView reloadData];
            break;
        }
        default:
            break;
    }
    
    // ハイライト解除
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}
#endif

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
