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

#define LAYER ((SwiftMovieLayer *)[self layer])

@implementation SwiftMovieView


#pragma mark -
#pragma mark UIKit Implementation
#ifdef SwiftMovieViewUsesUIKit

+ (Class) layerClass
{
    return [SwiftMovieLayer class];
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
        [[self layer] setContentsScale:scale];
    }
}

#endif


#pragma mark -
#pragma mark AppKit Implementation
#ifndef SwiftMovieViewUsesUIKit

#endif


#pragma mark
#pragma mark

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
        [LAYER setMovieLayerDelegate:(delegate ? self : nil)];

        m_delegate = delegate;
        
        m_delegate_movieView_willDisplayFrame = [m_delegate respondsToSelector:@selector(movieView:willDisplayFrame:)];
        m_delegate_movieView_didDisplayFrame  = [m_delegate respondsToSelector:@selector(movieView:didDisplayFrame:)];
        m_delegate_movieView_spriteLayer_shouldInterpolateFromFrame_toFrame = [m_delegate respondsToSelector:@selector(movieView:spriteLayer:shouldInterpolateFromFrame:toFrame:)];
    }
}

- (void) setMovie:(SwiftMovie *)movie             { [LAYER setMovie:movie]; }
- (void) setDrawsBackground:(BOOL)drawsBackground { [LAYER setDrawsBackground:drawsBackground]; }
- (void) setUsesSublayers:(BOOL)usesSublayers     { [LAYER setUsesSublayers:usesSublayers]; }

- (SwiftMovie    *) movie    { return [LAYER movie];           }
- (SwiftPlayhead *) playhead { return [LAYER playhead];        }
- (BOOL) drawsBackground     { return [LAYER drawsBackground]; }
- (BOOL) usesSublayers       { return [LAYER usesSublayers];   }

@synthesize delegate = m_delegate;
@dynamic layer;

@end
