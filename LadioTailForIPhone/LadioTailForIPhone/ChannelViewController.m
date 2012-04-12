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

#import "Player.h"
#import "LadioLib/LadioLib.h"
#import "ChannelViewController.h"

@implementation ChannelViewController

@synthesize channel;
@synthesize topNavigationItem;
@synthesize playButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        channel = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self playButtonChange:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playButtonChange:) name:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:nil];

    topNavigationItem.title = channel.nam;
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NAME_PLAY_STATE_CHANGED object:nil];

    [self setTopNavigationItem:nil];
    [self setPlayButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)play:(id)sender
{

    NSURL *url = [channel getPlayUrl];
    Player *player = [Player getPlayer];
    if ([player isPlayUrl:url]) {
        [player stop];
    } else {
        [player play:url];
    }
}

- (void)playButtonChange:(NSNotification *)notification
{
    NSURL *url = [channel getPlayUrl];
    Player *player = [Player getPlayer];
    if ([player isPlayUrl:url]) {
        [playButton setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [playButton setTitle:@"Play" forState:UIControlStateNormal];
    }
}
@end
