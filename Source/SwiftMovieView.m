/*
    SwiftMovieView.m
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

#import "SwiftMovieView.h"

#import "SwiftLayer.h"
#import "SwiftSingleLayer.h"
#import "SwiftMovie.h"
#import "SwiftMultiLayer.h"
#import "SwiftScene.h"
#import "SwiftFrame.h"
#import "SwiftPlayhead.h"
#import "SwiftSoundPlayer.h"


@interface SwiftMovieView ()
- (void) _displayLinkDidFire:(CADisplayLink *)displayLink;
@end


@implementation SwiftMovieView

- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        m_showsBackgroundColor = YES;
    }
    
    return self;
}


- (void) dealloc
{
    [m_displayLink invalidate];

    [m_movie        release];  m_movie        = nil;
    [m_playhead     release];  m_playhead     = nil;
    [m_displayLink  release];  m_displayLink  = nil;
    [m_layer        release];  m_layer        = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Superclass Overrides

- (void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsLayout];
}


- (void) layoutSubviews
{
    UIViewContentMode mode = [self contentMode];

    CGRect bounds    = [self bounds];
    CGSize movieSize = [m_movie stageRect].size;
    CGRect frame     = { CGPointZero, movieSize };

    if (mode == UIViewContentModeScaleToFill) {
        frame = bounds;

    } else if ((mode == UIViewContentModeScaleAspectFit) || (mode == UIViewContentModeScaleAspectFit)) {
        
        
    } else if (mode == UIViewContentModeScaleAspectFill) {
        
    
    } else {
        CGFloat x = 0.0, y = 0.0;

        if ((mode == UIViewContentModeTopLeft) || (mode == UIViewContentModeLeft) || (mode == UIViewContentModeBottomLeft)) {
            x = 0.0;
        } else if ((mode == UIViewContentModeTop) || (mode == UIViewContentModeCenter) || (mode == UIViewContentModeBottom)) {
            x = round((bounds.size.width - movieSize.width) / 2.0);
        } else if ((mode == UIViewContentModeTopRight) || (mode == UIViewContentModeRight) || (mode == UIViewContentModeBottomRight)) {
            x = bounds.size.width - movieSize.width;
        }

        if ((mode == UIViewContentModeTopLeft) || (mode == UIViewContentModeTop) || (mode == UIViewContentModeTopRight)) {
            y = 0.0;
        } else if ((mode == UIViewContentModeLeft) || (mode == UIViewContentModeCenter) || (mode == UIViewContentModeRight)) {
            y = round((bounds.size.height - movieSize.height) / 2.0);
        } else if ((mode == UIViewContentModeBottomLeft) || (mode == UIViewContentModeBottom) || (mode == UIViewContentModeBottomRight)) {
            y = bounds.size.height - movieSize.height;
        }

        frame = CGRectMake(x, y, movieSize.width, movieSize.height);
    }

    [m_layer setFrame:frame];
}


- (void) setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    [self setNeedsLayout];
}


- (void) willMoveToWindow:(UIWindow *)newWindow
{
    if (newWindow != [self window]) {
        CGFloat scale = [newWindow contentScaleFactor];
        if (scale < 1) scale = 1;
        [self setContentScaleFactor:scale];
        [m_layer setContentsScale:scale];

        [m_displayLink invalidate];
        [m_displayLink release];
        m_displayLink = nil;
        
        m_displayLink = [[[newWindow screen] displayLinkWithTarget:self selector:@selector(_displayLinkDidFire:)] retain]; 
        [m_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [m_displayLink setPaused:!m_playing];
        m_displayLinkPlayStart = CACurrentMediaTime();
        m_displayLinkPlayIndex = 0;
    }
}


- (void) _displayLinkDidFire:(CADisplayLink *)displayLink
{
    CFTimeInterval elapsed = ([m_displayLink timestamp] - m_displayLinkPlayStart);

    long currentIndex = (long)(elapsed * m_framesPerSecond);

    if (m_displayLinkPlayIndex != currentIndex) {
        [m_playhead step];
        m_displayLinkPlayIndex = currentIndex;
    }
}


- (void) _updateLayer
{
    Class cls = m_usesMultipleLayers ? [SwiftMultiLayer class] : [SwiftSingleLayer class];

    [m_layer removeFromSuperlayer];
    [m_layer release];

    m_layer = [[cls alloc] initWithMovie:m_movie];
    [m_layer setFrameAnimationDuration:(m_interpolatesFrames ? (1.0 / m_framesPerSecond) : 0.0)];
    [m_layer setCurrentFrame:[m_playhead frame]];

    if (m_showsBackgroundColor) {
        m_showsBackgroundColor = ~m_showsBackgroundColor;
        [self setShowsBackgroundColor:YES];
    }

    [[self layer] addSublayer:m_layer];
    
    [self layoutSubviews];
}


#pragma mark -
#pragma mark Playhead Delegate

- (void) playheadReachedEnd:(SwiftPlayhead *)playhead
{
    [self setPlaying:NO];
}


- (void) playheadDidUpdate:(SwiftPlayhead *)playhead
{
    SwiftScene *scene = [playhead scene];
    SwiftFrame *frame = [playhead frame];

    if (m_delegate_movieView_willDisplayScene_frame) {
        [m_delegate movieView:self willDisplayScene:scene frame:frame];
    }

    [[SwiftSoundPlayer sharedInstance] processMovie:m_movie frame:frame];

    [m_layer setCurrentFrame:frame];
}


#pragma mark -
#pragma mark Accessors

- (void) setMovie:(SwiftMovie *)movie
{
    if (m_movie != movie) {
        [m_movie release];
        m_movie = [movie retain];
        
        m_framesPerSecond = [m_movie frameRate];

        [m_playhead release];
        m_playhead = [[SwiftPlayhead alloc] initWithMovie:m_movie delegate:(id<SwiftPlayheadDelegate>)self];

        [self _updateLayer];

        [self setNeedsLayout];
    }
}


- (void) setUsesMultipleLayers:(BOOL)yn
{
    if (yn != m_usesMultipleLayers) {
        m_usesMultipleLayers = yn;
        [self _updateLayer];
    }
}


- (void) setInterpolatesFrames:(BOOL)yn
{
    m_interpolatesFrames = yn;
    [m_layer setFrameAnimationDuration:(yn ? (1.0 / [m_movie frameRate]) : 0.0)];
}


- (void) setDelegate:(id<SwiftMovieViewDelegate>)delegate
{
    if (delegate != m_delegate) {
        m_delegate = delegate;
        m_delegate_movieView_didDisplayScene_frame  = [delegate respondsToSelector:@selector(movieView:didDisplayScene:frame:)];
        m_delegate_movieView_willDisplayScene_frame = [delegate respondsToSelector:@selector(movieView:willDisplayScene:frame:)];
    }
} 


- (void) setPlaying:(BOOL)playing
{
    if (m_playing != playing) {
        m_playing = playing;
        [m_displayLink setPaused:!m_playing];
        m_displayLinkPlayStart = CACurrentMediaTime();
        m_displayLinkPlayIndex = 0;
    }
}


- (void) setShowsBackgroundColor:(BOOL)showsBackgroundColor
{
    if (showsBackgroundColor != m_showsBackgroundColor) {
        if (showsBackgroundColor) {
            CGColorRef backgroundColor = SwiftColorCopyCGColor([m_movie backgroundColor]);
            [m_layer setBackgroundColor:backgroundColor];
            CGColorRelease(backgroundColor);
        } else {
            [m_layer setBackgroundColor:NULL];
        }

        m_showsBackgroundColor = showsBackgroundColor;
    }
}

@synthesize movie                    = m_movie,
            delegate                 = m_delegate,
            playing                  = m_playing,
            playhead                 = m_playhead,
            showsBackgroundColor     = m_showsBackgroundColor,
            usesMultipleLayers       = m_usesMultipleLayers,
            interpolatesFrames       = m_interpolatesFrames;

@end
