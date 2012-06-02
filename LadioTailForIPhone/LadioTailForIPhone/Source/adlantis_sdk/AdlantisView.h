//
//  AdlantisView.h
//  AdLantis iOS SDK
//
//  Created on 10/16/09.
//  Copyright 2009 Atlantiss.jp. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif

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
@class AdlantisAdView, AdlantisAd, AdlantisViewSwapper;

///////////////////////////////////////////////////////////////////////////////////////////////////
typedef enum AdlantisViewLocation{
  AdlantisViewLocationAtTop = 0,
  AdlantisViewLocationAtBottom,
  AdlantisViewLocationElsewhere,
}AdlantisViewLocation;

///////////////////////////////////////////////////////////////////////////////////////////////////
// standard view sizes for orientation
CGSize AdlantisViewSizeForOrientation(UIInterfaceOrientation orientation);
AdlantisViewLocation AdlantisLocationForView(UIView *view);

///////////////////////////////////////////////////////////////////////////////////////////////////
@interface AdlantisView : UIView {
@private
  AdlantisAdView *adView1, *adView2;
  AdlantisViewSwapper *_viewSwapper;
  
  NSTimeInterval _animationDuration;
  
  UIView *buttonOverlay;
  BOOL buttonDown;
  NSTimeInterval initialTouchTimestamp;
  CGPoint initialTouchLocation;
  BOOL _collapsed;
  BOOL isAnimating;

  UIInterfaceOrientation previous_orientation;
  AdlantisAd *_currentAd;
  BOOL receiveAds,previewIsBeingShown;
  
  UIView *activityIndicatorLayer;
  UIActivityIndicatorView *activityIndicator;
  UIImageView *failImageView;
}

@property(nonatomic,readonly) BOOL collapsed;
@property(nonatomic,assign) AdlantisViewTransition defaultTransition;
@property(nonatomic,retain) AdlantisAd *currentAd;
@property(nonatomic,assign) NSTimeInterval animationDuration;

-(IBAction)showNextAd:(id)sender;
-(IBAction)showPreviousAd:(id)sender;

-(IBAction)collapse;
-(IBAction)uncollapse;
-(IBAction)toggleCollapse;

-(IBAction)fadeIn;
-(IBAction)fadeOut;
-(IBAction)toggleFaded;

-(IBAction)clearCache;

-(IBAction)showActivityIndicator;
-(IBAction)hideActivityIndicator;
-(BOOL)activityIndicatorVisible;
-(IBAction)toggleActivityIndicatorVisibility;
-(IBAction)showFailureIndicator;

-(UIInterfaceOrientation)aspectOrientation;     // the orientation for which ads are shown

@end
  
#ifdef __cplusplus
} /* closing brace for extern "C" */
#endif

