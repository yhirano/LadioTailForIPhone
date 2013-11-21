//
//  NADIconView.h
//  NendAd
//
//  Ver 2.3.0
//
//  アイコン型広告ビュークラス

#import <UIKit/UIKit.h>

#define NAD_ICONVIEW_SIZE_75x75  CGSizeMake(75,75)
#define NAD_ICON_SIZE_57x57  CGSizeMake(57,57)

@interface NADIconView : UIView{
    id delegate;
}

#pragma mark - delegateオブジェクトの指定
@property (nonatomic,assign) id delegate;
#pragma mark - テキスト表示設定
@property (nonatomic) BOOL textHidden;

#pragma mark - テキストカラー設定
-(void)setTextColor:(UIColor *)setColor;

@end
