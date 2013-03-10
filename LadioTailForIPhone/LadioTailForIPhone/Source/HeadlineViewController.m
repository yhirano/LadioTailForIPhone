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

#import "EGOTableViewPullRefresh/EGORefreshTableHeaderView.h"
#import "FBNetworkReachability/FBNetworkReachability.h"
#import "ViewDeck/IIViewDeckController.h"
#import "Views/ChannelTableViewCell/ChannelTableViewCell.h"
#import "LadioTailConfig.h"
#import "Player.h"
#import "ChannelViewController.h"
#import "Views/AdViewCell/AdViewCell.h"
#import "HeadlineViewController.h"

/// 選択されたソート種類を覚えておくためのキー
#define SELECTED_CHANNEL_SORT_TYPE_INDEX @"SELECTED_CHANNEL_SORT_TYPE_INDEX"

typedef enum {
    HeadlineViewDisplayTypeOnlyTitleAndDj,
    HeadlineViewDisplayTypeElapsedTime,
    HeadlineViewDisplayTypeBitrate,
    HeadlineViewDisplayTypeElapsedTimeAndBitrate
} HeadlineViewDisplayType;

@interface HeadlineViewController () <UITableViewDelegate, UISearchBarDelegate, EGORefreshTableHeaderDelegate,
                                      IIViewDeckControllerDelegate, ChannelTableViewDelegate>

@end

@implementation HeadlineViewController
{
    /// ヘッドラインの表示方式
    NSInteger headlineViewDisplayType_;

    /// 検索ワード
    NSString *searchWord_;

    /// 再生中ボタンのインスタンスを一時的に格納しておく領域
    UIBarButtonItem *tempPlayingBarButtonItem_;

    /// PullRefreshView
    EGORefreshTableHeaderView *refreshHeaderView_;

    /// ViewDeckController
    IIViewDeckController *viewDeckController_;

    /// 広告セル
    AdViewCell *adViewCell_;
}

- (void)dealloc
{
    tempPlayingBarButtonItem_ = nil;

    viewDeckController_.delegate = nil;
    viewDeckController_ = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:RadioLibHeadlineDidStartLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RadioLibHeadlineDidFinishLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RadioLibHeadlineFailLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RadioLibHeadlineChannelChangedNotification object:nil];
#ifdef DEBUG
    NSLog(@"%@ unregisted headline update notifications.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidPlayNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidStopNotification object:nil];
}

- (void)setChannelSortType:(ChannelSortType)channelSortType
{
    if (_channelSortType == channelSortType) {
        return;
    }

    _channelSortType = channelSortType;

    // 選択されたソートタイプを保存しておく
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:_channelSortType forKey:SELECTED_CHANNEL_SORT_TYPE_INDEX];

    [self updateHeadlineTable];
}

- (void)fetchHeadline
{
    Headline *headline = [Headline sharedInstance];
    [headline fetchHeadline];
}

- (void)scrollToTopAnimated:(BOOL)animated
{
    NSInteger sectionNum = [_headlineTableView numberOfSections];
    NSInteger rowNum = [_headlineTableView numberOfRowsInSection:0];
    if (sectionNum > 0 && rowNum > 0) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [_headlineTableView scrollToRowAtIndexPath:indexPath
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:animated];
    }
}

#pragma mark - Private methods

