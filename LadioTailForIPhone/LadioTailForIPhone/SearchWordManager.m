//
//  SearchWordManager.m
//  LadioTailForIPhone
//
//  Created by 平野 雄一 on 12/04/14.
//  Copyright (c) 2012年 Y.Hirano. All rights reserved.
//

#import "SearchWordManager.h"

static SearchWordManager *instance = nil;

@implementation SearchWordManager

@synthesize searchWord;

+ (SearchWordManager *)sharedInstance
{
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[SearchWordManager alloc] init];
    });
    return instance;
}

@end
