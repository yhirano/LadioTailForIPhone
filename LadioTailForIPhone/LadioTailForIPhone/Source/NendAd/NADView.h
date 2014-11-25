//
//  NADView.h
//  NendAd
//
//  広告枠ベースビュークラス

#import <UIKit/UIKit.h>

#define NAD_ADVIEW_SIZE_320x50  CGSizeMake(320,50)

// エラー種別
NS_ENUM(NSInteger, NADViewErrorCode) {
    // 広告サイズがディスプレイサイズよりも大きい
    NADVIEW_AD_SIZE_TOO_LARGE,
    // 不明な広告ビュータイプ
    NADVIEW_INVALID_RESPONSE_TYPE,
    // 広告取得失敗
    NADVIEW_FAILED_AD_REQUEST,
    // 広告画像の取得失敗
    NADVIEW_FAILED_AD_DOWNLOAD,
    // リクエストしたサイズと取得したサイズが異なる
    NADVIEW_AD_SIZE_DIFFERENCES
};

@class NADView;

@protocol NADViewDelegate <NSObject>

@optional

#pragma mark - NADViewの広告ロードが初めて成功した際に通知されます
- (void)nadViewDidFinishLoad:(NADView *)adView;

#pragma mark - 広告受信が成功した際に通知されます
- (void)nadViewDidReceiveAd:(NADView *)adView;

#pragma mark - 広告受信に失敗した際に通知されます
- (void)nadViewDidFailToReceiveAd:(NADView *)adView;

#pragma mark - 広告バナークリック時に通知されます
- (void)nadViewDidClickAd:(NADView *)adView;

@end

@interface NADView : UIView {
    id delegate;
    NSError *error;
}

#pragma mark - delegateオブジェクトの指定
@property (nonatomic, assign) id <NADViewDelegate> delegate;

#pragma mark - モーダルビューを表示元のビューコントローラを指定
// ※現在では利用されないpropertyのため、今後は削除を予定しています。
@property (nonatomic, assign) UIViewController *rootViewController;

#pragma mark - Log出力設定
@property (nonatomic) BOOL isOutputLog;

#pragma mark - エラー内容出力
@property (nonatomic, assign) NSError *error;

#pragma apiKey
@property (nonatomic,assign) NSString *nendApiKey;

#pragma 広告枠ID
@property (nonatomic,assign) NSString *nendSpotID;


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

