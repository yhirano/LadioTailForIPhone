/*
 * Copyright (c) 2012-2017 Yuichi Hirano
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

#import "SwipableTableViewCell.h"

@implementation SwipableTableViewCell
{
    // スワイプで移動するビュー
    UIView *swipeView_;

    // ジェスチャー
    UIPanGestureRecognizer *panGesture_;
    // 移動した位置を記憶しておく
    CGPoint lastPosition_;

    // 初期位置
    CGPoint firstPocition_;
    // スワイプで移動するビューの最大移動量
    CGSize limitSize_;
    // スワイプが有効になったと見なされる移動量
    CGSize enableSize_;

    __weak UITableView *tableView_;
    __weak id<SwipableTableViewDelegate> tableViewDelegate_;
}

- (void)dealloc
{
    // didDetectPanningの呼び出しで落ちることがあるようなので、明示的にactionとdelegateを削除してみる
    [panGesture_ removeTarget:nil action:NULL];
    panGesture_.delegate = nil;
}

- (UIView *)swipeView
{
    return swipeView_;
}

- (void)setSwipeView:(UIView *)swipeView
{
    swipeView_ = swipeView;
    firstPocition_ = swipeView.frame.origin;
    if (panGesture_ == nil) {
        panGesture_ = [[UIPanGestureRecognizer alloc] init];
        [panGesture_ addTarget:self action:@selector(didDetectPanning:)];
        panGesture_.delegate = self;
    }
    [self.contentView addGestureRecognizer:panGesture_];
}

- (void)revertSwipeWithAnimated:(BOOL)animated
{
    CGFloat newPositionX = firstPocition_.x;

    if (animated) {
        panGesture_.enabled = NO;
        NSTimeInterval duration = 0.24;
        __weak id weakSelf = self;
        [UIView animateWithDuration:duration
                              delay:0.0
                            options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             CGRect frame = swipeView_.frame;
                             frame.origin.x = newPositionX;
                             swipeView_.frame = frame;
                         }
                         completion:^(BOOL finished) {
                             id strongSelf = weakSelf;
                             [strongSelf setSwipeState:SwipableTableViewCellSwipeStateNormal];

                             if ([tableViewDelegate_
                                    respondsToSelector:@selector(tableView:didChangeSwipeEnable:forCell:forRowAtIndexPath:)]){
                                 NSIndexPath* indexPath = [tableView_ indexPathForCell:strongSelf];
                                 if (indexPath) {
                                     [tableViewDelegate_ tableView:tableView_
                                              didChangeSwipeEnable:NO
                                                           forCell:strongSelf
                                                 forRowAtIndexPath:indexPath];
                                 }
                             }

                             panGesture_.enabled = YES;
                         }];
    } else {
        CGRect frame = swipeView_.frame;
        frame.origin.x = newPositionX;
        swipeView_.frame = frame;
        [self setSwipeState:SwipableTableViewCellSwipeStateNormal];

        if ([tableViewDelegate_
                respondsToSelector:@selector(tableView:didChangeSwipeEnable:forCell:forRowAtIndexPath:)]) {
            NSIndexPath* indexPath = [tableView_ indexPathForCell:self];
            if (indexPath) {
                [tableViewDelegate_ tableView:tableView_
                         didChangeSwipeEnable:NO
                                      forCell:self
                            forRowAtIndexPath:indexPath];
            }
        }
    }
}

#pragma mark - Private methods

- (BOOL)isEnableSwipe
{
    if (swipeView_.frame.origin.x > firstPocition_.x + enableSize_.width) {
        return YES;
    } else {
        return NO;
    }
}

- (void)setSwipeState:(SwipableTableViewCellSwipeState)state
{
    if (_swipeState == state) {
        return;
    }

    _swipeState = state;

    if ([tableViewDelegate_ respondsToSelector:@selector(tableView:didChangeSwipeState:forRowAtIndexPath:)]) {
        NSIndexPath* indexPath = [tableView_ indexPathForCell:self];
        if (indexPath) {
            [tableViewDelegate_ tableView:tableView_ didChangeSwipeState:_swipeState forRowAtIndexPath:indexPath];
        }
    }
}

#pragma mark - Gesture action

- (void)didDetectPanning:(UIPanGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            lastPosition_ = [gesture locationInView:self];
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint position = [gesture locationInView:self];
            CGRect frame = swipeView_.frame;

            CGFloat diff = (position.x - lastPosition_.x);
            if (diff == 0) {
                ;
            } else if (frame.origin.x + diff <= firstPocition_.x) {
                frame.origin.x = firstPocition_.x;
                __weak id weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    id strongSelf = weakSelf;
                    BOOL befoure = [self isEnableSwipe];
                    swipeView_.frame = frame;
                    BOOL after = [self isEnableSwipe];

                    if (befoure != after) {
                        if([tableViewDelegate_
                            respondsToSelector:@selector(tableView:didChangeSwipeEnable:forCell:forRowAtIndexPath:)]){
                            NSIndexPath* indexPath = [tableView_ indexPathForCell:strongSelf];
                            if (indexPath) {
                                [tableViewDelegate_ tableView:tableView_
                                         didChangeSwipeEnable:after
                                                      forCell:strongSelf
                                            forRowAtIndexPath:indexPath];
                            }
                        }
                    }
                });
            } else if (frame.origin.x + diff <= firstPocition_.x + limitSize_.width) {
                frame.origin.x += diff;
                __weak id weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    id strongSelf = weakSelf;

                    BOOL befoure = [self isEnableSwipe];
                    swipeView_.frame = frame;
                    BOOL after = [self isEnableSwipe];
                    
                    if (befoure != after) {
                        if([tableViewDelegate_
                            respondsToSelector:@selector(tableView:didChangeSwipeEnable:forCell:forRowAtIndexPath:)]){
                            NSIndexPath* indexPath = [tableView_ indexPathForCell:strongSelf];
                            if (indexPath) {
                                [tableViewDelegate_ tableView:tableView_
                                         didChangeSwipeEnable:after
                                                      forCell:strongSelf
                                            forRowAtIndexPath:indexPath];
                            }
                        }
                    }
                });
            }

            [self setSwipeState:SwipableTableViewCellSwipeStateSwiping];

            lastPosition_ = position;
            break;
        }
        default:
        {
            if (_swipeState == SwipableTableViewCellSwipeStateSwiping) {
                if ([self isEnableSwipe]) {
                    if([tableViewDelegate_
                        respondsToSelector:@selector(tableViewDidSwipeEnable:forCell:forRowAtIndexPath:)]){
                        NSIndexPath* indexPath = [tableView_ indexPathForCell:self];
                        if (indexPath) {
                            [tableViewDelegate_ tableViewDidSwipeEnable:tableView_
                                                                forCell:self
                                                      forRowAtIndexPath:indexPath];
                        }
                    }
                }
                [self revertSwipeWithAnimated:YES];
            }
            break;
        }
    }
}

#pragma mark - UIView methods

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];

    // 〜 iOS 6.1
    if ([newSuperview isKindOfClass:[UITableView class]]) {
        tableView_ = (UITableView*)newSuperview;
        tableViewDelegate_ = (id<SwipableTableViewDelegate>)tableView_.delegate;
    }
    // iOS 7.0 〜
    else if ([newSuperview.superview isKindOfClass:[UITableView class]]) {
        tableView_ = (UITableView*)newSuperview.superview;
        tableViewDelegate_ = (id<SwipableTableViewDelegate>)tableView_.delegate;
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    if ([self.superview isEqual:tableView_] || // 〜 iOS 6.1
        [self.superview.superview isEqual:tableView_] // iOS 7.0 〜
    ) {
        NSIndexPath* indexPath = [tableView_ indexPathForCell:self];
        if ([tableViewDelegate_ respondsToSelector:@selector(tableView:sizeForRowAtIndexPath:)]) {
            limitSize_.width = [tableViewDelegate_ tableView:tableView_ sizeForRowAtIndexPath:indexPath];
        }
        if ([tableViewDelegate_ respondsToSelector:@selector(tableView:swipeEnableSizeForRowAtIndexPath:)]) {
            enableSize_.width = [tableViewDelegate_ tableView:tableView_ swipeEnableSizeForRowAtIndexPath:indexPath];
        }
    }
}

#pragma mark - UITableViewCell methods

- (void)prepareForReuse
{
    [super prepareForReuse];

    [self revertSwipeWithAnimated:NO];
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    BOOL allow = YES;
    if ([tableViewDelegate_ respondsToSelector:@selector(tableView:shouldAllowSwipingForRowAtIndexPath:)]) {
        NSIndexPath* indexPath = [tableView_ indexPathForCell:self];
        if (indexPath) {
            allow = [tableViewDelegate_ tableView:tableView_ shouldAllowSwipingForRowAtIndexPath:indexPath];
        }
    }
    if (!allow) {
        return NO;
    }

    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint velocity = [panGesture_ velocityInView:self.contentView];

    if (fabs(velocity.x) < fabs(velocity.y)) {
        return NO;
    }

    // 自身や他のセルが選択されている場合
    if (self.isSelected || (tableView_ && [tableView_ indexPathForSelectedRow])) {
        return NO;
    }

    return YES;
}

@end
