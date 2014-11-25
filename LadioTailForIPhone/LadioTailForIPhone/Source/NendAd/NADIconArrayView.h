//
//  NADIconArrayView.h
//  NendAd
//
//  アイコン型広告ビュークラス(InterfaceBuilder用)

#import <UIKit/UIKit.h>
#import "NADIconLoader.h"

@class NADIconLoader;



@interface NADIconArrayView : UIView{
}

#pragma mark - テキスト表示設定
@property (nonatomic,assign) BOOL textHidden;
#pragma mark - 周囲の余白表示設定
@property (nonatomic,assign) BOOL iconSpaceEnabled;
#pragma apiKey
@property (nonatomic,assign) NSString *nendApiKey;
#pragma 広告枠ID
@property (nonatomic,assign) NSString *nendSpotID;
#pragma アイコン表示方向
@property (nonatomic,assign) BOOL isVertical;
#pragma アイコン表示数
@property(nonatomic,assign) NSNumber* icons;
#pragma mark - Log出力設定
@property (nonatomic,assign) BOOL isOutputLog;

@property (nonatomic,readonly) NADIconLoader* iconLoader;

#pragma mark - テキストカラー設定
-(void)setTextColor:(UIColor *)setColor;
#pragma mark - 広告の定期ロード中断を要求します
-(void)pause;
#pragma mark - 広告の定期ロード再開を要求します
-(void)resume;

@end
