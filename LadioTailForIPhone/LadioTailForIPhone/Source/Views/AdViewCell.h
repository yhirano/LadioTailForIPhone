//
//  AdViewCell.h
//  LadioTailForIPhone
//
//  Created by Yuichi Hirano on 2013/02/11.
//  Copyright (c) 2013年 Y.Hirano. All rights reserved.
//

#import <UIKit/UIKit.h>

/// 広告TableViewCell
@interface AdViewCell : UITableViewCell

@property (nonatomic) UIViewController *rootViewController;

/** セルのサイズを返す
 
 @return セルのサイズ
 */
- (CGSize)cellSize;

/// 広告をロードする
- (void)load;

@end