#if defined(LADIO_TAIL)
- (UITableViewCell *)tableView:(UITableView *)tableView createChannelCell:(NSInteger)num
{
    Channel *channel = (Channel *) _showedChannels[num];
    
    NSString *cellIdentifier;
    
    switch (headlineViewDisplayType_) {
        case HeadlineViewDisplayTypeElapsedTime:
            cellIdentifier = @"ChannelCell_TitleAndDj_Time";
            break;
        case HeadlineViewDisplayTypeBitrate:
            cellIdentifier = @"ChannelCell_TitleAndDj_Bitrate";
            break;
        case HeadlineViewDisplayTypeOnlyTitleAndDj:
            cellIdentifier = @"ChannelCell_TitleAndDj";
            break;
        case HeadlineViewDisplayTypeElapsedTimeAndBitrate:
        default:
            cellIdentifier = @"ChannelCell_TitleAndDj_BitrateAndTime";
            break;
    }
    
    ChannelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[ChannelTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    UIImageView *headphoneImageView = (UIImageView *) [cell viewWithTag:1];
    UILabel *titleLabel = (UILabel *) [cell viewWithTag:2];
    UILabel *djLabel = (UILabel *) [cell viewWithTag:3];
    UILabel *listenersLabel = (UILabel *) [cell viewWithTag:4];
    UIImageView *playImageView = (UIImageView *) [cell viewWithTag:5];
    UIImageView *favoriteImageView = (UIImageView *) [cell viewWithTag:6];
    UILabel *dateLabel = (UILabel *) [cell viewWithTag:7];
    UILabel *bitrateLabel = (UILabel *) [cell viewWithTag:8];
    UIImageView *anchorImage = (UIImageView *) [cell viewWithTag:9];
    UILabel *anchorLabel = (UILabel *) [cell viewWithTag:10];
    UIView *swipeView = (UIView *) [cell viewWithTag:11];
    UIActivityIndicatorView *preparingIndicator = (UIActivityIndicatorView *) [cell viewWithTag:12];

    if ([channel isPlaySupported] == NO) {
        [headphoneImageView setImage:[UIImage imageNamed:@"tablecell_headphones_gray"]];
    } else {
        [headphoneImageView setImage:[UIImage imageNamed:@"tablecell_headphones_white"]];
    }

    if ([channel.nam length] > 0) {
        titleLabel.text = channel.nam;
    } else {
        titleLabel.text = @"";
    }
    if ([channel.dj length] > 0) {
        djLabel.text = channel.dj;
    } else {
        djLabel.text = @"";
    }
    if (channel.cln != CHANNEL_UNKNOWN_LISTENER_NUM) {
        listenersLabel.text = [[NSString alloc] initWithFormat:@"%d", channel.cln];
    } else {
        listenersLabel.text = @"";
    }
    if (dateLabel != nil && !dateLabel.hidden) {
        dateLabel.text = [[self class] dateText:channel.tims];
    }
    if (bitrateLabel != nil && !bitrateLabel.hidden) {
        bitrateLabel.text = [[self class] bitrateText:channel.bit];
    }
    
    // テーブルセルのテキスト等の色を変える
    titleLabel.textColor = HEADLINE_CELL_TITLE_TEXT_COLOR;
    titleLabel.highlightedTextColor = HEADLINE_CELL_TITLE_TEXT_SELECTED_COLOR;
    
    djLabel.textColor = HEADLINE_CELL_DJ_TEXT_COLOR;
    djLabel.highlightedTextColor = HEADLINE_CELL_DJ_TEXT_SELECTED_COLOR;
    
    listenersLabel.textColor = HEADLINE_CELL_LISTENERS_TEXT_COLOR;
    listenersLabel.highlightedTextColor = HEADLINE_CELL_LISTENERS_TEXT_SELECTED_COLOR;
    
    if (dateLabel != nil && !dateLabel.hidden) {
        dateLabel.backgroundColor = [UIColor colorWithPatternImage:[[self class] dateLabelBackgroundImage:channel.tims]];
        dateLabel.textColor = HEADLINE_CELL_DATE_TEXT_COLOR;
        dateLabel.highlightedTextColor = HEADLINE_CELL_DATE_TEXT_SELECTED_COLOR;
    }
    
    if (bitrateLabel != nil && !bitrateLabel.hidden) {
        bitrateLabel.backgroundColor = [UIColor colorWithPatternImage:[[self class] bitrateLabelBackgroundImage:channel.bit]];
        bitrateLabel.textColor = HEADLINE_CELL_BITRATE_TEXT_COLOR;
        bitrateLabel.highlightedTextColor = HEADLINE_CELL_BITRATE_TEXT_SELECTED_COLOR;
    }

    BOOL playing = [[Player sharedInstance] isPlaying:[channel playUrl]];
    playImageView.hidden = !playing;
    
    preparingIndicator.transform = CGAffineTransformMakeScale(0.725, 0.725); // Indicatorのサイズ変更
    preparingIndicator.center = playImageView.center; // 再生アイコンとIndicatorの中心をあわせる
    BOOL preparing = [[Player sharedInstance] isPreparing:[channel playUrl]];
    if (preparing) {
        [preparingIndicator startAnimating];
        preparingIndicator.hidden = NO;
    } else {
        [preparingIndicator stopAnimating];
        preparingIndicator.hidden = YES;
    }
    
    favoriteImageView.hidden = !channel.favorite;

    ChannelTableViewCell *channelCell = (ChannelTableViewCell *)cell;
    channelCell.swipeView = swipeView;

    anchorLabel.textColor = HEADLINE_CELL_PLAY_SWIPE_TEXT_COLOR;
    anchorLabel.highlightedTextColor = HEADLINE_CELL_PLAY_SWIPE_TEXT_COLOR;
    anchorLabel.text = @"";

    if (playing) {
        [anchorImage setImage:[UIImage imageNamed:@"tablecell_stop_black"]];
        [anchorImage setHighlightedImage:[UIImage imageNamed:@"tablecell_stop_black"]];
    } else if ([channel isPlaySupported] == NO) {
        [anchorImage setImage:[UIImage imageNamed:@"tablecell_notsupported_black"]];
        [anchorImage setHighlightedImage:[UIImage imageNamed:@"tablecell_notsupported_black"]];
    } else {
        [anchorImage setImage:[UIImage imageNamed:@"tablecell_play_black"]];
        [anchorImage setHighlightedImage:[UIImage imageNamed:@"tablecell_play_black"]];
    }

    return cell;
}
#elif defined(RADIO_EDGE)
- (UITableViewCell *)tableView:(UITableView *)tableView createChannelCell:(NSInteger)num
{
    Channel *channel = (Channel *) _showedChannels[num];
    
    NSString *cellIdentifier = @"ChannelCell_ServerNameAndGenre_Bitrate";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    UIImageView *headphoneImageView = (UIImageView *) [cell viewWithTag:1];
    UILabel *serverNameLabel = (UILabel *) [cell viewWithTag:2];
    UILabel *genreLabel = (UILabel *) [cell viewWithTag:3];
    UIImageView *playImageView = (UIImageView *) [cell viewWithTag:5];
    UIImageView *favoriteImageView = (UIImageView *) [cell viewWithTag:6];
    UILabel *bitrateLabel = (UILabel *) [cell viewWithTag:8];
    UIImageView *anchorImage = (UIImageView *) [cell viewWithTag:9];
    UILabel *anchorLabel = (UILabel *) [cell viewWithTag:10];
    UIView *swipeView = (UIView *) [cell viewWithTag:11];
    UIActivityIndicatorView *preparingIndicator = (UIActivityIndicatorView *) [cell viewWithTag:12];

    if ([channel isPlaySupported] == NO) {
        [headphoneImageView setImage:[UIImage imageNamed:@"tablecell_headphones_gray"]];
    } else {
        [headphoneImageView setImage:[UIImage imageNamed:@"tablecell_headphones_white"]];
    }

    if ([channel.serverName length] > 0) {
        serverNameLabel.text = channel.serverName;
    } else {
        serverNameLabel.text = @"";
    }
    if ([channel.genre length] > 0) {
        genreLabel.text = channel.genre;
    } else {
        genreLabel.text = @"";
    }
    if (bitrateLabel != nil) {
        bitrateLabel.text = [[self class] bitrateText:channel.bitrate];
    }
    
    // テーブルセルのテキスト等の色を変える
    serverNameLabel.textColor = HEADLINE_CELL_TITLE_TEXT_COLOR;
    serverNameLabel.highlightedTextColor = HEADLINE_CELL_TITLE_TEXT_SELECTED_COLOR;
    
    genreLabel.textColor = HEADLINE_CELL_DJ_TEXT_COLOR;
    genreLabel.highlightedTextColor = HEADLINE_CELL_DJ_TEXT_SELECTED_COLOR;
    
    if (bitrateLabel != nil) {
        bitrateLabel.backgroundColor = [UIColor colorWithPatternImage:[[self class] bitrateLabelBackgroundImage:channel.bitrate]];
        bitrateLabel.textColor = HEADLINE_CELL_BITRATE_TEXT_COLOR;
        bitrateLabel.highlightedTextColor = HEADLINE_CELL_BITRATE_TEXT_SELECTED_COLOR;
    }

    BOOL playing = [[Player sharedInstance] isPlaying:[channel listenUrl]];
    playImageView.hidden = !playing;
    
    preparingIndicator.transform = CGAffineTransformMakeScale(0.725, 0.725); // Indicatorのサイズ変更
    preparingIndicator.center = playImageView.center; // 再生アイコンとIndicatorの中心をあわせる
    BOOL preparing = [[Player sharedInstance] isPreparing:[channel listenUrl]];
    if (preparing) {
        [preparingIndicator startAnimating];
        preparingIndicator.hidden = NO;
    } else {
        [preparingIndicator stopAnimating];
        preparingIndicator.hidden = YES;
    }

    favoriteImageView.hidden = !channel.favorite;

    ChannelTableViewCell *channelCell = (ChannelTableViewCell *)cell;
    channelCell.swipeView = swipeView;

    anchorLabel.textColor = HEADLINE_CELL_PLAY_SWIPE_TEXT_COLOR;
    anchorLabel.highlightedTextColor = HEADLINE_CELL_PLAY_SWIPE_TEXT_COLOR;
    anchorLabel.text = @"";
    
    if (playing) {
        [anchorImage setImage:[UIImage imageNamed:@"tablecell_stop_black"]];
        [anchorImage setHighlightedImage:[UIImage imageNamed:@"tablecell_stop_black"]];
    } else if ([channel isPlaySupported] == NO) {
        [anchorImage setImage:[UIImage imageNamed:@"tablecell_notsupported_black"]];
        [anchorImage setHighlightedImage:[UIImage imageNamed:@"tablecell_notsupported_black"]];
    } else {
        [anchorImage setImage:[UIImage imageNamed:@"tablecell_play_black"]];
        [anchorImage setHighlightedImage:[UIImage imageNamed:@"tablecell_play_black"]];
    }

    return cell;
}
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif

+ (NSInteger)headlineViewDisplayType
{
    NSInteger result = HeadlineViewDisplayTypeElapsedTime;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *view_headline = [defaults objectForKey:@"view_headline"];
    if ([view_headline isEqualToString:@"view_headline_only_title_and_dj"]) {
        result = HeadlineViewDisplayTypeOnlyTitleAndDj;
    } else if ([view_headline isEqualToString:@"view_headline_elapsed_time"]) {
        result = HeadlineViewDisplayTypeElapsedTime;
    } else if ([view_headline isEqualToString:@"view_headline_bitrate"]) {
        result = HeadlineViewDisplayTypeBitrate;
    } else if ([view_headline isEqualToString:@"view_headline_elapsed_time_and_bitrate"]) {
        result = HeadlineViewDisplayTypeElapsedTimeAndBitrate;
    }

    return result;
}

+ (NSString *)dateText:(NSDate *)date
{
    NSString *result;
    
    NSInteger diffTime = (NSInteger)[[NSDate date] timeIntervalSinceDate:date];
    NSInteger diffDay = diffTime / (24 * 60 * 60);
    NSInteger diffHour = (diffTime % (24 * 60 * 60)) / (60 * 60);
    NSInteger diffMin = (diffTime % (60 * 60)) / 60;
    // 1分未満
    if (diffDay < 1 && diffHour < 1 && diffMin < 1) {
        result = [[NSString alloc] initWithFormat:NSLocalizedString(@"%dmin", @"分"), 1];
    }
    // 1日以上前
    else if (diffDay >= 1) {
        NSString *daySuffix;
        if (diffDay == 1) {
            daySuffix = NSLocalizedString(@"%dday", @"日");
        } else {
            daySuffix = NSLocalizedString(@"%ddays", @"日");
        }
        result = [[NSString alloc] initWithFormat:daySuffix, diffDay];
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
        result = diffTimeString;
    }
    
    return result;
}

/// 渡された日付と現在の日付から、日付ラベルの背景画像を返す
+ (UIImage *)dateLabelBackgroundImage:(NSDate *)date
{
    UIImage *result;
    
    NSTimeInterval diffTime = [[NSDate date] timeIntervalSinceDate:date];
    
    // 渡された日付が現在よりも新しい場合（ないはずだが一応）
    if (diffTime <= 0) {
        result = [UIImage imageNamed:@"date_label_background_01"];
    } else if (0 < diffTime && diffTime <= 1 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_01"];
    } else if (1 * 18 * 60 < diffTime && diffTime <= 2 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_02"];
    } else if (2 * 18 * 60 < diffTime && diffTime <= 3 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_03"];
    } else if (3 * 18 * 60 < diffTime && diffTime <= 4 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_04"];
    } else if (4 * 18 * 60 < diffTime && diffTime <= 5 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_05"];
    } else if (5 * 18 * 60 < diffTime && diffTime <= 6 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_06"];
    } else if (6 * 18 * 60 < diffTime && diffTime <= 7 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_07"];
    } else if (7 * 18 * 60 < diffTime && diffTime <= 8 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_08"];
    } else if (8 * 18 * 60 < diffTime && diffTime <= 9 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_09"];
    } else if (9 * 18 * 60 < diffTime && diffTime <= 10 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_10"];
    } else if (10 * 18 * 60 < diffTime && diffTime <= 11 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_11"];
    } else if (11 * 18 * 60 < diffTime && diffTime <= 12 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_12"];
    } else if (12 * 18 * 60 < diffTime && diffTime <= 13 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_13"];
    } else if (13 * 18 * 60 < diffTime && diffTime <= 14 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_14"];
    } else if (14 * 18 * 60 < diffTime && diffTime <= 15 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_15"];
    } else if (15 * 18 * 60 < diffTime && diffTime <= 16 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_16"];
    } else if (16 * 18 * 60 < diffTime && diffTime <= 17 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_17"];
    } else if (17 * 18 * 60 < diffTime && diffTime <= 18 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_18"];
    } else if (18 * 18 * 60 < diffTime && diffTime <= 19 * 18 * 60) {
        result = [UIImage imageNamed:@"date_label_background_19"];
    } else {
        result = [UIImage imageNamed:@"date_label_background_20"];
    }
    
    return result;
}


+ (NSString *)bitrateText:(NSInteger)bitrate
{
    NSString *result;

    if (bitrate < 1000) {
        result = [[NSString alloc] initWithFormat:@"%dkbps", bitrate];
    }
    // 1000 - 1024
    else if (bitrate <= 1024) {
        result = @"1Mbps";
    }
    // 1025 - 102399 (99.99Mbps)
    else if (bitrate <= 102399) {
        result = [[NSString alloc] initWithFormat:@"%.1fMbps", bitrate / (float)1024];
    }
    // 102400 - 1048575(999.99Mbps)
    else if (bitrate <= 1048575) {
        result = [[NSString alloc] initWithFormat:@"%.0fMbps", bitrate / (float)1024];
    } else {
        result = [[NSString alloc] initWithFormat:@"%.1fTbps", bitrate / (float)(1024 * 1024)];
    }
    
    return result;
}

/// 渡されたビットレートから、ビットレートラベルの背景画像を返す
+ (UIImage *)bitrateLabelBackgroundImage:(NSInteger)bitrate
{
    UIImage *result;
    
    if (bitrate <= 24) {
        result = [UIImage imageNamed:@"bitrate_label_background_01"];
    } else if (24 < bitrate && bitrate <= 32) {
        result = [UIImage imageNamed:@"bitrate_label_background_02"];
    } else if (32 < bitrate && bitrate <= 40) {
        result = [UIImage imageNamed:@"bitrate_label_background_03"];
    } else if (40 < bitrate && bitrate <= 48) {
        result = [UIImage imageNamed:@"bitrate_label_background_04"];
    } else if (48 < bitrate && bitrate <= 56) {
        result = [UIImage imageNamed:@"bitrate_label_background_05"];
    } else if (56 < bitrate && bitrate <= 64) {
        result = [UIImage imageNamed:@"bitrate_label_background_06"];
    } else if (64 < bitrate && bitrate <= 72) {
        result = [UIImage imageNamed:@"bitrate_label_background_07"];
    } else if (72 < bitrate && bitrate <= 80) {
        result = [UIImage imageNamed:@"bitrate_label_background_08"];
    } else if (80 < bitrate && bitrate <= 88) {
        result = [UIImage imageNamed:@"bitrate_label_background_09"];
    } else if (88 < bitrate && bitrate <= 96) {
        result = [UIImage imageNamed:@"bitrate_label_background_10"];
    } else if (96 < bitrate && bitrate <= 104) {
        result = [UIImage imageNamed:@"bitrate_label_background_11"];
    } else if (104 < bitrate && bitrate <= 112) {
        result = [UIImage imageNamed:@"bitrate_label_background_12"];
    } else {
        result = [UIImage imageNamed:@"bitrate_label_background_13"];
    }
    
    return result;
}

/// 指定されたTableViewのIndexPathから何番目の番組かを取得する
+ (NSInteger)channelIndexFromIndexPath:(NSIndexPath *)indexPath
{
    if (!IS_SHOW_AD) {
        return indexPath.row;
    } else {
        return indexPath.row - 1;
    }
}

/// 指定された何番目の番組からTableViewのIndexPathを取得する
+ (NSIndexPath *)indexPathFromChannelIndex:(NSInteger)channelIndex
{
    if (!IS_SHOW_AD) {
        return [NSIndexPath indexPathForRow:channelIndex inSection:0];
    } else {
        return [NSIndexPath indexPathForRow:(channelIndex + 1) inSection:0];
    }
}

- (void)updateHeadlineTable
{
    if (SEARCH_EACH_CHAR == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 検索バーの入力を受け付けない
            _headlineSearchBar.userInteractionEnabled = NO;
        });
    }

    Headline *headline = [Headline sharedInstance];
    _showedChannels = [headline channels:_channelSortType
                              searchWord:searchWord_];

    dispatch_async(dispatch_get_main_queue(), ^{
        // ナビゲーションタイトルを更新
        NSString *navigationTitleStr = @"";
        if ([_showedChannels count] == 0) {
            navigationTitleStr = NSLocalizedString(@"ON AIR", @"番組一覧にトップに表示されるONAIR 番組が無い場合/番組画面から戻るボタン");
        } else {
            navigationTitleStr = NSLocalizedString(@"ON AIR %dch", @"番組一覧にトップに表示されるONAIR 番組がある場合");
        }
        _navigateionItem.title = [[NSString alloc] initWithFormat:navigationTitleStr, [_showedChannels count]];
        
        // ヘッドラインテーブルを更新
        [self.headlineTableView reloadData];
        
        if (SEARCH_EACH_CHAR == NO) {
            // 検索バーの入力を受け付ける
            _headlineSearchBar.userInteractionEnabled = YES;
            // 検索バーのインジケーターを消す
            [_headlineSearchBarIndicator stopAnimating];
        }
    });
}

