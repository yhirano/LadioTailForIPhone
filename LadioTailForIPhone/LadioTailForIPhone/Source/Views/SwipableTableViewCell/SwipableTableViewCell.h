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

#import <UIKit/UIKit.h>

// スワイプの状態
typedef enum
{
    SwipableTableViewCellSwipeStateNormal,
    SwipableTableViewCellSwipeStateSwiping,
} SwipableTableViewCellSwipeState;

@interface SwipableTableViewCell : UITableViewCell

/// スワイプで移動するビュー
@property(strong) UIView *swipeView;

/// スワイプの状態
@property(readonly) SwipableTableViewCellSwipeState swipeState;

- (void)revertSwipeWithAnimated:(BOOL)animated;

@end

@protocol SwipableTableViewDelegate < UITableViewDelegate >
@optional

- (BOOL) tableView:(UITableView*)tableView shouldAllowSwipingForRowAtIndexPath:(NSIndexPath*)indexPath;

- (CGFloat)tableView:(UITableView *)tableView sizeForRowAtIndexPath:(NSIndexPath *)indexPath;

- (CGFloat)tableView:(UITableView *)tableView swipeEnableSizeForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)  tableView:(UITableView *)tableView
didChangeSwipeState:(SwipableTableViewCellSwipeState)state
  forRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)   tableView:(UITableView *)tableView
didChangeSwipeEnable:(BOOL)enable
             forCell:(SwipableTableViewCell *)cell
   forRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableViewDidSwipeEnable:(UITableView *)tableView
                         forCell:(SwipableTableViewCell *)cell
               forRowAtIndexPath:(NSIndexPath *)indexPath;

@end