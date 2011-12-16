/*
    SwiffMovieLayer.m
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

#import "SwiffMovieLayer.h"

#import "SwiffMovie.h"
#import "SwiffPlayhead.h"
#import "SwiffSoundPlayer.h"


@interface SwiffSpriteLayer (Protected)
- (CGAffineTransform) _baseAffineTransform;
- (void) _setNeedsLayoutOnAll;
- (void) _setNeedsDisplayOnAll;
@end


@implementation SwiffMovieLayer

- (id) init
{
    if ((self = [super init])) {
        m_baseAffineTransform = CGAffineTransformIdentity;
        m_baseColorTransform  = SwiffColorTransformIdentity;
        m_postColorTransform  = SwiffColorTransformIdentity;
    }

    return self;
}


- (void) dealloc
{
    [m_playhead setDelegate:nil];
    [m_playhead release];
    m_playhead = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods

- (void) _updateBackgroundColor
{
    SwiffColor *backgroundColorPointer = [[self movie] backgroundColorPointer];

    if (m_drawsBackground && backgroundColorPointer) {
        CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
        CGColorRef color = CGColorCreate(rgb, (CGFloat *)backgroundColorPointer); 
        
        [self setBackgroundColor:color];

        if (color) CFRelease(color);
        if (rgb)   CFRelease(rgb);

    } else {
        [self setBackgroundColor:NULL];
    }
}


#pragma mark -
#pragma mark Overrides

- (BOOL) _spriteLayer:(SwiffSpriteLayer *)layer shouldInterpolateFromFrame:(SwiffFrame *)fromFrame toFrame:(SwiffFrame *)toFrame
{
    if (m_movieLayerDelegate_movieLayer_spriteLayer_shouldInterpolateFromFrame_toFrame) {
        return [m_movieLayerDelegate movieLayer:self spriteLayer:layer shouldInterpolateFromFrame:fromFrame toFrame:toFrame];
    }
    
    return NO;
}


- (CGAffineTransform) _baseAffineTransform
{
    CGAffineTransform superTransform = [super _baseAffineTransform];
    return CGAffineTransformConcat(m_baseAffineTransform, superTransform);
}


- (SwiffColorTransform *) _baseColorTransform
{
    return &m_baseColorTransform;
}


- (SwiffColorTransform *) _postColorTransform
{
    return &m_postColorTransform;
}


#pragma mark -
#pragma mark Playhead Delegate

- (void) playheadDidUpdate:(SwiffPlayhead *)playhead
{
    SwiffFrame *frame = [playhead frame];

    if (m_movieLayerDelegate_movieLayer_willDisplayFrame) {
        [m_movieLayerDelegate movieLayer:self willDisplayFrame:frame];
    }

    [[SwiffSoundPlayer sharedInstance] processMovie:m_movie frame:frame];

    [self setCurrentFrame:frame];
}


#pragma mark -
#pragma mark Accessors

- (void) setMovie:(SwiffMovie *)movie
{
    if (movie != [self movie]) {
        [super setMovie:movie];
        
        [m_playhead setDelegate:nil];
        [m_playhead release];
        m_playhead = [[SwiffPlayhead alloc] initWithMovie:m_movie delegate:self];
        [m_playhead gotoFrameWithIndex:0 play:NO];
        
        [self _updateBackgroundColor];

        [self playheadDidUpdate:m_playhead];
    }
}


- (void) setMovieLayerDelegate:(id<SwiffMovieLayerDelegate>)delegate
{
    if (m_movieLayerDelegate != delegate) {
        m_movieLayerDelegate = delegate;

        m_movieLayerDelegate_movieLayer_willDisplayFrame = [m_movieLayerDelegate respondsToSelector:@selector(movieLayer:willDisplayFrame:)];
        m_movieLayerDelegate_movieLayer_didDisplayFrame  = [m_movieLayerDelegate respondsToSelector:@selector(movieLayer:didDisplayFrame:)];
        m_movieLayerDelegate_movieLayer_spriteLayer_shouldInterpolateFromFrame_toFrame = [m_movieLayerDelegate respondsToSelector:@selector(movieLayer:spriteLayer:shouldInterpolateFromFrame:toFrame:)];
    }
}


- (void) setDrawsBackground:(BOOL)drawsBackground
{
    if (m_drawsBackground != drawsBackground) {
        m_drawsBackground = drawsBackground;
        [self _updateBackgroundColor];
    }
}


- (void) setBaseAffineTransform:(CGAffineTransform)baseAffineTransform
{
    if (!CGAffineTransformEqualToTransform(baseAffineTransform, m_baseAffineTransform)) {
        m_baseAffineTransform = baseAffineTransform;
        [self _setNeedsLayoutOnAll];
        [self _setNeedsDisplayOnAll];
    }
}


- (void) setBaseColorTransform:(SwiffColorTransform)baseColorTransform
{
    if (!SwiffColorTransformEqualToTransform(&baseColorTransform, &m_baseColorTransform)) {
        m_baseColorTransform = baseColorTransform;
        [self _setNeedsDisplayOnAll];
    }
}


- (void) setPostColorTransform:(SwiffColorTransform)postColorTransform
{
    if (!SwiffColorTransformEqualToTransform(&postColorTransform, &m_postColorTransform)) {
        m_postColorTransform = postColorTransform;
        [self _setNeedsDisplayOnAll];
    }
}


@synthesize movieLayerDelegate  = m_movieLayerDelegate,
            playhead            = m_playhead,
            drawsBackground     = m_drawsBackground,
            baseAffineTransform = m_baseAffineTransform,
            baseColorTransform  = m_baseColorTransform,
            postColorTransform  = m_postColorTransform;

@end
