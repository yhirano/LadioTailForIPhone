//
//  NADInterstitial.h
//  NendAd
//
//  インタースティシャル広告クラス

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

///-----------------------------------------------
/// @name Constants
///-----------------------------------------------

/**
 NADInterstitialClickType
 */
typedef enum {
    DOWNLOAD,
    CLOSE,
} NADInterstitialClickType;

/**
 NADInterstitialStatusCode
 */
typedef enum {
    SUCCESS,
    INVALID_RESPONSE_TYPE,
    FAILED_AD_REQUEST,
    FAILED_AD_DOWNLOAD,
} NADInterstitialStatusCode;

/**
 NADInterstitialShowAdResult
 */
typedef enum {
    AD_SHOW_SUCCESS,
    AD_LOAD_INCOMPLETE,
    AD_REQUEST_INCOMPLETE,
    AD_DOWNLOAD_INCOMPLETE,
    AD_FREQUENCY_NOT_REACHABLE,
    AD_SHOW_ALREADY
} NADInterstitialShowResult;

/**
 A delegate object for each event of Interstitial-AD.
 */
@protocol NADInterstitialDelegate <NSObject>

@optional

/**
 Notify the results of the ad load.
 */
- (void) didFinishLoadInterstitialAdWithStatus:(NADInterstitialStatusCode)status;

- (void) didFinishLoadInterstitialAdWithStatus:(NADInterstitialStatusCode)status spotId:(NSString *)spotId;

/**
 Notify the event of the ad click.
 */
- (void) didClickWithType:(NADInterstitialClickType)type;

- (void) didClickWithType:(NADInterstitialClickType)type spotId:(NSString *)spotId;

@end

/**
 The management class of Interstitial-AD.
 */
@interface NADInterstitial : NSObject

/**
 Set the delegate object.
 
 @warning Please set this to `nil` when the delegate object is deallocated.
 */
@property (nonatomic, assign, readwrite) id<NADInterstitialDelegate> delegate;

/**
 Log setting.
 */
@property (nonatomic, readwrite) BOOL isOutputLog;

/**
 Supported Orientations.
 */
@property (nonatomic, retain) NSArray* supportedOrientations;

///-----------------------------------------------
/// @name Creating and Initializing Nend Instance
///-----------------------------------------------

/**
 Creates and returns a `NADInterstitial` object.
 
 @return NADInterstitial
 */
+ (instancetype) sharedInstance;

///------------------------
/// @name Loading AD
///------------------------

/**
 Load the Interstitial-AD.
 
 @param apiKey An apiKey issued from the management screen.
 @param spotId A spotId issued from the management screen.
 @warning　Please call this when the application starts.
 
 for example:

 `- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions`
 */
- (void) loadAdWithApiKey:(NSString *)apiKey spotId:(NSString *)spotId;

///----------------------------
/// @name Showing / Closing AD
///----------------------------

/**
 Show the Interstitial-AD on the UIWindow.
 
 @return NADInterstitialShowResult
 */
- (NADInterstitialShowResult) showAd;

- (NADInterstitialShowResult) showAdWithSpotId:(NSString *)spotId;

/**
 Dismiss the Interstitial-AD.
 
 @return `YES` AD will be closed, otherwise `NO`.
 */
- (BOOL) dismissAd;

@end
