/*
    SwiffFilter.h
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
#import <SwiffParser.h>

@class SwiffGradient;

typedef struct SwiffFilterInternal SwiffFilterInternal;

enum {
    SwiffFilterTypeDropShadow    = 0,
    SwiffFilterTypeBlur          = 1,
    SwiffFilterTypeGlow          = 2,
    SwiffFilterTypeBevel         = 3,
    SwiffFilterTypeGradientGlow  = 4,
    SwiffFilterTypeConvolution   = 5,
    SwiffFilterTypeColorMatrix   = 6,
    SwiffFilterTypeGradientBevel = 7
};
typedef UInt8 SwiffFilterType;


@interface SwiffFilter : NSObject {
    SwiffFilterInternal *m_internal;
}

// Reads a FILTERLIST from the parser
+ (NSArray *) filterListWithParser:(SwiffParser *)parser;

@property (nonatomic, assign, readonly) SwiffFilterType filterType;

@end


@interface SwiffFilter (Blur)

// Available when filterType=SwiffFilterTypeBlur
@property (nonatomic, assign, readonly) CGFloat blurX;
@property (nonatomic, assign, readonly) CGFloat blurY;
@property (nonatomic, assign, readonly) UInt8 numberOfPasses;

@end


@interface SwiffFilter (ColorMatrix)

// Available when filterType=SwiffFilterTypeColorMatrix
@property (nonatomic, assign, readonly) UInt8  matrixWidth;   // Always 5
@property (nonatomic, assign, readonly) UInt8  matrixHeight;  // Always 4
@property (nonatomic, assign, readonly) float *matrixValues;  // float[20]
@end


@interface SwiffFilter (Convolution)

// Available when filterType=SwiffFilterTypeConvolution
@property (nonatomic, assign, readonly) UInt8  matrixWidth;
@property (nonatomic, assign, readonly) UInt8  matrixHeight;
@property (nonatomic, assign, readonly) float *matrixValues;  // float[matrixWidth * matrixHeight]
@property (nonatomic, assign, readonly) float  divisor;
@property (nonatomic, assign, readonly) float  bias;
@property (nonatomic, assign, readonly) SwiffColor color;
@property (nonatomic, assign, readonly, getter=isClamp) BOOL clamp;
@property (nonatomic, assign, readonly) BOOL preservesAlpha;

@end


@interface SwiffFilter (DropShadow)

// Available when filterType=SwiffFilterTypeDropShadow
@property (nonatomic, assign, readonly) SwiffColor color;
@property (nonatomic, assign, readonly) CGFloat blurX;
@property (nonatomic, assign, readonly) CGFloat blurY;
@property (nonatomic, assign, readonly) CGFloat angle;
@property (nonatomic, assign, readonly) CGFloat distance;
@property (nonatomic, assign, readonly) CGFloat strength;
@property (nonatomic, assign, readonly, getter=isInnerShadow) BOOL innerShadow;
@property (nonatomic, assign, readonly, getter=isKnockout)    BOOL knockout;
@property (nonatomic, assign, readonly) UInt8 numberOfPasses;

@end


@interface SwiffFilter (Glow)

@property (nonatomic, assign, readonly) SwiffColor color;
@property (nonatomic, assign, readonly) CGFloat blurX;
@property (nonatomic, assign, readonly) CGFloat blurY;
@property (nonatomic, assign, readonly) CGFloat strength;
@property (nonatomic, assign, readonly, getter=isInnerGlow) BOOL innerGlow;
@property (nonatomic, assign, readonly, getter=isKnockout)  BOOL knockout;
@property (nonatomic, assign, readonly) UInt8 numberOfPasses;

@end


@interface SwiffFilter (Bevel)

// Available when filterType=SwiffFilterTypeBevel
@property (nonatomic, assign, readonly) SwiffColor shadowColor;
@property (nonatomic, assign, readonly) SwiffColor highlightColor;
@property (nonatomic, assign, readonly) CGFloat blurX;
@property (nonatomic, assign, readonly) CGFloat blurY;
@property (nonatomic, assign, readonly) CGFloat angle;
@property (nonatomic, assign, readonly) CGFloat distance;
@property (nonatomic, assign, readonly) CGFloat strength;
@property (nonatomic, assign, readonly, getter=isInnerShadow) BOOL innerShadow;
@property (nonatomic, assign, readonly, getter=isKnockout)    BOOL knockout;
@property (nonatomic, assign, readonly, getter=isOnTop)       BOOL onTop;
@property (nonatomic, assign, readonly) UInt8 numberOfPasses;

@end


@interface SwiffFilter (GradientGlow)

// Available when filterType=SwiffFilterTypeGradientGlow
@property (nonatomic, retain, readonly) SwiffGradient *gradient;
@property (nonatomic, assign, readonly) CGFloat blurX;
@property (nonatomic, assign, readonly) CGFloat blurY;
@property (nonatomic, assign, readonly) CGFloat strength;
@property (nonatomic, assign, readonly, getter=isInnerGlow) BOOL innerGlow;
@property (nonatomic, assign, readonly, getter=isKnockout)  BOOL knockout;
@property (nonatomic, assign, readonly) UInt8 numberOfPasses;

@end


@interface SwiffFilter (GradientBevel)

// Available when filterType=SwiffFilterTypeGradientBevel
@property (nonatomic, retain, readonly) SwiffGradient *gradient;
@property (nonatomic, assign, readonly) CGFloat blurX;
@property (nonatomic, assign, readonly) CGFloat blurY;
@property (nonatomic, assign, readonly) CGFloat angle;
@property (nonatomic, assign, readonly) CGFloat distance;
@property (nonatomic, assign, readonly) CGFloat strength;
@property (nonatomic, assign, readonly, getter=isInnerShadow) BOOL innerShadow;
@property (nonatomic, assign, readonly, getter=isKnockout)    BOOL knockout;
@property (nonatomic, assign, readonly, getter=isOnTop)       BOOL onTop;
@property (nonatomic, assign, readonly) UInt8 numberOfPasses;

@end

