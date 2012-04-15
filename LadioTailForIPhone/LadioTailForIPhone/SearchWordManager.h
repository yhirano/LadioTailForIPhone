//
//  SearchWordManager.h
//  LadioTailForIPhone
//
//  Created by 平野 雄一 on 12/04/14.
//  Copyright (c) 2012年 Y.Hirano. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 番組一覧の検索ワードを保持しておくためのシングルトンクラス
 *
 * 4つタブで検索ワードを共通で使うために使用する
 */
@interface SearchWordManager : NSObject

@property (strong) NSString *searchWord;

+ (SearchWordManager *)sharedInstance;

@end
