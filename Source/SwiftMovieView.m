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
#import "SwiftMovie.h"


@interface SwiftMovieView ()
- (void) _setupMovieLayer;
- (void) _layoutMovieLayer;
@end


@implementation SwiftMovieView

- (void) dealloc
{
    [m_movieLayer setMovieLayerDelegate:nil];
    [m_movieLayer release];
    m_movieLayer = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark UIKit Implementation
#ifdef SwiftMovieViewUsesUIKit

- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self _setupMovieLayer];
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
    }
}

#endif


#pragma mark -
#pragma mark AppKit Implementation
#ifndef SwiftMovieViewUsesUIKit

- (id) initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        CALayer *layer = [CALayer layer];

        [layer setGeometryFlipped:YES];
        [self setLayer:layer];

        [self setWantsLayer:YES];
        
        [self _setupMovieLayer];
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

- (void) _setupMovieLayer
{
    m_movieLayer = [[SwiftMovieLayer alloc] init];
    [[self layer] addSublayer:m_movieLayer];
}


- (void) _layoutMovieLayer
{
    if (![self movie]) return;

    CGFloat w = [self bounds].size.width;
    CGFloat h = [self bounds].size.height;
    CGSize  stageSize   = [[self movie] stageRect].size;
    CGFloat aspectRatio = stageSize.width / stageSize.height;
    
    CGSize size = CGSizeMake(w, floor(w  / aspectRatio));
    if (size.height > h) {
        size = CGSizeMake(floor(h * aspectRatio), h);
    }

    CGRect movieFrame = CGRectMake(floor((w - size.width) / 2.0), floor((h - size.height) / 2.0), size.width, size.height);
    [m_movieLayer setFrame:movieFrame];
}


#pragma mark -
#pragma mark Movie Layer Delegate

- (void) movieLayer:(SwiftMovieLayer *)movieLayer willDisplayFrame:(SwiftFrame *)frame
{
    if (m_delegate_movieView_willDisplayFrame) {
        [m_delegate movieView:self willDisplayFrame:frame];
    }
}


- (void) movieLayer:(SwiftMovieLayer *)movieLayer didDisplayFrame:(SwiftFrame *)frame
{
    if (m_delegate_movieView_willDisplayFrame) {
        [m_delegate movieView:self didDisplayFrame:frame];
    }
}


- (BOOL) movieLayer:(SwiftMovieLayer *)movieLayer spriteLayer:(SwiftSpriteLayer *)spriteLayer shouldInterpolateFromFrame:(SwiftFrame *)fromFrame toFrame:(SwiftFrame *)toFrame
{
    if (m_delegate_movieView_spriteLayer_shouldInterpolateFromFrame_toFrame) {
        return [m_delegate movieView:self spriteLayer:spriteLayer shouldInterpolateFromFrame:fromFrame toFrame:toFrame];
    }
        
    return NO;
}


#pragma mark -
#pragma mark Accessors

- (void) setDelegate:(id<SwiftMovieViewDelegate>)delegate
{
    if (m_delegate != delegate) {
        [m_movieLayer setMovieLayerDelegate:(delegate ? self : nil)];

        m_delegate = delegate;
        
        m_delegate_movieView_willDisplayFrame = [m_delegate respondsToSelector:@selector(movieView:willDisplayFrame:)];
        m_delegate_movieView_didDisplayFrame  = [m_delegate respondsToSelector:@selector(movieView:didDisplayFrame:)];
        m_delegate_movieView_spriteLayer_shouldInterpolateFromFrame_toFrame = [m_delegate respondsToSelector:@selector(movieView:spriteLayer:shouldInterpolateFromFrame:toFrame:)];
    }
}


- (void) setDrawsBackground:(BOOL)drawsBackground
{
    [m_movieLayer setDrawsBackground:drawsBackground];

    if (drawsBackground) {
        [[self layer] setBackgroundColor:[m_movieLayer backgroundColor]];
    } else {
        [[self layer] setBackgroundColor:NULL];
    }
}


- (void) setMovie:(SwiftMovie *)movie
{
    [m_movieLayer setMovie:movie];
    
    if ([self drawsBackground]) {
        [[self layer] setBackgroundColor:[m_movieLayer backgroundColor]];
    }
    
    [self _layoutMovieLayer];
}


- (void) setBaseAffineTransform:(CGAffineTransform)transform
{
    [m_movieLayer setBaseAffineTransform:transform];
}


- (void) setBaseColorTransform:(SwiftColorTransform)transform
{
    [m_movieLayer setBaseColorTransform:transform];
}


- (void) setUsesSublayers:(BOOL)usesSublayers
{
    [m_movieLayer setUsesSublayers:usesSublayers];
}


- (SwiftMovie    *)     movie               { return [m_movieLayer movie];               }
- (SwiftPlayhead *)     playhead            { return [m_movieLayer playhead];            }
- (BOOL)                drawsBackground     { return [m_movieLayer drawsBackground];     }
- (BOOL)                usesSublayers       { return [m_movieLayer usesSublayers];       }
- (CGAffineTransform)   baseAffineTransform { return [m_movieLayer baseAffineTransform]; }
- (SwiftColorTransform) baseColorTransform  { return [m_movieLayer baseColorTransform];  }


@synthesize delegate = m_delegate;
@dynamic layer;

@end
