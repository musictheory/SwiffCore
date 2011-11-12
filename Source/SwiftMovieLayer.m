/*
    SwiftMovieLayer.m
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

#import "SwiftMovieLayer.h"

#import "SwiftMovie.h"
#import "SwiftPlayhead.h"
#import "SwiftSoundPlayer.h"


@implementation SwiftMovieLayer

- (void) dealloc
{
    [m_playhead setDelegate:nil];
    [m_playhead release];
    m_playhead = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods

- (BOOL) _spriteLayer:(SwiftSpriteLayer *)layer shouldInterpolateFromFrame:(SwiftFrame *)fromFrame toFrame:(SwiftFrame *)toFrame
{
    if (m_movieLayerDelegate_movieLayer_spriteLayer_shouldInterpolateFromFrame_toFrame) {
        return [m_movieLayerDelegate movieLayer:self spriteLayer:layer shouldInterpolateFromFrame:fromFrame toFrame:toFrame];
    }
    
    return NO;
}



#pragma mark -
#pragma mark Playhead Delegate

- (void) playheadDidUpdate:(SwiftPlayhead *)playhead
{
    SwiftFrame *frame = [playhead frame];

    if (m_movieLayerDelegate_movieLayer_willDisplayFrame) {
        [m_movieLayerDelegate movieLayer:self willDisplayFrame:frame];
    }

    [[SwiftSoundPlayer sharedInstance] processMovie:m_movie frame:frame];

    [self setCurrentFrame:frame];
}


#pragma mark -
#pragma mark Accessors

- (void) setMovie:(SwiftMovie *)movie
{
    if (movie != [self movie]) {
        [super setMovie:movie];
        
        [m_playhead setDelegate:nil];
        [m_playhead release];
        m_playhead = [[SwiftPlayhead alloc] initWithMovie:m_movie delegate:self];
    }
}


- (void) setMovieLayerDelegate:(id<SwiftMovieLayerDelegate>)delegate
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
    if ([self drawsBackground] != drawsBackground) {
        if (drawsBackground) {
            CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
            CGColorRef color = CGColorCreate(rgb, (CGFloat *)[[self movie] backgroundColorPointer]); 
            
            [self setBackgroundColor:color];

            CFRelease(color);
            CFRelease(rgb);

        } else {
            [self setBackgroundColor:NULL];
        }
    }
}


- (BOOL) drawsBackground
{
    return [self backgroundColor] != nil;
}


@synthesize movieLayerDelegate = m_movieLayerDelegate,
            playhead           = m_playhead;

@end
