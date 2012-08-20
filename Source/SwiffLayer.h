/*
    SwiffSpriteLayer.m
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

#import <SwiffTypes.h>
#import <SwiffImport.h>
#import <QuartzCore/QuartzCore.h>


@class SwiffMovie, SwiffFrame, SwiffPlacedObject, SwiffPlayhead, SwiffRenderer, SwiffSparseArray;
@protocol SwiffLayerDelegate;


@interface SwiffLayer : CALayer

- (id) initWithMovie:(SwiffMovie *)movie;

- (void) clearWeakReferences;
- (void) redisplay;

@property (nonatomic, weak) id<SwiffLayerDelegate> swiffLayerDelegate;

@property (nonatomic, strong, readonly) SwiffMovie *movie;
@property (nonatomic, strong, readonly) SwiffPlayhead *playhead;

@property (nonatomic, strong, readonly) SwiffFrame *currentFrame;

@property (nonatomic, assign) BOOL drawsBackground;

@property (nonatomic, assign) SwiffColor *multiplyColor;
@property (nonatomic, assign) CGFloat hairlineWidth;
@property (nonatomic, assign) CGFloat fillHairlineWidth;

@property (nonatomic, assign) BOOL shouldAntialias;
@property (nonatomic, assign) BOOL shouldSmoothFonts;
@property (nonatomic, assign) BOOL shouldSubpixelPositionFonts;
@property (nonatomic, assign) BOOL shouldSubpixelQuantizeFonts;
@property (nonatomic, assign) BOOL shouldFlattenSublayers;
@property (nonatomic, assign) BOOL shouldDrawDebugColors;

@end


@protocol SwiffLayerDelegate <NSObject>
- (void) layer:(SwiffLayer *)layer willUpdateCurrentFrame:(SwiffFrame *)currentFrame;
- (void) layer:(SwiffLayer *)layer didUpdateCurrentFrame:(SwiffFrame *)currentFrame;
- (BOOL) layer:(SwiffLayer *)layer shouldInterpolateFromFrame:(SwiffFrame *)fromFrame toFrame:(SwiffFrame *)toFrame;
@end
