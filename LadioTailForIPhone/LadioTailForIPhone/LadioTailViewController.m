/*
 * Copyright (c) 2012 Y.Hirano
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

#import "SVProgressHUD/SVProgressHUD.h"
#import "LadioLib.h"
#import "Player.h"
#import "LadioTailViewController.h"

/// ヘッドライン取得失敗時にエラーを表示する秒数
#define DELAY_FETCH_HEADLINE_MESSAGE 3

@implementation LadioTailViewController

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioLibHeadlineDidStartLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioLibHeadlineDidFinishLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioLibHeadlineFailLoadNotification object:nil];
#ifdef DEBUG
    NSLog(@"%@ unregisted headline update notifications.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */
}

#pragma mark - UIView methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // ヘッドラインの取得開始と終了をハンドリングし、ヘッドライン更新ボタンの有効無効の切り替えやテーブル更新を行う
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineDidStartLoad:)
                                                 name:LadioLibHeadlineDidStartLoadNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineDidFinishLoad:)
                                                 name:LadioLibHeadlineDidFinishLoadNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineFailLoad:)
                                                 name:LadioLibHeadlineFailLoadNotification 
                                               object:nil];
#ifdef DEBUG
    NSLog(@"%@ registed headline update notifications.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    // viewWillAppear:animated はsuperを呼び出す必要有り
    // テーブルの更新前に呼ぶらしい
    // http://d.hatena.ne.jp/kimada/20090917/1253187128
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // リモコン対応
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // リモコン対応
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];

    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIResponder methods

- (BOOL)canBecomeFirstResponder
{
    // リモコン対応
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent*)event
{
	switch (event.subtype) {
		case UIEventSubtypeRemoteControlTogglePlayPause:
            // リモコンからのボタンクリック
            [[Player sharedInstance] switchPlayStop];
            break;
		default:
            break;
	}
}

#pragma mark - Headline notifications
- (void)headlineDidStartLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update started notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */
    
    // 進捗ウィンドウを表示する
    [SVProgressHUD show];
}

- (void)headlineDidFinishLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update suceed notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */
    
    // 進捗ウィンドウを消す
    [SVProgressHUD dismiss];
}

- (void)headlineFailLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update faild notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */
    
    // 進捗ウィンドウにエラー表示
    NSString *errorStr = NSLocalizedString(@"Channel information could not be obtained.", @"番組表の取得に失敗");
    [SVProgressHUD dismissWithError:errorStr afterDelay:DELAY_FETCH_HEADLINE_MESSAGE];
}

@end
