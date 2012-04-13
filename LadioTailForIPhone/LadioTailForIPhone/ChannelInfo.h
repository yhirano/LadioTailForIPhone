//
//  ChannelInfo.h
//  LadioTailForIPhone
//
//  Created by 平野 雄一 on 12/04/13.
//  Copyright (c) 2012年 Y.Hirano. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 番組情報のタイトルとデータを持つクラス。
 * テーブル表示用
 */
@interface ChannelInfo : NSObject

@property (strong) NSString* title;

@property (strong) NSString* value;

- (id)initWithTitle:(NSString*) title value:(NSString*)value;

@end
