/*
    SwiffView.h
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
#import <SwiffLayer.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR || TARGET_HAS_UIKIT
#define SwiffViewUsesUIKit 1
#endif

#if SwiffViewUsesUIKit
#import <UIKit/UIKit.h>
#define SwiffViewSuperclass UIView
#define SwiffViewRect       CGRect
#else
#import <AppKit/AppKit.h>
#define SwiffViewSuperclass NSView
#define SwiffViewRect       NSRect
#endif


@class SwiffLayer, SwiffMovie, SwiffFrame, SwiffPlayhead;

@protocol SwiffViewDelegate;

@interface SwiffView : SwiffViewSuperclass <SwiffLayerDelegate> {
@private
    id<SwiffViewDelegate> m_delegate;
    SwiffLayer           *m_layer;
    
    BOOL m_delegate_swiffView_didUpdateCurrentFrame;
    BOOL m_delegate_swiffView_shouldInterpolateFromFrame_toFrame;
}

- (id) initWithFrame:(SwiffViewRect)frame movie:(SwiffMovie *)movie;

- (void) redisplay;

@property (nonatomic, assign) id<SwiffViewDelegate> delegate;

@property (nonatomic, retain, readonly) SwiffMovie *movie;
@property (nonatomic, retain, readonly) SwiffPlayhead *playhead;

@property (nonatomic, assign) BOOL drawsBackground;

@property (nonatomic, assign) SwiffColor *multiplyColor;
@property (nonatomic, assign) CGFloat hairlineWidth;
@property (nonatomic, assign) CGFloat fillHairlineWidth;

@property (nonatomic, assign) BOOL shouldAntialias;
@property (nonatomic, assign) BOOL shouldSmoothFonts;
@property (nonatomic, assign) BOOL shouldSubpixelPositionFonts;
@property (nonatomic, assign) BOOL shouldSubpixelQuantizeFonts;
@property (nonatomic, assign) BOOL shouldFlattenSublayersWhenStopped;


@end


@protocol SwiffViewDelegate <NSObject>
@optional
- (void) swiffView:(SwiffView *)swiffView didUpdateCurrentFrame:(SwiffFrame *)frame;
- (BOOL) swiffView:(SwiffView *)swiffView shouldInterpolateFromFrame:(SwiffFrame *)fromFrame toFrame:(SwiffFrame *)toFrame;
@end
