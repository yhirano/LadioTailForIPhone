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

#import "../../Player.h"
#import "../../PlayerDidStopNotificationObject.h"
#import "HistoryItem.h"
#import "HistoryManager.h"

#define HISTORY_KEY_V1 @"HISTORY_KEY_V1"

@implementation HistoryManager
{
    NSMutableArray *_history;
}

+ (HistoryManager *)sharedInstance
{
    static HistoryManager *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        instance = [[HistoryManager alloc] init];
    });
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        // データを復元する
        [self loadHistory];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerDidPlay:)
                                                     name:LadioTailPlayerDidPlayNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerDidStop:)
                                                     name:LadioTailPlayerDidStopNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidPlayNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioTailPlayerDidStopNotification object:nil];
}

- (NSArray *)history
{
    @synchronized(self) {
        return _history;
    }
}

#pragma mark - Player notification

- (void)playerDidPlay:(NSNotification *)notification
{
    Channel *channel = notification.object;
    HistoryItem *item = [self addHistory:channel];

    [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibHistoryChangedNotification
                                                        object:item];
}

- (void)playerDidStop:(NSNotification *)notification
{
    PlayerDidStopNotificationObject *object = notification.object;
    HistoryItem *item = [self applyListeningEndDateToHistory:object.channel];

    [[NSNotificationCenter defaultCenter] postNotificationName:RadioLibHistoryChangedNotification
                                                        object:item];
}

#pragma mark - Private methods

- (HistoryItem *)addHistory:(Channel *)channel
{
    HistoryItem *item;

    @synchronized(self) {
        item = [[HistoryItem alloc] init];
        item.channel = channel;
        [_history addObject:item];
    }
    
    // 履歴を保存する
    [self storeHistory];

    return item;
}

- (HistoryItem *)applyListeningEndDateToHistory:(Channel *)channel
{
    HistoryItem *result;

    @synchronized(self) {
        for (HistoryItem *item in _history) {
            if (!item.listeningEndDate && [item.channel isEqual:channel]) {
                item.listeningEndDate = [NSDate date];
                result = item;
                break;
            }
        }
    }

    return result;
}

/// データベースからお気に入り情報を復元する
- (void)loadHistory
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *hisotoryData = [defaults objectForKey:HISTORY_KEY_V1];
    if (hisotoryData != nil) {
        NSMutableArray *historyItemArray = [NSKeyedUnarchiver unarchiveObjectWithData:hisotoryData];
        if (historyItemArray != nil) {
            _history = [[NSMutableArray alloc] initWithArray:historyItemArray];
        } else {
            _history = [[NSMutableArray alloc] init];
        }
    } else {
        _history = [[NSMutableArray alloc] init];
    }
}

/// データベースに履歴情報を保存する
- (void)storeHistory
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:_history] forKey:HISTORY_KEY_V1];
}

/// データベースを空にする
- (void)clearHistory
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:HISTORY_KEY_V1];
    _history = nil;
}

@end
