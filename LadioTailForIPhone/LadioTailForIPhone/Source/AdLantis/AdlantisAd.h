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

@interface AdlantisAd : NSObject

@property (nonatomic) BOOL sendingImpressionCount;
@property (nonatomic) BOOL sentImpressionCount;     // インプレッションカウントがサーバーへ通知されたかどうかの判定。

+ (UIInterfaceOrientation)aspectOrientationForSize:(CGSize)size;
+ (UIInterfaceOrientation)aspectOrientationForSize:(CGSize)size orientation:(UIInterfaceOrientation)orientation;

- (id)initWithDictionary:(NSDictionary*)inDict;

- (void)viewingStarted;

- (void)viewingEnded;

- (id)objectForKey:(id)aKey;

- (NSString*) adType;

// テキスト広告の文字データ
- (NSString*) adText;

// 画像サイズ。バナー広告の際に使用する
- (CGSize) imageSizeForOrientation:(UIInterfaceOrientation) orientation;

// 代替テキスト
- (NSString*)altTextForOrientation:(UIInterfaceOrientation) orientation;

// 一行テキストの広告用アイコンURL
- (NSString*)iconURL;
// 一行テキストの広告用アイコンデータ
- (NSData*) iconData;

- (NSDictionary*)bannerAdDataForOrientation:(UIInterfaceOrientation) orientation;

- (NSString*)assetUrlStringForOrientation:(UIInterfaceOrientation) orientation;

- (UIImage*)imageForRenderedAdForOrientation:(UIInterfaceOrientation) orientation;
- (UIImage*)imageForRenderedAdWithSize:(CGSize)imageSize;

- (NSString*)tapUrlString;
- (NSString*)urlString;          // this method is to become obsolete, use tapUrlString instead

- (BOOL)showAlert;
- (NSString*)linkType;

- (void)sendImpressionCount;
- (NSString*)countImpressionURLString;

- (BOOL)hasLandscape;
- (BOOL)hasAdForOrientation:(UIInterfaceOrientation) orientation;

- (void)requestDataForOrientation:(UIInterfaceOrientation) orientation;

- (NSString*) longDescription;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
extern NSString * const AdlantisAdTypeWeb;
extern NSString * const AdlantisAdTypeTel;
extern NSString * const AdlantisAdTypeAppStore;
extern NSString * const AdlantisAdTypeITunes;
