//
//  DemoApp.m
//  Demo
//
//  Created by Ricci Adams on 2011-10-12.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

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
