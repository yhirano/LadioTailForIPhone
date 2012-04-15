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

+ (SearchWordManager*)sharedInstance
{
    if (instance == nil) {
        instance = [[SearchWordManager alloc] init];
    }
    return instance;
}

@end
