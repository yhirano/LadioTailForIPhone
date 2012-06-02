//
//  AdlantisAdManager.h
//  AdLantis iOS SDK
//
//  Copyright 2009 Atlantis. All rights reserved.
//

#import <Foundation/Foundation.h>

///////////////////////////////////////////////////////////////////////////////////////////////////
@class ASINetworkQueue;
@class AdlantisURLCache;
@class AdlantisAd,AdlantisView;
@class AdlantisPreviewController;
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

extern NSString * const AdlantisURLProcessingStarted;
extern NSString * const AdlantisURLProcessingEnded;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface AdlantisAdManager : NSObject {
@private
  NSMutableArray *_ads;
  NSString *_publisherID;
  NSMutableArray *_users;                          // array of non-retained references to users (see addUser: removeUser:)
  
  NSString *_userID, *_password;
  
  AdlantisURLCache *_urlCache;
    
  ASINetworkQueue *_requestNetworkQueue;
  ASINetworkQueue *assetNetworkQueue;
  ASINetworkQueue *_impressionCountNetworkQueue;
  ASINetworkQueue *expansionCountNetworkQueue;
  ASINetworkQueue *redirectionNetworkQueue;
  ASINetworkQueue *conversionTagQueue;
  
  NSMutableArray *impressionCountHoldQueue;
  NSMutableArray *expansionCountHoldQueue;
  
  AdNetworkConnection *_adNetworkConnection;
  
  NSTimer *_adFetchTimer;
  NSTimeInterval _adFetchInterval;                 // amount of time before fetching next set of ads, set to zero to stop ad fetch
  NSTimeInterval _adDisplayInterval;               // amount of time before showing the next ad
  NSTimeInterval _impressionCountReportInterval;   // amount of time before sending impression count
  
  AdlantisPreviewController *_currentPreview;
  AdlantisAd *_currentAd;                          // ad being handled by handleTouchForAd:

  BOOL conversionTagSent;                         // has the conversion tag been sent?
  BOOL _didInitialAdRequest;                      // has the initial ad request been made?
}

+(AdlantisAdManager*)sharedManager;

+(NSString*)versionString;                        // AdLantis SDK version
+(NSString*)fullVersionString;                    // Complete version information in one line
+(NSString*)build;                                // AdLantis SDK build

+(NSString*)byline;

+(NSMutableArray*)adsFromJSONData:(NSData*)jsonAdData;

@property(nonatomic,retain,readonly) NSArray *ads;

@property(nonatomic,retain) NSString *publisherID;

@property(nonatomic,copy) NSString *host;

@property(nonatomic,assign) NSTimeInterval adFetchInterval;
@property(nonatomic,assign) NSTimeInterval adDisplayInterval;

@property(nonatomic,readonly) NSTimeInterval impressionCountReportInterval;

@property(nonatomic,retain) AdNetworkConnection *adNetworkConnection;
@property(nonatomic,copy) NSArray *testAdRequestURLs;

-(void)addUser:(id)user selector:(SEL)aSelector;
-(void)removeUser:(id)user;

-(NSData*) cachedDataForURLString:(NSString*)urlString;

// make http request for assets
-(void)requestAdData:(AdlantisAd*)ad forUrl:(NSString*)url;
-(void)requestDataForUrl:(NSString*)url;

// user request ad
-(void)handleTouchForAd:(AdlantisAd*)ad;
-(void)handleTouchForView:(AdlantisView*)adView;
-(void)openUrlForAd:(AdlantisAd*)ad;

// send impression count for ad
// インプレッションカウントを送信する
-(void)sendImpressionCountForAd:(AdlantisAd*)ad;

// send count expansion for ad
-(void)sendCountExpandForAd:(AdlantisAd*)ad;

// request the loading of ads from server, primarily for testing
-(void)loadAds;

// send conversion tag
-(void)sendConversionTag:(NSString*)inConversionTag;
-(void)sendConversionTagTest:(NSString*)inConversionTag;

// clear the contents of the cache
// キャッシュをクリアするための関数群
-(void)clearDiskCache;
-(void)clearMemoryCache;
-(void)clearCache;

// are there ads for the requested orientation?
-(BOOL)hasAdsForOrientation:(UIInterfaceOrientation) orientation;

@end
