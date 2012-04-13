//
//  ChannelInfo.m
//  LadioTailForIPhone
//
//  Created by 平野 雄一 on 12/04/13.
//  Copyright (c) 2012年 Y.Hirano. All rights reserved.
//

#import "ChannelInfo.h"

@implementation ChannelInfo

@synthesize title;
@synthesize value;

- (id)initWithTitle:(NSString*) t value:(NSString*)v
{
    if (self = [super init]) {
        self.title = t;
        self.value = v;
    }
    return self;
}


@end
