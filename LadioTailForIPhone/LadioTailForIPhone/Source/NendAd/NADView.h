//
//  NADView.h
//  NendAd
//
//  Ver 1.3.2
//
//  広告枠ベースビュークラス

#import <UIKit/UIKit.h>

#define NAD_ADVIEW_SIZE_320x50  CGSizeMake(320,50)

@class NADView;

@protocol NADViewDelegate <NSObject>

#pragma mark - NADViewの広告ロードが初めて成功した際に通知されます
- (void)nadViewDidFinishLoad:(NADView *)adView;

@optional

#pragma mark - 広告受信が成功した際に通知されます
- (void)nadViewDidReceiveAd:(NADView *)adView;

#pragma mark - 広告受信に失敗した際に通知されます
- (void)nadViewDidFailToReceiveAd:(NADView *)adView;

@end

@interface NADView : UIView {
    id delegate;
}

#pragma mark - delegateオブジェクトの指定
@property (nonatomic, assign) id <NADViewDelegate> delegate;

#pragma mark - モーダルビューを表示元のビューコントローラを指定
@property (nonatomic, assign) UIViewController *rootViewController;

#pragma mark - 広告枠のapiKeyとspotIDをセット
- (void)setNendID:(NSString *)apiKey spotID:(NSString *)spotID;

#pragma mark - 広告のロード開始
- (void)load;

#pragma mark - 広告のロード開始
//  接続エラーや広告設定受信エラーなどの場合にリトライする間隔を、NSDictionaryで任意指定出来ます。
//  30 - 3600 の間で指定してください。範囲外指定された場合は標準の60秒が適用されます。
//
// 例) 180秒指定
//   [nadView load:[NSDictionary dictionaryWithObjectsAndKeys:@"180",@"retry",nil]];
- (void)load:(NSDictionary *)parameter;

#pragma mark - 広告の定期ロード中断を要求します
- (void)pause;

#pragma mark - 広告の定期ロード再開を要求します
- (void)resume;

@end
