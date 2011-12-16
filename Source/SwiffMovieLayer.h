/*
    SwiffMovieLayer.h
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

#import <SwiffBase.h>
#import <SwiffSpriteLayer.h>
#import <SwiffPlayhead.h>

@protocol SwiffMovieLayerDelegate;

@class SwiffScene;


@interface SwiffMovieLayer : SwiffSpriteLayer <SwiffPlayheadDelegate> {
@private
    id<SwiffMovieLayerDelegate> m_movieLayerDelegate;
    SwiffPlayhead *m_playhead;

    CGAffineTransform   m_baseAffineTransform;
    SwiffColorTransform m_baseColorTransform;
    SwiffColorTransform m_postColorTransform;

    BOOL        m_drawsBackground;
    BOOL        m_movieLayerDelegate_movieLayer_willDisplayFrame;
    BOOL        m_movieLayerDelegate_movieLayer_didDisplayFrame;
    BOOL        m_movieLayerDelegate_movieLayer_spriteLayer_shouldInterpolateFromFrame_toFrame;
}

@property (nonatomic, assign) id<SwiffMovieLayerDelegate> movieLayerDelegate;

@property (nonatomic, retain, readonly) SwiffPlayhead *playhead;
@property (nonatomic, assign) BOOL drawsBackground;

@property (nonatomic, assign) CGAffineTransform baseAffineTransform;
@property (nonatomic, assign) SwiffColorTransform baseColorTransform;
@property (nonatomic, assign) SwiffColorTransform postColorTransform;

@end


@protocol SwiffMovieLayerDelegate <NSObject>
- (void) movieLayer:(SwiffMovieLayer *)movieLayer willDisplayFrame:(SwiffFrame *)frame;
- (void) movieLayer:(SwiffMovieLayer *)movieLayer didDisplayFrame:(SwiffFrame *)frame;
- (BOOL) movieLayer:(SwiffMovieLayer *)movieLayer spriteLayer:(SwiffSpriteLayer *)spriteLayer shouldInterpolateFromFrame:(SwiffFrame *)fromFrame toFrame:(SwiffFrame *)toFrame;
@end

