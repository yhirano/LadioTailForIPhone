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

#import <SVProgressHUD/SVProgressHUD.h>
#import "LadioTailConfig.h"
#import "RadioLib/RadioLib.h"
#import "LadioTailConfig.h"
#import "Player.h"
#import "HeadlineNaviViewController.h"
#import "SideMenuViewController.h"
#import "HeadlineViewController.h"
#import "LadioTailViewController.h"

@interface LadioTailViewController () <IIViewDeckControllerDelegate>

@end

@implementation LadioTailViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    HeadlineNaviViewController* headlineNaviViewController =
        (HeadlineNaviViewController *)[storyboard instantiateViewControllerWithIdentifier:@"HeadlineNaviViewController"];
    SideMenuViewController *sideMenuTableViewController =
        (SideMenuViewController *)[storyboard instantiateViewControllerWithIdentifier:@"SideMenuViewController"];
    self = [super initWithCenterViewController:headlineNaviViewController
                            leftViewController:sideMenuTableViewController];
    return self;
}

-(void)dealloc
{
    self.delegate = nil;

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

    self.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractiveWithTapToClose;
    self.sizeMode = IIViewDeckViewSizeMode;
    [self setCenterTapperAccessibilityLabel:NSLocalizedString(@"Main menu", @"メインメニューボタン")];
    [self setCenterTapperAccessibilityHint:NSLocalizedString(@"Close the main menu", @"メインメニューを閉じる")];

    self.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // leftSizeはviewDidAppear以前に設定するとLandscapeでアプリを起動したときにメニューのサイズがおかしくなる
    self.leftSize = [LadioTailConfig sideMenuLeftSize];

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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    // サイドメニューのテーブルの幅を変更する（VoiceOver対応）
    // 画面が回転する際に端までテーブルビューがないと見栄えが悪いので、サイドメニューが閉じる直前にテーブルビューを引き延ばす
    UIViewController *leftController = self.leftController;
    if ([leftController isKindOfClass:[SideMenuViewController class]]) {
        SideMenuViewController *sideMenuTableViewController = (SideMenuViewController *)leftController;
        CGRect frame = sideMenuTableViewController.tableView.frame;
        frame.size.width = self.view.frame.size.width;
        sideMenuTableViewController.tableView.frame = frame;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation];

    // サイドメニューのテーブルの幅を変更する（VoiceOver対応）
    UIViewController *leftController = self.leftController;
    if ([leftController isKindOfClass:[SideMenuViewController class]]) {
        SideMenuViewController *sideMenuTableViewController = (SideMenuViewController *)leftController;
        CGRect frame = sideMenuTableViewController.tableView.frame;
        frame.size.width = [LadioTailConfig sideMenuLeftSize];
        sideMenuTableViewController.tableView.frame = frame;
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
    UIViewController* centerController = self.centerController;
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
        NSArray<Channel*> *channels = headlineViewController.showedChannels;
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
    UIViewController* centerController = self.centerController;
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
        NSArray<Channel*> *channels = headlineViewController.showedChannels;
        
        if ([channels count] > 0) {
            result = channels[(arc4random() % [channels count])];
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

#pragma mark - IIViewDeckControllerDelegate methods

- (void)viewDeckController:(IIViewDeckController*)viewDeckController didChangeOffset:(CGFloat)offset orientation:(IIViewDeckOffsetOrientation)orientation panning:(BOOL)panning
{
    // サイドメニューのテーブルの幅を変更する（VoiceOver対応）
    // 画面がバウンスする際に端までテーブルビューがないと見栄えが悪いので、サイドメニューが閉じる直前にテーブルビューを引き延ばす
    UIViewController *leftController = self.leftController;
    if ([leftController isKindOfClass:[SideMenuViewController class]]) {
        SideMenuViewController *sideMenuTableViewController = (SideMenuViewController *)leftController;
        if (offset >= [LadioTailConfig sideMenuLeftSize]) {
            CGRect frame = sideMenuTableViewController.tableView.frame;
            frame.size.width = offset;
            sideMenuTableViewController.tableView.frame = frame;
        }
    }
}

- (void)viewDeckController:(IIViewDeckController*)viewDeckController
          willOpenViewSide:(IIViewDeckSide)viewDeckSide
                  animated:(BOOL)animated
{
    HeadlineViewController *headlineViewController = nil;
    
    // HeadlineNaviViewControllerを取得する
    HeadlineNaviViewController *headlineNaviViewController = nil;
    UIViewController *centerController = self.centerController;
    if ([centerController isKindOfClass:[HeadlineNaviViewController class]]) {
        headlineNaviViewController = (HeadlineNaviViewController*)centerController;

        // HeadlineNaviViewControllerの中からHeadlineViewControllerを探し出す
        for (UIViewController *viewcon in headlineNaviViewController.viewControllers) {
            if ([viewcon isKindOfClass:[HeadlineViewController class]]) {
                headlineViewController = (HeadlineViewController *)viewcon;
                break;
            }
        }
    }
    
    if (headlineViewController != nil) {
        // キーボードを閉じる
        [headlineViewController.headlineSearchBar resignFirstResponder];
    }

    // 左側のメニューが開く
    if (viewDeckSide == IIViewDeckLeftSide) {
        // サイドメニューのテーブルの幅を変更する（VoiceOver対応）
        UIViewController *leftController = self.leftController;
        if ([leftController isKindOfClass:[SideMenuViewController class]]) {
            SideMenuViewController *sideMenuTableViewController = (SideMenuViewController *)leftController;
            CGRect frame = sideMenuTableViewController.tableView.frame;
            frame.size.width = [LadioTailConfig sideMenuLeftSize];
            sideMenuTableViewController.tableView.frame = frame;
        }
    }
}

#pragma mark - Headline notifications

- (void)headlineDidStartLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update started notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    dispatch_async(dispatch_get_main_queue(), ^{
        // 進捗ウィンドウを表示する
        if (!UIAccessibilityIsVoiceOverRunning()) {
            [SVProgressHUD show];
        } else {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"Updating", @"更新中")];
        }
    });
}

- (void)headlineDidFinishLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update suceed notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    dispatch_async(dispatch_get_main_queue(), ^{
        // 進捗ウィンドウを消す
        [SVProgressHUD dismiss];
    });
}

- (void)headlineFailLoad:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"%@ received headline update faild notification.", NSStringFromClass([self class]));
#endif /* #ifdef DEBUG */

    dispatch_async(dispatch_get_main_queue(), ^{
        // 進捗ウィンドウにエラー表示
        NSString *errorStr = NSLocalizedString(@"Channel information could not be obtained.", @"番組表の取得に失敗");
        [SVProgressHUD showErrorWithStatus:errorStr];
    });
}

@end
