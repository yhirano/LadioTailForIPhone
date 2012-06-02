//
//  AdlantisAd.h
//  AdLantis iOS SDK
//
//  Created on 10/22/09.
//  Copyright 2009 Atlantis. All rights reserved.
//

#import <Foundation/Foundation.h>

///////////////////////////////////////////////////////////////////////////////////////////////////
extern NSString const *AdlantisAdTypeText;
extern NSString const *AdlantisAdTypeBanner;

extern CGFloat const AdLantisStandardPortraitAdWidth;
extern CGFloat const AdLantisStandardPortraitAdHeight;
extern CGFloat const AdLantisStandardLandscapeAdWidth;
extern CGFloat const AdLantisStandardLandscapeAdHeight;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@class SDTiming;

@interface AdlantisAd : NSObject {
@private
  NSDictionary *_adData;
  NSTimeInterval _displayTime;           // 一つの広告が表示される時間（秒単位）
  BOOL sendingImpressionCount;
  BOOL sentImpressionCount;             // インプレッションカウントがサーバーへ通知されたかどうかの判定。
  BOOL sendingExpansionCount;
  BOOL sentExpansionCount;
  SDTiming *elapsedViewTiming;
}

@property (nonatomic,retain) NSDictionary *adData;

@property (nonatomic) NSTimeInterval displayTime;

@property (nonatomic) BOOL sendingImpressionCount;
@property (nonatomic) BOOL sentImpressionCount;
@property (nonatomic) BOOL sendingExpansionCount;
@property (nonatomic) BOOL sentExpansionCount;

+(UIInterfaceOrientation)aspectOrientationForSize:(CGSize)size;
+(UIInterfaceOrientation)aspectOrientationForSize:(CGSize)size orientation:(UIInterfaceOrientation)orientation;

-(id)initWithDictionary:(NSDictionary*)inDict;

-(void)viewingStarted;

-(void)viewingEnded;

-(id)objectForKey:(id)aKey;

-(NSString*) adType;

// テキスト広告の文字データ
-(NSString*) adText;

// 画像サイズ。バナー広告の際に使用する
-(CGSize) imageSizeForOrientation:(UIInterfaceOrientation) orientation;

// 代替テキスト
-(NSString*)altTextForOrientation:(UIInterfaceOrientation) orientation;

// 一行テキストの広告用アイコンURL
-(NSString*)iconURL;
// 一行テキストの広告用アイコンデータ
-(NSData*) iconData;

-(NSDictionary*)bannerAdDataForOrientation:(UIInterfaceOrientation) orientation;

-(NSString*)assetUrlStringForOrientation:(UIInterfaceOrientation) orientation;

-(UIImage*)imageForRenderedAdForOrientation:(UIInterfaceOrientation) orientation;
-(UIImage*)imageForRenderedAdWithSize:(CGSize)imageSize;

-(NSString*)tapUrlString;
-(NSString*)urlString;          // this method is to become obsolete, use tapUrlString instead

-(BOOL)hasPreview;              // returns YES if the property is defined, however there may not be an actual preview URL
-(NSString*)previewURLString;
-(BOOL)showAlert;
-(NSString*)linkType;
-(BOOL)shouldHandleRedirect;

-(void)sendImpressionCount;
-(NSString*)countImpressionURLString;

-(BOOL)hasLandscape;
-(BOOL)hasAdForOrientation:(UIInterfaceOrientation) orientation;

-(NSString*)countExpandURLString;
-(BOOL)hasExpandedAdForOrientation:(UIInterfaceOrientation) orientation;
-(NSDictionary*)expandedContentForOrientation:(UIInterfaceOrientation) orientation;
-(NSString*)expandedContentImageURLForOrientation:(UIInterfaceOrientation) orientation;
-(CGSize)expandedContentAdSizeForOrientation:(UIInterfaceOrientation) orientation;

-(void)requestDataForOrientation:(UIInterfaceOrientation) orientation;

-(NSString*) longDescription;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
extern NSString * const AdlantisAdTypeWeb;
extern NSString * const AdlantisAdTypeTel;
extern NSString * const AdlantisAdTypeAppStore;
extern NSString * const AdlantisAdTypeITunes;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface NSArray(AdlantisAdExtensions)
-(NSArray*)adsForOrientation:(UIInterfaceOrientation)orientation;
-(NSUInteger)adCountForOrientation:(UIInterfaceOrientation)orientation;
@end