- (void)updatePlayingButton
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // 再生状態に逢わせて再生ボタンの表示を切り替える
        if ([[Player sharedInstance] state] == PlayerStatePlay) {
            self.navigationItem.rightBarButtonItem = tempPlayingBarButtonItem_;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    });
}

#pragma mark - Actions

- (IBAction)openSideMenu:(id)sender
{
    [self.viewDeckController toggleLeftViewAnimated:YES];
}

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // ソートタイプを復元する
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    ChannelSortType s = [defaults integerForKey:SELECTED_CHANNEL_SORT_TYPE_INDEX];
#if defined(LADIO_TAIL)
    switch (s) {
        case ChannelSortTypeNewly:
        case ChannelSortTypeListeners:
        case ChannelSortTypeTitle:
        case ChannelSortTypeDj:
            _channelSortType = s;
            break;
        case ChannelSortTypeNone:
        default:
            _channelSortType = ChannelSortTypeNewly;
            break;
    }
#elif defined(RADIO_EDGE)
    switch (s) {
        case ChannelSortTypeNewly:
        case ChannelSortTypeServerName:
        case ChannelSortTypeGenre:
        case ChannelSortTypeBitrate:
            _channelSortType = s;
            break;
        case ChannelSortTypeNone:
        default:
            _channelSortType = ChannelSortTypeNewly;
            break;
    }
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif

    // 設定の変更を補足する
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];

    // ヘッドラインの取得開始と終了をハンドリングし、ヘッドライン更新ボタンの有効無効の切り替えやテーブル更新を行う
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineDidStartLoad:)
                                                 name:RadioLibHeadlineDidStartLoadNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineDidFinishLoad:)
                                                 name:RadioLibHeadlineDidFinishLoadNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineFailLoad:)
                                                 name:RadioLibHeadlineFailLoadNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineChannelChanged:)
                                                 name:RadioLibHeadlineChannelChangedNotification
                                               object:nil];

    // 再生状態が切り替わるごとに再生ボタンなどの表示を切り替える
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playStateChanged:)
                                                 name:LadioTailPlayerPrepareNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playStateChanged:)
                                                 name:LadioTailPlayerDidPlayNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playStateChanged:)
                                                 name:LadioTailPlayerDidStopNotification
                                               object:nil];

    // dealloc時にself.viewDeckControllerでviewDeckControllerが取得できないようであるため
    // ここでviewDeckController_にself.viewDeckControllerを保持する
    viewDeckController_ = self.viewDeckController;
    viewDeckController_.delegate = self;

    // 番組画面からの戻るボタンのテキストと色を書き換える
    NSString *backButtonString = NSLocalizedString(@"ON AIR", @"番組一覧にトップに表示されるONAIR 番組が無い場合/番組画面から戻るボタン");
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:backButtonString
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:nil
                                                                      action:nil];
    backButtonItem.tintColor = BACK_BUTTON_COLOR;
    self.navigationItem.backBarButtonItem = backButtonItem;

    // メニューボタンの色を変更する
    _sideMenuBarButtonItem.tintColor = SIDEMENU_BUTTON_COLOR;

    // 再生中ボタンの装飾を変更する
    _playingBarButtonItem.title = NSLocalizedString(@"Playing", @"再生中ボタン");
    _playingBarButtonItem.tintColor = PLAYING_BUTTON_COLOR;
    // 再生中ボタンを保持する
    tempPlayingBarButtonItem_ = _playingBarButtonItem;

    // 検索バーの色を変える
    _headlineSearchBar.tintColor = SEARCH_BAR_COLOR;

    // 検索バーが空でもサーチキーを押せるようにする
    // http://stackoverflow.com/questions/3846917/iphone-uisearchbar-how-to-search-for-string
    for (UIView *subview in _headlineSearchBar.subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            ((UITextField *) subview).enablesReturnKeyAutomatically = NO;
            break;
        }
    }

    // StoryBoard上でセルの高さを設定しても有効にならないので、ここで高さを設定する
    // http://stackoverflow.com/questions/7214739/uitableview-cells-height-is-not-working-in-a-empty-table
    _headlineTableView.rowHeight = 54;
    // テーブルの背景の色を変える
    _headlineTableView.backgroundColor = HEADLINE_TABLE_BACKGROUND_COLOR;
    // テーブルの境界線の色を変える
    _headlineTableView.separatorColor = HEADLINE_TABLE_SEPARATOR_COLOR;

    // ヘッドライン表示方式を設定
    headlineViewDisplayType_ = [[self class] headlineViewDisplayType];
    
    if (PULL_REFRESH_HEADLINE) {
        // PullRefreshViewの生成
        if (refreshHeaderView_ == nil) {
            CGRect pullRefreshViewRect = CGRectMake(
                                                    0.0f,
                                                    0.0f - _headlineTableView.bounds.size.height,
                                                    self.view.frame.size.width,
                                                    _headlineTableView.bounds.size.height);
            EGORefreshTableHeaderView *view =
            [[EGORefreshTableHeaderView alloc] initWithFrame:pullRefreshViewRect
                                              arrowImageName:PULL_REFRESH_ARROW_IMAGE
                                                   textColor:PULL_REFRESH_TEXT_COLOR];
            view.backgroundColor = PULL_REFRESH_TEXT_BACKGROUND_COLOR;
            
            view.delegate = self;
            [_headlineTableView addSubview:view];
            refreshHeaderView_ = view;
        }
    }

    adViewCell_ = [[AdViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ChannelCell_Ad"];
    adViewCell_.rootViewController = self;
    [adViewCell_ load];
}

- (void)viewDidUnload
{
    [self setSideMenuBarButtonItem:nil];
    [self setNavigateionItem:nil];
    [self setPlayingBarButtonItem:nil];
    [self setHeadlineSearchBar:nil];
    [self setHeadlineTableView:nil];
    [self setHeadlineSearchBarIndicator:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    // 表示後とにヘッドラインテーブルを更新する
    [self updateHeadlineTable];

    // 再生状態に逢わせて再生ボタンの表示を切り替える
    [self updatePlayingButton];

    // 広告の定期ロード再開
    [adViewCell_ resume];

    // viewWillAppear:animated はsuperを呼び出す必要有り
    // テーブルの更新前に呼ぶらしい
    // http://d.hatena.ne.jp/kimada/20090917/1253187128
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // 広告の定期ロード中断
    [adViewCell_ pause];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // ネットワークが接続済みの場合で、かつ番組表を取得していない場合
    if ([FBNetworkReachability sharedInstance].reachable && [[Headline sharedInstance] channels] == 0) {
        // 番組表を取得する
        // 進捗ウィンドウを正しく表示させるため、viewDidAppear:animated で番組表を取得する
        [self fetchHeadline];
    }
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
    // テーブルから番組を選択した
    if ([[segue identifier] isEqualToString:@"SelectChannel"]) {
        // 番組情報を遷移先のViewに設定
        UIViewController *viewCon = [segue destinationViewController];
        if ([viewCon isKindOfClass:[ChannelViewController class]]) {
            NSInteger channelIndex =
                [[self class] channelIndexFromIndexPath:[_headlineTableView indexPathForSelectedRow]];
            Channel *channel = _showedChannels[channelIndex];
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
#if defined(LADIO_TAIL)
            Channel *channel = [headline channelFromPlayUrl:playingUrl];
#elif defined(RADIO_EDGE)
            Channel *channel = [headline channelFromListenUrl:playingUrl];
#else
            #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif
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

    __block NSInteger playingChannelIndex;
    __block BOOL found = NO;
    // 再生している番組がの何番目かを探索する
    dispatch_apply([_showedChannels count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
        if (found == NO) {
            Channel *channel = _showedChannels[i];
#if defined(LADIO_TAIL)
            if ([channel isSameMount:playingChannel]) {
                playingChannelIndex = i;
                found = YES; // 見つかったことを示す
            }
#elif defined(RADIO_EDGE)
            if ([channel isSameListenUrl:playingChannel]) {
                playingChannelIndex = i;
                found = YES; // 見つかったことを示す
            }
#else
            #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif
        }
    });

    // 見つかった場合はスクロール
    if (found) {
        NSIndexPath *indexPath = [[self class] indexPathFromChannelIndex:playingChannelIndex];
        [_headlineTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // 検索バーに入力された文字列を保持
    searchWord_ = searchText;

    if (SEARCH_EACH_CHAR) {
        [self updateHeadlineTable];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (SEARCH_EACH_CHAR == NO) {
        [_headlineSearchBarIndicator startAnimating];
        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
            [self updateHeadlineTable];
        }];
    }
    // キーボードを閉じる
    [searchBar resignFirstResponder];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!IS_SHOW_AD) {
        return [_showedChannels count];
    } else {
        NSInteger result = [_showedChannels count];
        // 番組を取得していない場合
        if (result <= 0) {
            return 0;
        }
        // 番組を取得している場合
        else {
            // 広告表示分を足す
            return [_showedChannels count] + 1;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 広告View
    if (IS_SHOW_AD && indexPath.row == 0) {
        return adViewCell_;
    }
    // 広告View以外のView
    else {
        return [self tableView:tableView createChannelCell:[[self class] channelIndexFromIndexPath:indexPath]];
    }
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!IS_SHOW_AD) {
        return 54;
    } else {
        if (indexPath.row == 0) {
            if (!adViewCell_) {
                return 54;
            } else {
                return [adViewCell_ cellSize].height;
            }
        } else {
            return 54;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!IS_SHOW_AD) {
        [self performSegueWithIdentifier:@"SelectChannel" sender:self];
    } else {
        if (indexPath.row == 0) {
            // 選択解除（選択時ハイライトなしにしているが、タップ後スクロールするとハイライトするため解除する）
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        } else {
            [self performSegueWithIdentifier:@"SelectChannel" sender:self];
        }
    }
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

#pragma mark - IIViewDeckControllerDelegate methods

- (BOOL)viewDeckControllerWillOpenLeftView:(IIViewDeckController*)viewDeckController animated:(BOOL)animated
{
    // キーボードを閉じる
    [_headlineSearchBar resignFirstResponder];
    return YES;
}

#pragma mark - ChannelTableViewDelegate methods

- (BOOL)tableView:(UITableView*)tableView shouldAllowSwipingForRowAtIndexPath:(NSIndexPath*)indexPath
{
    PlayerState playerState = [[Player sharedInstance] state];
    if (playerState == PlayerStatePrepare) {
        return NO;
    }

    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView sizeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView swipeEnableSizeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 38;
}

- (void)   tableView:(UITableView *)tableView
didChangeSwipeEnable:(BOOL)enable
             forCell:(ChannelTableViewCell *)cell
   forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UILabel *anchorLabel = (UILabel *) [cell viewWithTag:10];
    if (enable) {
        NSInteger channelIndex = [[self class] channelIndexFromIndexPath:indexPath];
        Channel *channel = (Channel *) _showedChannels[channelIndex];
        if (channel) {
#if defined(LADIO_TAIL)
            BOOL playing = [[Player sharedInstance] isPlaying:channel.playUrl];
#elif defined(RADIO_EDGE)
            BOOL playing = [[Player sharedInstance] isPlaying:channel.listenUrl];
#else
            #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif
            if (playing) {
                anchorLabel.text = @"STOP";
                [anchorLabel.layer removeAllAnimations]; // アニメーションのキャンセル
                anchorLabel.alpha = 0;
                [UIView animateWithDuration:0.24 delay:0.0
                                    options:UIViewAnimationCurveLinear | UIViewAnimationOptionAllowUserInteraction
                                 animations:^{
                                     anchorLabel.alpha = 1;
                                 }
                                 completion:nil];
            } else if ([channel isPlaySupported] == NO) {
                anchorLabel.text = @"";
            } else {
                anchorLabel.text = @"PLAY";
                [anchorLabel.layer removeAllAnimations]; // アニメーションのキャンセル
                anchorLabel.alpha = 0;
                [UIView animateWithDuration:0.24 delay:0.0
                                    options:UIViewAnimationCurveLinear | UIViewAnimationOptionAllowUserInteraction
                                 animations:^{
                                     anchorLabel.alpha = 1;
                                 }
                                 completion:nil];
            }
        } else {
            anchorLabel.text = @"";
        }
    } else {
        [anchorLabel.layer removeAllAnimations]; // アニメーションのキャンセル
        anchorLabel.alpha = 0;
    }
}

- (void)tableViewDidSwipeEnable:(UITableView *)tableView
                        forCell:(ChannelTableViewCell *)cell
              forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger channelIndex = [[self class] channelIndexFromIndexPath:indexPath];
    Channel *channel = (Channel *) _showedChannels[channelIndex];
    if (channel) {
#if defined(LADIO_TAIL)
        BOOL playing = [[Player sharedInstance] isPlaying:channel.playUrl];
#elif defined(RADIO_EDGE)
        BOOL playing = [[Player sharedInstance] isPlaying:channel.listenUrl];
#else
        #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif
        if (playing) {
            [[Player sharedInstance] stop];
        } else if ([channel isPlaySupported] == NO) {
            ;
        } else {
            [[Player sharedInstance] playChannel:channel];
        }
    }

    UILabel *anchorLabel = (UILabel *) [cell viewWithTag:10];
    anchorLabel.text = @"";
}

#pragma mark - NSUserDefaults notifications

- (void)defaultsChanged:(NSNotification *)notification
{
    NSInteger currentHeadlineViewDisplayType = [[self class] headlineViewDisplayType];

    if (headlineViewDisplayType_ != currentHeadlineViewDisplayType) {
        headlineViewDisplayType_ = currentHeadlineViewDisplayType;
        [self updateHeadlineTable];
    }
}

#pragma mark - Headline notifications

- (void)headlineDidStartLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update started notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */
}

- (void)headlineDidFinishLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update suceed notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    if (PULL_REFRESH_HEADLINE) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Pull refreshを終了する
            [refreshHeaderView_ egoRefreshScrollViewDataSourceDidFinishedLoading:_headlineTableView];
        });
    }
}

- (void)headlineFailLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update faild notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    if (PULL_REFRESH_HEADLINE) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Pull refreshを終了する
            [refreshHeaderView_ egoRefreshScrollViewDataSourceDidFinishedLoading:_headlineTableView];
        });
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
        dispatch_async(dispatch_get_main_queue(), ^{
            // 再生が開始した際に、再生している番組をテーブルの一番上になるようにスクロールする
            if ([[Player sharedInstance] state] == PlayerStatePlay) {
                [self scrollToTopAtPlayingCell];
            }
        });
    }
}

@end
