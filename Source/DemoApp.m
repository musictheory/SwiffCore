/*
    DemoApp.m
    Copyright (c) 2011, musictheory.net, LLC.  All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
          notice, this list of conditions and the following disclaimer in the
          documentation and/or other materials provided with the distribution.
        * Neither the name of musictheory.net, LLC nor the names of its contributors
          may be used to endorse or promote products derived from this software
          without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL MUSICTHEORY.NET, LLC BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "DemoApp.h"

static NSString * const sDemoURLString = @"http://www.potterpuppetpals.com/Potter.swf";
static NSString * const sDemoDataKey   = @"DemoData";

@implementation DemoViewController

- (void) _loadMovie
{
    m_movie = [[SwiftMovie alloc] initWithData:m_movieData];
    [m_movieView setMovie:m_movie];
    [m_movieView play];
}


- (void) _loadDemoData
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSURL         *url      = [NSURL URLWithString:sDemoURLString];
        NSError       *error    = nil;
        NSURLResponse *response = nil;
        NSURLRequest  *request  = [NSURLRequest requestWithURL:url];

        NSData *movieData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            m_movieData = [movieData retain];
            [[NSUserDefaults standardUserDefaults] setObject:m_movieData forKey:sDemoDataKey];
            [[NSUserDefaults standardUserDefaults] synchronize];

            if ([m_movieData length]) {
                [self _loadMovie];
            };
        });
    });
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    UIView *selfView = [self view];

    m_movieView = [[SwiftMovieView alloc] initWithFrame:[selfView bounds]];
    [m_movieView setContentMode:UIViewContentModeScaleToFill];
    [m_movieView setUsesAcceleratedRendering:YES];
    [m_movieView setInterpolatesFrames:YES];
    [m_movieView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];

    [selfView addSubview:m_movieView];

    m_movieData = [[[NSUserDefaults standardUserDefaults] objectForKey:sDemoDataKey] retain];
    if ([m_movieData length]) {
        [self _loadMovie];
    } else {
        [self _loadDemoData];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

@end



@implementation DemoAppDelegate

- (void) dealloc
{
    [m_window release];
    [m_viewController release];

    [super dealloc];
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    m_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    m_viewController = [[DemoViewController alloc] init];

    [m_window setRootViewController:m_viewController];
    [m_window makeKeyAndVisible];

    return YES;
}

@synthesize window         = m_window,
            viewController = m_viewController;

@end
