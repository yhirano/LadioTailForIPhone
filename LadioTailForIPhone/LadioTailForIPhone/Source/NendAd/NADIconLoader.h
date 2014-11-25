//
//  NADIconLoader.h
//  NendAd
//
//  アイコン型広告ローダークラス

#import <Foundation/Foundation.h>
#import "NADIconView.h"

@class NADIconLoader;

@protocol NADIconLoaderDelegate <NSObject>

@optional
#pragma mark - NADViewの広告ロードが初めて成功した際に通知されます
- (void)nadIconLoaderDidFinishLoad:(NADIconLoader *)iconLoader;
#pragma mark - 広告受信が成功した際に通知されます
- (void)nadIconLoaderDidReceiveAd:(NADIconLoader *)iconLoader nadIconView:(NADIconView*)nadIconView;
#pragma mark - 広告受信に失敗した際に通知されます
- (void)nadIconLoaderDidFailToReceiveAd:(NADIconLoader *)iconLoader nadIconView:(NADIconView*)nadIconView;
#pragma mark - 広告バナークリック時に通知されます
- (void)nadIconLoaderDidClickAd:(NADIconLoader *)iconLoader nadIconView:(NADIconView*)nadIconView;

@end

@interface NADIconLoader : NSObject{
    id delegate;
}

#pragma mark - delegateオブジェクトの指定
@property (nonatomic, assign) id <NADIconLoaderDelegate> delegate;

#pragma mark - Log出力設定
@property (nonatomic) BOOL isOutputLog;

#pragma mark - エラー内容出力
@property (nonatomic, assign) NSError *error;

#pragma mark - NADIconLoaderにIconViewを追加
-(void)addIconView:(NADIconView*)iconView;

#pragma mark - NADIconLoaderからIconViewを削除
-(void)removeIconView:(NADIconView*)iconView;

#pragma mark - 広告枠のapiKeyとspotIDをセット
-(void)setNendID:(NSString *)apiKey spotID:(NSString *)spotID;

#pragma mark - 広告のロード開始
-(void)load;

#pragma mark - 広告の定期ロード中断を要求します
-(void)pause;

#pragma mark - 広告の定期ロード再開を要求します
-(void)resume;

@end
