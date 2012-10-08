/*
 * Copyright (c) 2012 Yuichi Hirano
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

#import "ViewDeck/IIViewDeckController.h"
#import "GRMustache/GRMustache.h"
#import "LadioTailConfig.h"
#import "AboutViewController.h"

@implementation AboutViewController

#pragma mark - Actions

- (IBAction)openSideMenu:(id)sender;
{
    [self.viewDeckController toggleLeftViewAnimated:YES];
}

#pragma mark UIView methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"About Ladio Tail", @"Ladio Tailについて");

    // メニューボタンの色を変更する
    _sideMenuBarButtonItem.tintColor = SIDEMENU_BUTTON_COLOR;

    NSString *versionNumberString = [[NSBundle mainBundle] infoDictionary][(NSString*)kCFBundleVersionKey];
    NSString *versionInfo = [[NSString alloc] initWithFormat:@"Version %@", versionNumberString];

    NSError *error = nil;
#if DEBUG
    NSString *buildDate = [[NSBundle mainBundle] infoDictionary][@"CFBuildDate"];
    NSDictionary *dict = @{@"version_info":versionInfo, @"build_date":buildDate};
#else
    NSDictionary *dict = @{@"version_info":versionInfo};
#endif /* #if DEBUG */
    NSString *html = [GRMustacheTemplate renderObject:dict
                                        fromResource:@"AboutHtml"
                                       withExtension:@"mustache"
                                              bundle:[NSBundle mainBundle]
                                               error:&error];
    if (error != nil) {
        NSLog(@"GRMustacheTemplate parse error. Error: %@", [error localizedDescription]);
    }

    [_webView loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        switch (interfaceOrientation) {
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
                return YES;
            case UIInterfaceOrientationPortraitUpsideDown:
            default:
                return NO;
        }
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

- (BOOL)shouldAutorotate
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return NO;
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
