//
//  AdlantisAdManager.h
//  AdLantis iOS SDK
//
//  Copyright 2009 Atlantis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

///////////////////////////////////////////////////////////////////////////////////////////////////
@class AdlantisAd;
@class AdlantisAdsModel;
@class AdNetworkConnection;

// used when assets are updated via network
extern NSString * const AdlantisAdsUpdatedNotification;
extern NSString * const AdlantisAdsUpdatedNotificationAdCount;          // NSNumber(int) count of ads received
extern NSString * const AdlantisAdsUpdatedNotificationCached;           // NSValue(bool) were the ads loaded from the cache?
extern NSString * const AdlantisAdsUpdatedNotificationError;            // NSValue(bool) was there an error?
extern NSString * const AdlantisAdsUpdatedNotificationNSError;          // NSError error that occurred (not always available)
extern NSString * const AdlantisAdsUpdatedNotificationErrorDescription; // NSString describing error (not always available)

extern NSString * const AdlantisAdManagerAssetUpdatedNotification;

extern NSString * const AdlantisPreviewWillBeShownNotification;
extern NSString * const AdlantisPreviewWillBeHiddenNotification;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface AdlantisAdManager : NSObject

+ (AdlantisAdManager*)sharedManager;

+ (NSString*)versionString;                        // AdLantis SDK version
+ (NSString*)build;                                // AdLantis SDK build
- (NSString*)fullVersionString;                    // Complete version information in one line

- (NSString*)byline;

+ (NSMutableArray*)adsFromJSONData:(NSData*)jsonAdData;

@property (nonatomic,retain) AdlantisAdsModel *adsModel;

@property (nonatomic,retain) NSString *publisherID;

@property (nonatomic,copy) NSString *host;

@property (nonatomic,assign) NSTimeInterval adFetchInterval;      // (default) amount of time (in seconds) before fetching next set of ads, set to zero to stop ad fetch
@property (nonatomic,assign) NSTimeInterval adDisplayInterval;    // (default) amount of time (in seconds) before showing the next ad

@property (nonatomic,readonly) NSTimeInterval impressionCountReportInterval;  // amount of time (in seconds) before sending impression count

@property (nonatomic,retain) AdNetworkConnection *adNetworkConnection;
@property (nonatomic,copy) NSArray *testAdRequestURLs;

@property (nonatomic,retain) NSString *isoCountryCode; // ISO 3166-1 country code representation

- (void)addUser:(id)user selector:(SEL)aSelector;
- (void)removeUser:(id)user;

- (NSData*) cachedDataForURLString:(NSString*)urlString;

// make http request for assets
- (void)requestAdData:(AdlantisAd*)ad forUrl:(NSString*)url;
- (void)requestDataForUrl:(NSString*)url;

// user request ad
- (void)handleTouchForAd:(AdlantisAd*)ad;
- (void)openUrlForAd:(AdlantisAd*)ad;

// send impression count for ad
// インプレッションカウントを送信する
- (void)sendImpressionCountForAd:(AdlantisAd*)ad;

// request the loading of ads from server, primarily for testing
- (void)loadAds;

// send conversion tag
- (void)sendConversionTag:(NSString*)inConversionTag;
- (void)sendConversionTagTest:(NSString*)inConversionTag;

// clear the contents of the cache
// キャッシュをクリアするための関数群
- (void)clearDiskCache;
- (void)clearMemoryCache;
- (void)clearCache;

// are there ads for the requested orientation?
- (BOOL)hasAdsForOrientation:(UIInterfaceOrientation) orientation;

@end
