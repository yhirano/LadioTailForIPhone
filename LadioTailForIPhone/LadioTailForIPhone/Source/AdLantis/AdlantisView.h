//
//  AdlantisView.h
//  AdLantis iOS SDK
//
//  Created on 10/16/09.
//  Copyright 2009 Atlantiss.jp. All rights reserved.
//

#import <UIKit/UIKit.h>

///////////////////////////////////////////////////////////////////////////////////////////////////
typedef enum {
  AdlantisViewTransitionFadeIn,
  AdlantisViewTransitionSlideFromRight,
  AdlantisViewTransitionSlideFromLeft,
  AdlantisViewTransitionSlideFromBottom,
  AdlantisViewTransitionSlideFromTop,
  AdlantisViewTransitionNone
}AdlantisViewTransition;

///////////////////////////////////////////////////////////////////////////////////////////////////
extern NSString * const AdlantisViewAdTouchedNotification;

///////////////////////////////////////////////////////////////////////////////////////////////////
@class AdlantisAd;

///////////////////////////////////////////////////////////////////////////////////////////////////
typedef enum AdlantisViewLocation{
  AdlantisViewLocationAtTop = 0,
  AdlantisViewLocationAtBottom,
  AdlantisViewLocationElsewhere,
}AdlantisViewLocation;

///////////////////////////////////////////////////////////////////////////////////////////////////
// standard view sizes for orientation
#ifdef __cplusplus
extern "C" {
#endif
  
CGSize AdlantisViewSizeForOrientation(UIInterfaceOrientation orientation);
AdlantisViewLocation AdlantisLocationForView(UIView *view);

#ifdef __cplusplus
} /* closing brace for extern "C" */
#endif

///////////////////////////////////////////////////////////////////////////////////////////////////
@interface AdlantisView : UIView

@property (nonatomic,assign) AdlantisViewTransition defaultTransition;
@property (nonatomic,readonly) AdlantisAd *currentAd;
@property (nonatomic,assign) NSTimeInterval adFetchInterval;
@property (nonatomic,retain) NSString *publisherID;

- (IBAction)showNextAd:(id)sender;
- (IBAction)showPreviousAd:(id)sender;

- (BOOL)collapsed;
- (IBAction)collapse;
- (IBAction)uncollapse;
- (IBAction)toggleCollapse;

- (IBAction)fadeIn;
- (IBAction)fadeOut;
- (IBAction)toggleFaded;

- (IBAction)clearCache;

- (void)requestAds;

- (UIInterfaceOrientation)aspectOrientation;     // the orientation for which ads are shown

+ (CGSize)sizeForOrientation:(UIInterfaceOrientation)orientation;

@end

