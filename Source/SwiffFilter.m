/*
    SwiffFilter.m
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


#import "SwiffFilter.h"
#import "SwiffGradient.h"



@implementation SwiffFilter

+ (NSArray *) filterListWithParser:(SwiffParser *)parser
{
    UInt8 numberOfFilters;
    SwiffParserReadUInt8(parser, &numberOfFilters);
    if (!numberOfFilters) return nil;
    
    NSMutableArray *filterList = [NSMutableArray arrayWithCapacity:numberOfFilters];

    for (NSInteger i = 0; i < numberOfFilters; i++) {
        UInt8 filterID;
        SwiffParserReadUInt8(parser, &filterID);

        Class cls = nil;

        if      (filterID == 0)  cls = [SwiffDropShadowFilter    class];
        else if (filterID == 1)  cls = [SwiffBlurFilter          class];
        else if (filterID == 2)  cls = [SwiffGlowFilter          class];
        else if (filterID == 3)  cls = [SwiffBevelFilter         class];
        else if (filterID == 4)  cls = [SwiffGradientGlowFilter  class];
        else if (filterID == 5)  cls = [SwiffConvolutionFilter   class];
        else if (filterID == 6)  cls = [SwiffColorMatrixFilter   class];
        else if (filterID == 7)  cls = [SwiffGradientBevelFilter class];
            
        if (cls) {
            SwiffFilter *filter = [[cls alloc] initWithParser:parser];
            [filterList addObject:filter];
        }
    }

    return filterList;
}


- (id) initWithParser:(SwiffParser *)parser
{
    return [super init];
}


@end


#pragma mark -
#pragma mark Blur Filter

@implementation SwiffBlurFilter

- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        SwiffParserReadFixed(parser, &m_blurX);
        SwiffParserReadFixed(parser, &m_blurY);

        UInt32 tmp;
        SwiffParserReadUBits(parser, 5, &tmp);  m_numberOfPasses = tmp;
        SwiffParserReadUBits(parser, 3, &tmp);  // Reserved UB[3]
    }

    return self;
}


@synthesize blurX          = m_blurX,
            blurY          = m_blurY,
            numberOfPasses = m_numberOfPasses;

@end


#pragma mark -
#pragma mark Color Matrix Filter

@implementation SwiffColorMatrixFilter

- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        for (NSInteger i = 0; i < 20; i++) {
            SwiffParserReadFloat(parser, &m_matrixValues[i]);
        }
    }

    return self;
}


- (UInt8)   matrixHeight { return 5; }
- (UInt8)   matrixWidth  { return 4; }
- (float *) matrixValues { return &m_matrixValues[0]; }

@end


#pragma mark -
#pragma mark Convolution Filter

@implementation SwiffConvolutionFilter

- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        SwiffParserReadUInt8(parser, &m_matrixWidth);
        SwiffParserReadUInt8(parser, &m_matrixHeight);
        SwiffParserReadFloat(parser, &m_divisor);
        SwiffParserReadFloat(parser, &m_bias);

        NSInteger count = m_matrixWidth * m_matrixHeight;

        m_matrixValues = malloc(sizeof(float) * count);
        for (NSInteger i = 0; i < count; i++) {
            SwiffParserReadFloat(parser, &m_matrixValues[i]);
        }

        UInt32 tmp;
        SwiffParserReadUBits(parser, 6, &tmp);  // Reserved UB[6]
        SwiffParserReadUBits(parser, 1, &tmp);  m_clamp = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  m_preservesAlpha = tmp;

    }

    return self;
}


- (void) dealloc
{
    free(m_matrixValues);
    m_matrixValues = NULL;
}


@synthesize matrixWidth    = m_matrixWidth,
            matrixHeight   = m_matrixHeight,
            matrixValues   = m_matrixValues,
            divisor        = m_divisor,
            bias           = m_bias,
            color          = m_color,
            clamp          = m_clamp,
            preservesAlpha = m_preservesAlpha;

@end


#pragma mark -
#pragma mark Drop Shadow Filter

@implementation SwiffDropShadowFilter

- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        SwiffParserReadColorRGBA(parser, &m_color);
        SwiffParserReadFixed(parser, &m_blurX);
        SwiffParserReadFixed(parser, &m_blurY);
        SwiffParserReadFixed(parser, &m_angle);
        SwiffParserReadFixed(parser, &m_distance);
        SwiffParserReadFixed8(parser, &m_strength);

        UInt32 tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  m_innerShadow = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  m_knockout = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  // Composite source Always 1
        SwiffParserReadUBits(parser, 5, &tmp);  m_numberOfPasses = tmp;
    }

    return self;
}

@synthesize color          = m_color,
            blurX          = m_blurX,
            blurY          = m_blurY,
            angle          = m_angle,
            distance       = m_distance,
            strength       = m_strength,
            innerShadow    = m_innerShadow,
            knockout       = m_knockout,
            numberOfPasses = m_numberOfPasses;

@end

#pragma mark -
#pragma mark Glow Filter

@implementation SwiffGlowFilter

- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        SwiffParserReadColorRGBA(parser, &m_color);
        SwiffParserReadFixed(parser, &m_blurX);
        SwiffParserReadFixed(parser, &m_blurY);
        SwiffParserReadFixed8(parser, &m_strength);

        UInt32 tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  m_innerGlow = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  m_knockout = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  // Composite source Always 1
        SwiffParserReadUBits(parser, 5, &tmp);  m_numberOfPasses = tmp;
    }
    
    return self;
}


@synthesize color = m_color,
            blurX = m_blurX,
            blurY = m_blurY,
            strength = m_strength,
            innerGlow = m_innerGlow,
            knockout = m_knockout,
            numberOfPasses = m_numberOfPasses;

@end


#pragma mark -
#pragma mark Bevel Filter

@implementation SwiffBevelFilter

- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        SwiffParserReadColorRGBA(parser, &m_shadowColor);
        SwiffParserReadColorRGBA(parser, &m_highlightColor);
        SwiffParserReadFixed(parser, &m_blurX);
        SwiffParserReadFixed(parser, &m_blurY);
        SwiffParserReadFixed(parser, &m_angle);
        SwiffParserReadFixed(parser, &m_distance);
        SwiffParserReadFixed8(parser, &m_strength);

        UInt32 tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  m_innerShadow = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  m_knockout = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  // Composite source Always 1
        SwiffParserReadUBits(parser, 1, &tmp);  m_onTop = tmp;
        SwiffParserReadUBits(parser, 4, &tmp);  m_numberOfPasses = tmp;
    }
    
    return self;
}


@synthesize shadowColor = m_shadowColor,
            highlightColor = m_highlightColor,
            blurX = m_blurX,
            blurY = m_blurY,
            angle = m_angle,
            distance = m_distance,
            strength = m_strength,
            innerShadow = m_innerShadow,
            knockout = m_knockout,
            onTop = m_onTop,
            numberOfPasses = m_numberOfPasses;

@end


#pragma mark -
#pragma mark Gradient Glow Filter

@implementation SwiffGradientGlowFilter

- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        m_gradient = [[SwiffGradient alloc] initWithParser:parser isFocalGradient:NO];

        SwiffParserReadFixed(parser, &m_blurX);
        SwiffParserReadFixed(parser, &m_blurY);
        SwiffParserReadFixed(parser, &m_angle);
        SwiffParserReadFixed(parser, &m_distance);
        SwiffParserReadFixed8(parser, &m_strength);

        UInt32 tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  m_innerGlow = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  m_knockout = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  // Composite source Always 1
        SwiffParserReadUBits(parser, 1, &tmp);  m_onTop = tmp;
        SwiffParserReadUBits(parser, 4, &tmp);  m_numberOfPasses = tmp;
    }

    return self;
}


@synthesize gradient       = m_gradient,
            blurX          = m_blurX,
            blurY          = m_blurY,
            angle          = m_angle,
            distance       = m_distance,
            strength       = m_strength,
            innerGlow      = m_innerGlow,
            knockout       = m_knockout,
            onTop          = m_onTop,
            numberOfPasses = m_numberOfPasses;

@end


#pragma mark -
#pragma mark Gradient Bevel Filter

@implementation SwiffGradientBevelFilter 

- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        m_gradient = [[SwiffGradient alloc] initWithParser:parser isFocalGradient:NO];

        SwiffParserReadFixed(parser, &m_blurX);
        SwiffParserReadFixed(parser, &m_blurY);
        SwiffParserReadFixed(parser, &m_angle);
        SwiffParserReadFixed(parser, &m_distance);
        SwiffParserReadFixed8(parser, &m_strength);

        UInt32 tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  m_innerShadow = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  m_knockout = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  // Composite source Always 1
        SwiffParserReadUBits(parser, 1, &tmp);  m_onTop = tmp;
        SwiffParserReadUBits(parser, 4, &tmp);  m_numberOfPasses = tmp;
    }
    
    return self;
}


@synthesize gradient       = m_gradient,
            blurX          = m_blurX,
            blurY          = m_blurY,
            angle          = m_angle,
            distance       = m_distance,
            strength       = m_strength,
            innerShadow    = m_innerShadow,
            knockout       = m_knockout,
            onTop          = m_onTop,
            numberOfPasses = m_numberOfPasses;

@end
