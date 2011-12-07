/*
    SwiftMovieLayer.h
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

#import <SwiftBase.h>
#import <SwiftSpriteLayer.h>
#import <SwiftPlayhead.h>

@protocol SwiftMovieLayerDelegate;

@class SwiftScene;


@interface SwiftMovieLayer : SwiftSpriteLayer <SwiftPlayheadDelegate> {
@private
    id<SwiftMovieLayerDelegate> m_movieLayerDelegate;
    SwiftPlayhead *m_playhead;

    CGAffineTransform m_baseAffineTransform;
    SwiftColorTransform m_baseColorTransform;

    BOOL        m_drawsBackground;
    BOOL        m_movieLayerDelegate_movieLayer_willDisplayFrame;
    BOOL        m_movieLayerDelegate_movieLayer_didDisplayFrame;
    BOOL        m_movieLayerDelegate_movieLayer_spriteLayer_shouldInterpolateFromFrame_toFrame;
}

@property (nonatomic, assign) id<SwiftMovieLayerDelegate> movieLayerDelegate;

@property (nonatomic, retain, readonly) SwiftPlayhead *playhead;
@property (nonatomic, assign) BOOL drawsBackground;

@property (nonatomic, assign) CGAffineTransform baseAffineTransform;
@property (nonatomic, assign) SwiftColorTransform baseColorTransform;

@end


@protocol SwiftMovieLayerDelegate <NSObject>
- (void) movieLayer:(SwiftMovieLayer *)movieLayer willDisplayFrame:(SwiftFrame *)frame;
- (void) movieLayer:(SwiftMovieLayer *)movieLayer didDisplayFrame:(SwiftFrame *)frame;
- (BOOL) movieLayer:(SwiftMovieLayer *)movieLayer spriteLayer:(SwiftSpriteLayer *)spriteLayer shouldInterpolateFromFrame:(SwiftFrame *)fromFrame toFrame:(SwiftFrame *)toFrame;
@end

