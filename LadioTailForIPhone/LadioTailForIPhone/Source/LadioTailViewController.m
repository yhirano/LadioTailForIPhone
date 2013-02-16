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
#import "ViewDeck/IIViewDeckController.h"
#import "LadioTailConfig.h"
#import "RadioLib/RadioLib.h"
#import "Player.h"
#import "HeadlineNaviViewController.h"
#import "SideMenuTableViewController.h"
#import "HeadlineViewController.h"
#import "LadioTailViewController.h"

@implementation LadioTailViewController
{
    IIViewDeckController *viewDeckController_;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RadioLibHeadlineDidStartLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RadioLibHeadlineDidFinishLoadNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RadioLibHeadlineFailLoadNotification object:nil];
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
                                                 name:RadioLibHeadlineDidStartLoadNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineDidFinishLoad:)
                                                 name:RadioLibHeadlineDidFinishLoadNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headlineFailLoad:)
                                                 name:RadioLibHeadlineFailLoadNotification 
                                               object:nil];
#ifdef DEBUG
    NSLog(@"%@ registed headline update notifications.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    // サイドメニューを設定する
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    HeadlineNaviViewController* headlineNaviViewController =
        (HeadlineNaviViewController *)[storyboard instantiateViewControllerWithIdentifier:@"HeadlineNaviViewController"];
    SideMenuTableViewController *sideMenuTableViewController =
        (SideMenuTableViewController *)[storyboard instantiateViewControllerWithIdentifier:@"SideMenuTableViewController"];
    viewDeckController_ = [[IIViewDeckController alloc] initWithCenterViewController:headlineNaviViewController
                                                                 leftViewController:sideMenuTableViewController];
    viewDeckController_.view.frame = self.view.bounds;
    viewDeckController_.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractiveWithTapToClose;
    viewDeckController_.leftLedge = SIDEMENU_LEFT_LEDGE;

    [self.view addSubview:viewDeckController_.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [viewDeckController_ viewWillAppear:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // リモコン対応
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    // リモコン対応/シェイク対応
    [self becomeFirstResponder];

    [viewDeckController_ viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // リモコン対応
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];

    [viewDeckController_ viewWillDisappear:animated];

    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [viewDeckController_ viewDidDisappear:animated];
    
    [super viewDidDisappear:animated];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [viewDeckController_ willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    [viewDeckController_ willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [viewDeckController_ didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [viewDeckController_ shouldAutorotateToInterfaceOrientation:interfaceOrientation];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        switch (interfaceOrientation) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
                return YES;
            case UIInterfaceOrientationPortraitUpsideDown:
            default:
                return NO;
        }
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

- (BOOL)shouldAutorotate
{
    [viewDeckController_ shouldAutorotate];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return NO;
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
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

    // HeadlineNaviViewControllerを取得する
    HeadlineNaviViewController *headlineNaviViewController = nil;
    UIViewController* centerController = viewDeckController_.centerController;
    if ([centerController isKindOfClass:[HeadlineNaviViewController class]]) {
        headlineNaviViewController = (HeadlineNaviViewController*)centerController;
    } else {
        return nil;
    }

    // HeadlineNaviViewControllerの中からHeadlineViewControllerを探し出す
    for (UIViewController *viewcon in headlineNaviViewController.viewControllers) {
        if ([viewcon isKindOfClass:[HeadlineViewController class]]) {
            headlineViewController = (HeadlineViewController *)viewcon;
            break;
        }
    }

    if (headlineViewController != nil) {
        // 番組を取得する
        NSArray *channels = headlineViewController.showedChannels;
        __block NSInteger playingChannelIndex;
        __block BOOL found = NO;
        // 再生している番組が表示しているHeadlineViewControllerの何番目かを探索する
        dispatch_apply([channels count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
            if (found == NO) {
                Channel *channel = channels[i];
#if defined(LADIO_TAIL)
                if ([channel isSameMount:playingChannel]) {
                    playingChannelIndex = i;
                    found = YES; // 見つかったことを示す
                }
#elif defined(RADIO_EDGE)
                if ([channel isSameListenUrl:playingChannel]) {
                    playingChannelIndex = i;
                    found = YES; // 見つかったことを示す
                }
#else
#error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif
            }
        });
        // 番組が見つかった場合
        if (found) {
            // 現在再生中の次の番組を返す場合
            if (next) {
                // 番組が終端で無い場合
                if (playingChannelIndex < [channels count] - 1) {
                    // 次の番組を返す
                    result = channels[(playingChannelIndex + 1)];
                }
            }
            // 現在再生中の前の番組を返す場合
            else {
                // 番組が一番前で無い場合
                if (playingChannelIndex > 0) {
                    // 前の番組を返す
                    result = channels[(playingChannelIndex - 1)];
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

    // HeadlineNaviViewControllerを取得する
    HeadlineNaviViewController *headlineNaviViewController = nil;
    UIViewController* centerController = viewDeckController_.centerController;
    if ([centerController isKindOfClass:[HeadlineNaviViewController class]]) {
        headlineNaviViewController = (HeadlineNaviViewController*)centerController;
    } else {
        return nil;
    }

    // HeadlineNaviViewControllerの中からHeadlineViewControllerを探し出す
    for (UIViewController *viewcon in headlineNaviViewController.viewControllers) {
        if ([viewcon isKindOfClass:[HeadlineViewController class]]) {
            headlineViewController = (HeadlineViewController *)viewcon;
            break;
        }
    }
    
    // HeadlineViewControllerタブを選択している場合
    if (headlineViewController != nil) {
        // 番組を取得する
        NSArray *channels = headlineViewController.showedChannels;
        
        if ([channels count] > 0) {
            result = channels[(arc4random() % [channels count])];
        }
    }

    return result;
}

/**
 * メインスレッドで処理を実行する
 *
 * @params メインスレッドで処理を実行する
 */
- (void)execMainThread:(void (^)(void))exec
{
    if ([NSThread isMainThread]) {
        exec();
    } else {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            exec();
        }];
    }
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

#pragma mark - Headline notifications

- (void)headlineDidStartLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update started notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    [self execMainThread:^{
        // 進捗ウィンドウを表示する
        [SVProgressHUD show];
    }];
}

- (void)headlineDidFinishLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update suceed notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    [self execMainThread:^{
        // 進捗ウィンドウを消す
        [SVProgressHUD dismiss];
    }];
}

- (void)headlineFailLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update faild notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    [self execMainThread:^{
        // 進捗ウィンドウにエラー表示
        NSString *errorStr = NSLocalizedString(@"Channel information could not be obtained.", @"番組表の取得に失敗");
        [SVProgressHUD showErrorWithStatus:errorStr];
    }];
}

@end
