/*
 * Copyright (c) 2012 Y.Hirano
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <UIKit/UIKit.h>
#import "iAd/iAd.h"

@interface WebPageViewController : UIViewController <UIWebViewDelegate, ADBannerViewDelegate>

@property (strong) NSURL *url;

@property (weak, nonatomic) IBOutlet UINavigationItem *topNavigationItem;

@property (weak, nonatomic) IBOutlet UIWebView *pageWebView;

@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) IBOutlet UIButton *forwardButton;

@property (weak, nonatomic) IBOutlet UIButton *reloadButton;

@property (weak, nonatomic) IBOutlet UIView *bottomView;

- (IBAction)back:(id)sender;

- (IBAction)forward:(id)sender;

- (IBAction)goToBottom:(id)sender;

- (IBAction)reload:(id)sender;

@end
