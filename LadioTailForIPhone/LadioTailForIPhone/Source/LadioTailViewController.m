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

#import "SVProgressHUD/SVProgressHUD.h"
#import "LadioTailConfig.h"
#import "LadioLib/LadioLib.h"
#import "Player.h"
#import "HeadlineViewController.h"
#import "LadioTailViewController.h"

/// 選択されたタブを覚えておくためのキー
#define MAIN_TAB_SELECTED_INDEX @"MAIN_TAB_SELECTED_INDEX"

@implementation LadioTailViewController

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioLibHeadlineDidStartLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioLibHeadlineDidFinishLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LadioLibHeadlineFailLoadNotification object:nil];
#ifdef DEBUG
    NSLog(@"%@ unregisted headline update notifications.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    self.delegate = nil;
}

#pragma mark - UIView methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 選択されたタブを復元する
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // 対応するデータが保存されていない場合でも0が返るので一番最初のタブが選択される
    self.selectedIndex = [defaults integerForKey:MAIN_TAB_SELECTED_INDEX];
    
    self.delegate = self;

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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // リモコン対応
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    // リモコン対応/シェイク対応
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

#pragma mark - Private Methods

/**
 * 選択しているタブのビューから、再生している番組の次または前の番組を取得する
 *
 * @param next YESの場合は次の番組、NOの場合は前の番組を返す
 * @return 次または前の番組。存在しない場合はnil。
 */
- (Channel *)nextOrPriviousChannel:(BOOL)next
{
    Channel *result = nil;
    Channel *playingChannel = [[Player sharedInstance] playingChannel];
    HeadlineViewController *headlineViewController = nil;

    // 再生中の番組が存在しない場合（ありえないはずだが）は終了
    if (playingChannel == nil) {
        return nil;
    }

    // 選択しているタブのビューがUINavigationControllerの場合（常にtrueのはずだが一応チェック）
    if ([self.selectedViewController isKindOfClass:[UINavigationController class]]) {
        // UINavigationControllerの中からHeadlineViewControllerを探し出す
        UINavigationController *nvc =(UINavigationController*)self.selectedViewController;
        for (UIViewController *viewcon in nvc.viewControllers) {
            if ([viewcon isKindOfClass:[HeadlineViewController class]]) {
                headlineViewController = (HeadlineViewController *)viewcon;
                break;
            }
        }
    }
    // ルートがHeadlineViewControllerであることはないはずだが一応チェック
    else if ([self.selectedViewController isKindOfClass:[HeadlineViewController class]]) {
        headlineViewController = (HeadlineViewController *)self.selectedViewController;
    }

    // HeadlineViewControllerタブを選択している場合
    if (headlineViewController != nil) {
        // 選択しているタブの表示されている番組を取得する
        NSArray *channels = headlineViewController.showedChannels;
        NSInteger playingChannelIndex;
        BOOL found = NO;
        // 再生している番組が表示しているHeadlineViewControllerの何番目かを探索する
        for (playingChannelIndex = 0; playingChannelIndex < [channels count]; ++playingChannelIndex) {
            Channel *channel = [channels objectAtIndex:playingChannelIndex];
            if ([channel isSameMount:playingChannel]) {
                found = YES; // 見つかったことを示す
                break;
            }
        }
        // 番組が見つかった場合
        if (found) {
            // 現在再生中の次の番組を返す場合
            if (next) {
                // 番組が終端で無い場合
                if (playingChannelIndex < [channels count] - 1) {
                    // 次の番組を返す
                    result = [channels objectAtIndex:(playingChannelIndex + 1)];
                }
            }
            // 現在再生中の前の番組を返す場合
            else {
                // 番組が一番前で無い場合
                if (playingChannelIndex > 0) {
                    // 前の番組を返す
                    result = [channels objectAtIndex:(playingChannelIndex - 1)];
                }
            }
        }
    }

    return result;
}

- (Channel *)randomChannel
{
    Channel *result = nil;
    HeadlineViewController *headlineViewController = nil;

    // 選択しているタブのビューがUINavigationControllerの場合（常にtrueのはずだが一応チェック）
    if ([self.selectedViewController isKindOfClass:[UINavigationController class]]) {
        // UINavigationControllerの中からHeadlineViewControllerを探し出す
        UINavigationController *nvc =(UINavigationController*)self.selectedViewController;
        for (UIViewController *viewcon in nvc.viewControllers) {
            if ([viewcon isKindOfClass:[HeadlineViewController class]]) {
                headlineViewController = (HeadlineViewController *)viewcon;
                break;
            }
        }
    }
    // ルートがHeadlineViewControllerであることはないはずだが一応チェック
    else if ([self.selectedViewController isKindOfClass:[HeadlineViewController class]]) {
        headlineViewController = (HeadlineViewController *)self.selectedViewController;
    }
    
    // HeadlineViewControllerタブを選択している場合
    if (headlineViewController != nil) {
        // 選択しているタブの表示されている番組を取得する
        NSArray *channels = headlineViewController.showedChannels;
        
        if ([channels count] > 0) {
            result = [channels objectAtIndex:(arc4random() % [channels count])];
        }
    }

    return result;
}

#pragma mark - UIResponder methods

- (BOOL)canBecomeFirstResponder
{
    // リモコン対応/シェイク対応
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent*)event
{
    Channel *channel;
    Player *player = [Player sharedInstance];

	switch (event.subtype) {
		case UIEventSubtypeRemoteControlTogglePlayPause:
            // リモコンからのボタンクリック
            [player switchPlayStop];
            break;
        case UIEventSubtypeRemoteControlNextTrack:
            channel = [self nextOrPriviousChannel:YES];
            if (channel != nil) {
                [player playChannel:channel];
            }
            break;
        case UIEventSubtypeRemoteControlPreviousTrack:
            channel = [self nextOrPriviousChannel:NO];
            if (channel != nil) {
                [player playChannel:channel];
            }
            break;
		default:
            break;
	}
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.type == UIEventSubtypeMotionShake) {
        NSLog(@"Shaked.");

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *operation_shake = [defaults objectForKey:@"operation_shake"];
        if ([operation_shake isEqualToString:@"shake_update_headline"]) {
            Headline *headline = [Headline sharedInstance];
            [headline fetchHeadline];
        } else if ([operation_shake isEqualToString:@"shake_play_random"]) {
            Channel *channel = [self randomChannel];
            if (channel != nil) {
                Player *player = [Player sharedInstance];
                [player playChannel:channel];
            }
        }
    }
}

#pragma mark - UITabBarControllerDelegate methods
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    // 選択されたタブを保存しておく
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.selectedIndex forKey:MAIN_TAB_SELECTED_INDEX];
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
