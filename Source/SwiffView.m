/*
    SwiffView.m
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

#import "SwiffView.h"
#import "SwiffMovie.h"


@interface SwiffView ()
- (void) _layoutMovieLayer;
@end


@implementation SwiffView

- (void) dealloc
{
    [m_layer clearWeakReferences];
    [m_layer setSwiffLayerDelegate:nil];
    [m_layer release];
    m_layer = nil;

    [super dealloc];
}


- (void) redisplay
{
    [m_layer redisplay];
}


#pragma mark -
#pragma mark UIKit Implementation
#ifdef SwiffViewUsesUIKit

- (id) initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame movie:nil];
}


- (id) initWithFrame:(CGRect)frame movie:(SwiffMovie *)movie
{
    if (!movie) {
        SwiffWarn(@"-[SwiffView initWithFrame:movie:] called with nil movie");
    }

    if ((self = [super initWithFrame:frame])) {
        m_layer = [[SwiffLayer alloc] initWithMovie:movie];
        [[self layer] addSublayer:m_layer];
        [self _layoutMovieLayer];
    }
    
    return self;
}


- (void) setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    [self setNeedsLayout];
}


- (void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self _layoutMovieLayer];
}


- (void) willMoveToWindow:(UIWindow *)newWindow
{
    if (newWindow != [self window]) {
        CGFloat scale = [newWindow contentScaleFactor];
        if (scale < 1) scale = 1;
        [self setContentScaleFactor:scale];
        [[self layer] setContentsScale:scale];
        [m_layer setContentsScale:scale];
    }
}

#endif


#pragma mark -
#pragma mark AppKit Implementation
#ifndef SwiffViewUsesUIKit

- (id) initWithFrame:(NSRect)frame movie:(SwiffMovie *)movie
{
    if (!movie) {
        SwiffWarn(@"-[SwiffView initWithFrame:movie:] called with nil movie");
    }


    if ((self = [super initWithFrame:frame])) {
        CALayer *layer = [CALayer layer];

        [layer setGeometryFlipped:YES];
        [self setLayer:layer];

        [self setWantsLayer:YES];
        
        m_layer = [[SwiffLayer alloc] initWithMovie:movie];
        [[self layer] addSublayer:m_layer];

        [self _layoutMovieLayer];
    }
    
    return self;
}


- (void) setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self _layoutMovieLayer];
}


#endif


#pragma mark -
#pragma mark Private Methods

- (void) _layoutMovieLayer
{
    SwiffMovie *movie = [self movie];
    if (!movie) return;

    CGFloat w = [self bounds].size.width;
    CGFloat h = [self bounds].size.height;
    CGSize  stageSize   = [movie stageRect].size;
    CGFloat aspectRatio = stageSize.width / stageSize.height;
    
    CGSize size = CGSizeMake(w, floor(w  / aspectRatio));
    if (size.height > h) {
        size = CGSizeMake(floor(h * aspectRatio), h);
    }

    CGRect movieFrame = CGRectMake(floor((w - size.width) / 2.0), floor((h - size.height) / 2.0), size.width, size.height);
    [m_layer setFrame:movieFrame];
}


#pragma mark -
#pragma mark Movie Layer Delegate

- (void) layer:(SwiffLayer *)layer didUpdateCurrentFrame:(SwiffFrame *)currentFrame
{
    if (m_delegate_swiffView_didUpdateCurrentFrame) {
        [m_delegate swiffView:self didUpdateCurrentFrame:currentFrame];
    }
}


- (BOOL) layer:(SwiffLayer *)layer shouldInterpolateFromFrame:(SwiffFrame *)fromFrame toFrame:(SwiffFrame *)toFrame
{
    if (m_delegate_swiffView_shouldInterpolateFromFrame_toFrame) {
        return [m_delegate swiffView:self shouldInterpolateFromFrame:fromFrame toFrame:toFrame];
    }
        
    return NO;
}


#pragma mark -
#pragma mark Accessors

- (void) setDelegate:(id<SwiffViewDelegate>)delegate
{
    if (m_delegate != delegate) {
        [m_layer setSwiffLayerDelegate:(delegate ? self : nil)];

        m_delegate = delegate;
        
        m_delegate_swiffView_didUpdateCurrentFrame  = [m_delegate respondsToSelector:@selector(swiffView:didUpdateCurrentFrame:)];
        m_delegate_swiffView_shouldInterpolateFromFrame_toFrame = [m_delegate respondsToSelector:@selector(swiffView:shouldInterpolateFromFrame:toFrame:)];
    }
}


- (void) setDrawsBackground:(BOOL)drawsBackground
{
    [m_layer setDrawsBackground:drawsBackground];

    if (drawsBackground) {
        [[self layer] setBackgroundColor:[m_layer backgroundColor]];
    } else {
        [[self layer] setBackgroundColor:NULL];
    }
}


- (void) setTintColor:(SwiffColor *)color
{
    [m_layer setTintColor:color];
}


- (void) setHairlineWidth:(CGFloat)hairlineWidth
{
    [m_layer setHairlineWidth:hairlineWidth];
}


- (void) setHairlineWithFillWidth:(CGFloat)hairlineWidth
{
    [m_layer setHairlineWithFillWidth:hairlineWidth];
}


- (SwiffMovie    *) movie                 { return [m_layer movie];           }
- (SwiffPlayhead *) playhead              { return [m_layer playhead];        }
- (BOOL)            drawsBackground       { return [m_layer drawsBackground]; }
- (SwiffColor    *) tintColor             { return [m_layer tintColor];       }
- (CGFloat)         hairlineWidth         { return [m_layer hairlineWidth];   }
- (CGFloat)         hairlineWithFillWidth { return [m_layer hairlineWithFillWidth]; }

@synthesize delegate = m_delegate;

@end
