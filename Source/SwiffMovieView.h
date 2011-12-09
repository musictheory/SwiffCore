/*
    SwiffMovieView.h
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

#import <SwiffImport.h>
#import <SwiffBase.h>
#import <SwiffMovieLayer.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR || TARGET_HAS_UIKIT
#define SwiffMovieViewUsesUIKit 1
#endif

#if SwiffMovieViewUsesUIKit
#import <UIKit/UIKit.h>
#define SwiffMovieViewSuperclass UIView
#else
#import <AppKit/AppKit.h>
#define SwiffMovieViewSuperclass NSView
#endif


@class SwiffLayer, SwiffMovie, SwiffFrame, SwiffPlayhead;
@class SwiffMovieLayer, SwiffSpriteLayer;

@protocol SwiffMovieViewDelegate;

@interface SwiffMovieView : SwiffMovieViewSuperclass <SwiffMovieLayerDelegate> {
@private
    id<SwiffMovieViewDelegate> m_delegate;
    SwiffMovieLayer *m_movieLayer;
    
    BOOL m_delegate_movieView_willDisplayFrame;
    BOOL m_delegate_movieView_didDisplayFrame;
    BOOL m_delegate_movieView_spriteLayer_shouldInterpolateFromFrame_toFrame;
}

@property (nonatomic, retain) SwiffMovie *movie;

@property (nonatomic, assign) id<SwiffMovieViewDelegate> delegate;
@property (nonatomic, assign) BOOL drawsBackground;
@property (nonatomic, assign) BOOL usesSublayers;
@property (nonatomic, assign) CGAffineTransform baseAffineTransform;
@property (nonatomic, assign) SwiffColorTransform baseColorTransform;

@property (nonatomic, retain, readonly) SwiffMovieLayer *layer;
@property (nonatomic, retain, readonly) SwiffPlayhead *playhead;


@end


@protocol SwiffMovieViewDelegate <NSObject>
@optional
- (void) movieView:(SwiffMovieView *)movieView willDisplayFrame:(SwiffFrame *)frame;
- (void) movieView:(SwiffMovieView *)movieView didDisplayFrame:(SwiffFrame *)frame;
- (BOOL) movieView:(SwiffMovieView *)movieView spriteLayer:(SwiffSpriteLayer *)spriteLayer shouldInterpolateFromFrame:(SwiffFrame *)fromFrame toFrame:(SwiffFrame *)toFrame;
@end
