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

#import <UIKit/UIKit.h>
#import "RadioLib/RadioLib.h"

@interface HeadlineViewController : UIViewController

@property (nonatomic, assign) ChannelSortType channelSortType;

/// テーブルに表示している番組
@property (nonatomic, strong ,readonly) NSArray<Channel*> *showedChannels;

@property (weak, nonatomic) IBOutlet UINavigationItem *navigateionItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sideMenuBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *playingBarButtonItem;

@property (weak, nonatomic) IBOutlet UISearchBar *headlineSearchBar;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *headlineSearchBarIndicator;

@property (weak, nonatomic) IBOutlet UITableView *headlineTableView;

- (void)fetchHeadline;

/**
 * 番組表の最終更新時間が指定の秒数より前の場合にのみ番組表を更新する
 *
 * @param intarval 番組表の最終更新時間がここに指定した秒数よりも前の場合に番組表を更新する
 */
- (void)fetchHeadlineIfLastUpdatePassedSince:(NSTimeInterval)intarval;

- (void)scrollToTopAnimated:(BOOL)animated;

- (IBAction)openSideMenu:(id)sender;

@end
