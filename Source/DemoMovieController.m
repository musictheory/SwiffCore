/*
    DemoMovieController.m
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

#import "DemoMovieController.h"

static NSString * const sMovieCache = @"MovieCache";

@interface DemoMovieController ()
- (void) _loadMovie;
- (void) _loadMovieData;
- (void) _cleanupViews;
- (void) _handleSliderDidChange:(id)sender;
- (void) _handlePlayButtonTapped:(id)sender;
@end


static void sSetCachedData(NSURL *url, NSData *data) 
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dictionary = [[defaults objectForKey:sMovieCache] mutableCopy];
    if (!dictionary) {
        dictionary = [[NSMutableDictionary alloc] init];
    }
    
    [dictionary setObject:data forKey:[url absoluteString]];
    
    [defaults setObject:dictionary forKey:sMovieCache];
    [defaults synchronize];
    
    [dictionary release];
}


static NSData *sGetCachedData(NSURL *url) 
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:sMovieCache] objectForKey:[url absoluteString]];
}


@implementation DemoMovieController

- (id) initWithURL:(NSURL *)url
{
    if ((self = [self init])) {
        m_movieURL = [url retain];
    }
    
    return self;
}


- (void) dealloc
{
    [self _cleanupViews];
    
    [m_movieURL release];
    m_movieURL = nil;
    
    [super dealloc];
}


- (void) viewDidLoad
{
    [super viewDidLoad];
    
    UIView *selfView = [self view];

    CGRect bounds = [selfView bounds];
    CGFloat bottomHeight = 44.0;

    CGRect movieFrame = bounds;
    movieFrame.size.height -= bottomHeight;

    CGRect sliderFrame = CGRectInset(bounds, 128.0, 0.0);
    sliderFrame.origin.y = sliderFrame.size.height - bottomHeight;
    sliderFrame.size.height = bottomHeight;

    CGRect playButtonFrame = bounds;
    playButtonFrame.origin.x = 0.0;
    playButtonFrame.origin.y = playButtonFrame.size.height - bottomHeight;
    playButtonFrame.size.height = bottomHeight;
    playButtonFrame.size.width = 128.0;
    playButtonFrame = CGRectInset(playButtonFrame, 32.0, 0.0);

    m_movieView = [[SwiftMovieView alloc] initWithFrame:movieFrame];
    [m_movieView setDelegate:self];
    [m_movieView setContentMode:UIViewContentModeCenter];
    [m_movieView setUsesAcceleratedRendering:YES];
    [m_movieView setInterpolatesFrames:YES];
    [m_movieView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [selfView addSubview:m_movieView];

    m_timelineSlider = [[UISlider alloc] initWithFrame:sliderFrame];
    [m_timelineSlider addTarget:self action:@selector(_handleSliderDidChange:) forControlEvents:UIControlEventValueChanged];
    [m_timelineSlider setContinuous:YES];
    [m_timelineSlider setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    [selfView addSubview:m_timelineSlider];

    m_playButton = [[UIButton alloc] initWithFrame:playButtonFrame];
    [m_playButton addTarget:self action:@selector(_handlePlayButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [m_playButton setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin];
    [m_playButton setTitle:@"Play" forState:UIControlStateNormal];
    [selfView addSubview:m_playButton];

    NSData *movieData = sGetCachedData(m_movieURL);
    if (movieData) {
        m_movieData = [movieData retain];
        [self _loadMovie];
    } else {
        [self _loadMovieData];
    }
}


- (void) viewDidUnload
{
    [super viewDidUnload];
    [self _cleanupViews];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}


- (void) gotoFrameNumber:(NSInteger)frameNumber
{
    m_frameNumber = frameNumber;
    [[m_movieView playhead] setRawFrameIndex:m_frameNumber];
}


#pragma mark -
#pragma mark Private Methods

- (void) _loadMovie
{
    m_movie = [[SwiftMovie alloc] initWithData:m_movieData];
    
    [m_timelineSlider setMaximumValue:([[m_movie frames] count] - 1)];
    
    [m_movieView setMovie:m_movie];
}


- (void) _loadMovieData
{
    if ([[m_movieURL scheme] isEqualToString:@"bundle"]) {
        NSString *filename     = [m_movieURL resourceSpecifier];
        NSString *resourcePath = [[NSBundle mainBundle] pathForResource:[filename stringByDeletingPathExtension] ofType:[filename pathExtension]];
        
        if (resourcePath) {
            m_movieData = [[NSData alloc] initWithContentsOfFile:resourcePath];
            [self _loadMovie];
        }

    } else {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError       *error    = nil;
            NSURLResponse *response = nil;
            NSURLRequest  *request  = [NSURLRequest requestWithURL:m_movieURL];

            NSData *movieData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
            dispatch_async(dispatch_get_main_queue(), ^{
                m_movieData = [movieData retain];
                sSetCachedData(m_movieURL, m_movieData);

                if ([m_movieData length]) {
                    [self _loadMovie];
                };
            });
        });
    }
}


- (void) _cleanupViews
{
    [m_timelineSlider removeTarget:self action:@selector(_handleSliderDidChange:) forControlEvents:UIControlEventValueChanged];
    [m_timelineSlider release];
    m_timelineSlider = nil;

    [m_playButton removeTarget:self action:@selector(_handlePlayButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [m_playButton release];
    m_playButton = nil;

    [m_movieView setDelegate:nil];
    [m_movieView release];
    m_movieView = nil;
}


- (void) _handleSliderDidChange:(id)sender
{
    float value = [m_timelineSlider value];
    [[m_movieView playhead] setRawFrameIndex:round(value)];
}


- (void) _handlePlayButtonTapped:(id)sender
{
    BOOL isPlaying = ![m_movieView isPlaying];
    [m_movieView setPlaying:isPlaying];
    [m_playButton setTitle:(isPlaying ? @"Pause" : @"Play") forState:UIControlStateNormal];
}


#pragma mark -
#pragma mark SwiftMovieView Delegate

- (void) movieView:(SwiftMovieView *)movieView willDisplayScene:(SwiftScene *)scene frame:(SwiftFrame *)frame
{
    NSInteger i = [[movieView playhead] rawFrameIndex];
    [m_timelineSlider setValue:(float)i];
}

@end
