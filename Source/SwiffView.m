/*
    SwiffView.m
    Copyright (c) 2011-2012, musictheory.net, LLC.  All rights reserved.

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
#import "SwiffUtils.h"
#import <SwiffLayer.h>


@interface SwiffView () <SwiffLayerDelegate>
@end


@implementation SwiffView {
    SwiffLayer *_layer;
}


- (void) dealloc
{
    [_layer clearWeakReferences];
    [_layer setSwiffLayerDelegate:nil];
}


- (void) redisplay
{
    [_layer redisplay];
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
        SwiffWarn(@"View", @"-[SwiffView initWithFrame:movie:] called with nil movie");
    }

    if ((self = [super initWithFrame:frame])) {
        _layer = [[SwiffLayer alloc] initWithMovie:movie];
        [_layer setContentsScale:[[UIScreen mainScreen] scale]];
        [[self layer] addSublayer:_layer];
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
        [_layer setContentsScale:scale];
    }
}

#endif


#pragma mark -
#pragma mark AppKit Implementation
#ifndef SwiffViewUsesUIKit

- (id) initWithFrame:(NSRect)frame movie:(SwiffMovie *)movie
{
    if (!movie) {
        SwiffWarn(@"View", @"-[SwiffView initWithFrame:movie:] called with nil movie");
    }


    if ((self = [super initWithFrame:frame])) {
        CALayer *layer = [CALayer layer];

        [layer setGeometryFlipped:YES];
        [self setLayer:layer];

        [self setWantsLayer:YES];
        
        _layer = [[SwiffLayer alloc] initWithMovie:movie];
        [[self layer] addSublayer:_layer];

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
    
    CGSize size = CGSizeMake(w, SwiffFloor(w  / aspectRatio));
    if (size.height > h) {
        size = CGSizeMake(SwiffFloor(h * aspectRatio), h);
    }

    CGRect movieFrame = CGRectMake(SwiffFloor((w - size.width) / 2.0), SwiffFloor((h - size.height) / 2.0), size.width, size.height);
    [_layer setFrame:movieFrame];
}


#pragma mark -
#pragma mark Movie Layer Delegate

- (void) layer:(SwiffLayer *)layer willUpdateCurrentFrame:(SwiffFrame *)frame
{
    if ([_delegate respondsToSelector:@selector(swiffView:willUpdateCurrentFrame:)]) {
        [_delegate swiffView:self willUpdateCurrentFrame:frame];
    }
}


- (void) layer:(SwiffLayer *)layer didUpdateCurrentFrame:(SwiffFrame *)frame
{
    if ([_delegate respondsToSelector:@selector(swiffView:didUpdateCurrentFrame:)]) {
        [_delegate swiffView:self didUpdateCurrentFrame:frame];
    }
}


- (BOOL) layer:(SwiffLayer *)layer shouldInterpolateFromFrame:(SwiffFrame *)fromFrame toFrame:(SwiffFrame *)toFrame
{
    if ([_delegate respondsToSelector:@selector(swiffView:shouldInterpolateFromFrame:toFrame:)]) {
        return [_delegate swiffView:self shouldInterpolateFromFrame:fromFrame toFrame:toFrame];
    }
        
    return NO;
}


#pragma mark -
#pragma mark Accessors

- (void) setDelegate:(id<SwiffViewDelegate>)delegate
{
    if (_delegate != delegate) {
        [_layer setSwiffLayerDelegate:(delegate ? self : nil)];
        _delegate = delegate;
    }
}


- (void) setDrawsBackground:(BOOL)drawsBackground
{
    [_layer setDrawsBackground:drawsBackground];

    if (drawsBackground) {
        [[self layer] setBackgroundColor:[_layer backgroundColor]];
    } else {
        [[self layer] setBackgroundColor:NULL];
    }
}

- (void) setMultiplyColor:(SwiffColor *)color         { [_layer setMultiplyColor:color];             }
- (void) setHairlineWidth:(CGFloat)width              { [_layer setHairlineWidth:width];             }
- (void) setFillHairlineWidth:(CGFloat)width          { [_layer setFillHairlineWidth:width];         }
- (void) setShouldAntialias:(BOOL)yn                  { [_layer setShouldAntialias:yn];              }
- (void) setShouldSmoothFonts:(BOOL)yn                { [_layer setShouldSmoothFonts:yn];            }
- (void) setShouldSubpixelPositionFonts:(BOOL)yn      { [_layer setShouldSubpixelPositionFonts:yn];  }
- (void) setShouldSubpixelQuantizeFonts:(BOOL)yn      { [_layer setShouldSubpixelQuantizeFonts:yn];  }
- (void) setShouldFlattenSublayers:(BOOL)yn           { [_layer setShouldFlattenSublayers:yn];       }
- (void) setShouldDrawDebugColors:(BOOL)yn            { [_layer setShouldDrawDebugColors:yn];        }

- (SwiffMovie    *) movie                             { return [_layer movie];                       }
- (SwiffPlayhead *) playhead                          { return [_layer playhead];                    }
- (BOOL)            drawsBackground                   { return [_layer drawsBackground];             }
- (SwiffColor    *) multiplyColor                     { return [_layer multiplyColor];               }
- (CGFloat)         hairlineWidth                     { return [_layer hairlineWidth];               }
- (CGFloat)         fillHairlineWidth                 { return [_layer fillHairlineWidth];           }       
- (BOOL)            shouldAntialias                   { return [_layer shouldAntialias];             }
- (BOOL)            shouldSmoothFonts                 { return [_layer shouldSmoothFonts];           }
- (BOOL)            shouldSubpixelPositionFonts       { return [_layer shouldSubpixelPositionFonts]; }
- (BOOL)            shouldSubpixelQuantizeFonts       { return [_layer shouldSubpixelQuantizeFonts]; }
- (BOOL)            shouldFlattenSublayers            { return [_layer shouldFlattenSublayers];      }
- (BOOL)            shouldDrawDebugColors             { return [_layer shouldDrawDebugColors];       }

@end
