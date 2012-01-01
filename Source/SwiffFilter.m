/*
    SwiffFilter.m
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


#import "SwiffFilter.h"
#import "SwiffGradient.h"


struct SwiffFilterInternal {
    float      bias;
    float      divisor;
    CGFloat    angle;
    CGFloat    blurX;
    CGFloat    blurY;
    CGFloat    distance;
    CGFloat    strength;
    float     *matrixValues;
    id         gradient;
    SwiffColor color1;          // color and shadowColor
    SwiffColor color2;          // highlightColor
    UInt8      filterType;
    UInt8      matrixHeight;
    UInt8      matrixWidth;
    UInt8      numberOfPasses;
    BOOL       clamp;
    BOOL       inner;
    BOOL       knockout;
    BOOL       flag1;           // preservesAlpha and onTop
};


static void sReadColorMatrixFilter(SwiffParser *parser, SwiffFilterInternal *internal)
{
    internal->matrixValues = malloc(sizeof(float) * 20);
    for (NSInteger i = 0; i < 20; i++) {
        SwiffParserReadFloat(parser, &internal->matrixValues[i]);
    }
}


static void sReadConvolutionFilter(SwiffParser *parser, SwiffFilterInternal *internal)
{
    SwiffParserReadUInt8(parser, &internal->matrixWidth);
    SwiffParserReadUInt8(parser, &internal->matrixHeight);
    SwiffParserReadFloat(parser, &internal->divisor);
    SwiffParserReadFloat(parser, &internal->bias);

    NSInteger count = internal->matrixWidth * internal->matrixHeight;

    internal->matrixValues = malloc(sizeof(float) * count);
    for (NSInteger i = 0; i < count; i++) {
        SwiffParserReadFloat(parser, &internal->matrixValues[i]);
    }

    UInt32 tmp;
    SwiffParserReadUBits(parser, 6, &tmp);  // Reserved UB[6]
    SwiffParserReadUBits(parser, 1, &tmp);  internal->clamp = tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  internal->flag1 = tmp;
}


static void sReadBlurFilter(SwiffParser *parser, SwiffFilterInternal *internal)
{
    SwiffParserReadFixed(parser, &internal->blurX);
    SwiffParserReadFixed(parser, &internal->blurY);

    UInt32 tmp;
    SwiffParserReadUBits(parser, 5, &tmp);  internal->numberOfPasses = tmp;
    SwiffParserReadUBits(parser, 3, &tmp);  // Reserved UB[3]
}


static void sReadDropShadowFilter(SwiffParser *parser, SwiffFilterInternal *internal)
{
    SwiffParserReadColorRGBA(parser, &internal->color1);
    SwiffParserReadFixed(parser, &internal->blurX);
    SwiffParserReadFixed(parser, &internal->blurY);
    SwiffParserReadFixed(parser, &internal->angle);
    SwiffParserReadFixed(parser, &internal->distance);
    SwiffParserReadFixed8(parser, &internal->strength);

    UInt32 tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  internal->inner = tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  internal->knockout = tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  // Composite source Always 1
    SwiffParserReadUBits(parser, 5, &tmp);  internal->numberOfPasses = tmp;
}


static void sReadGlowFilter(SwiffParser *parser, SwiffFilterInternal *internal)
{
    SwiffParserReadColorRGBA(parser, &internal->color1);
    SwiffParserReadFixed(parser, &internal->blurX);
    SwiffParserReadFixed(parser, &internal->blurY);
    SwiffParserReadFixed8(parser, &internal->strength);

    UInt32 tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  internal->inner = tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  internal->knockout = tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  // Composite source Always 1
    SwiffParserReadUBits(parser, 5, &tmp);  internal->numberOfPasses = tmp;
}


static void sReadBevelFilter(SwiffParser *parser, SwiffFilterInternal *internal)
{
    SwiffParserReadColorRGBA(parser, &internal->color1);
    SwiffParserReadColorRGBA(parser, &internal->color2);
    SwiffParserReadFixed(parser, &internal->blurX);
    SwiffParserReadFixed(parser, &internal->blurY);
    SwiffParserReadFixed(parser, &internal->angle);
    SwiffParserReadFixed(parser, &internal->distance);
    SwiffParserReadFixed8(parser, &internal->strength);

    UInt32 tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  internal->inner = tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  internal->knockout = tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  // Composite source Always 1
    SwiffParserReadUBits(parser, 1, &tmp);  internal->flag1 = tmp;
    SwiffParserReadUBits(parser, 4, &tmp);  internal->numberOfPasses = tmp;
}


static void sReadGradientGlowFilter(SwiffParser *parser, SwiffFilterInternal *internal)
{
    internal->gradient = [[SwiffGradient alloc] initWithParser:parser isFocalGradient:NO];

    SwiffParserReadFixed(parser, &internal->blurX);
    SwiffParserReadFixed(parser, &internal->blurY);
    SwiffParserReadFixed(parser, &internal->angle);
    SwiffParserReadFixed(parser, &internal->distance);
    SwiffParserReadFixed8(parser, &internal->strength);

    UInt32 tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  internal->inner = tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  internal->knockout = tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  // Composite source Always 1
    SwiffParserReadUBits(parser, 1, &tmp);  internal->flag1 = tmp;
    SwiffParserReadUBits(parser, 4, &tmp);  internal->numberOfPasses = tmp;
}


static void sReadGradientBevelFilter(SwiffParser *parser, SwiffFilterInternal *internal)
{
    internal->gradient = [[SwiffGradient alloc] initWithParser:parser isFocalGradient:NO];

    SwiffParserReadFixed(parser, &internal->blurX);
    SwiffParserReadFixed(parser, &internal->blurY);
    SwiffParserReadFixed(parser, &internal->angle);
    SwiffParserReadFixed(parser, &internal->distance);
    SwiffParserReadFixed8(parser, &internal->strength);

    UInt32 tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  internal->inner = tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  internal->knockout = tmp;
    SwiffParserReadUBits(parser, 1, &tmp);  // Composite source Always 1
    SwiffParserReadUBits(parser, 1, &tmp);  internal->flag1 = tmp;
    SwiffParserReadUBits(parser, 4, &tmp);  internal->numberOfPasses = tmp;
}


@interface SwiffFilter ()

@property (nonatomic, assign, readonly) CGFloat bias;
@property (nonatomic, assign, readonly) CGFloat divisor;
@property (nonatomic, assign, readonly) CGFloat angle;
@property (nonatomic, assign, readonly) CGFloat blurX;
@property (nonatomic, assign, readonly) CGFloat blurY;
@property (nonatomic, assign, readonly) CGFloat distance;
@property (nonatomic, assign, readonly) CGFloat strength;

@property (nonatomic, assign, readonly) float *matrixValues;
@property (nonatomic, retain, readonly) SwiffGradient *gradient;
@property (nonatomic, assign, readonly) SwiffColor color;
@property (nonatomic, assign, readonly) SwiffColor shadowColor;
@property (nonatomic, assign, readonly) SwiffColor highlightColor;

@property (nonatomic, assign, readonly) UInt8 matrixHeight;
@property (nonatomic, assign, readonly) UInt8 matrixWidth;
@property (nonatomic, assign, readonly) UInt8 numberOfPasses;

@property (nonatomic, assign, readonly, getter=isClamp) BOOL clamp;
@property (nonatomic, assign, readonly, getter=isInnerGlow) BOOL innerGlow;
@property (nonatomic, assign, readonly, getter=isInnerShadow) BOOL innerShadow;
@property (nonatomic, assign, readonly, getter=isKnockout) BOOL knockout;
@property (nonatomic, assign, readonly, getter=isOnTop) BOOL onTop;
@property (nonatomic, assign, readonly) BOOL preservesAlpha;

@end

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

        SwiffFilterInternal *internal = calloc(1, sizeof(SwiffFilterInternal));
        internal->filterType = filterID;

        if      (filterID == SwiffFilterTypeDropShadow)    sReadDropShadowFilter(parser, internal);
        else if (filterID == SwiffFilterTypeBlur)          sReadBlurFilter(parser, internal);
        else if (filterID == SwiffFilterTypeGlow)          sReadGlowFilter(parser, internal);
        else if (filterID == SwiffFilterTypeBevel)         sReadBevelFilter(parser, internal);
        else if (filterID == SwiffFilterTypeGradientGlow)  sReadGradientGlowFilter(parser, internal);
        else if (filterID == SwiffFilterTypeConvolution)   sReadConvolutionFilter(parser, internal);
        else if (filterID == SwiffFilterTypeColorMatrix)   sReadColorMatrixFilter(parser, internal);
        else if (filterID == SwiffFilterTypeGradientBevel) sReadGradientBevelFilter(parser, internal);
            
        SwiffFilter *filter = [[SwiffFilter alloc] init];
        filter->m_internal = internal;
        [filterList addObject:filter];
        [filter release];
    }

    return filterList;
}


- (void) dealloc
{
    free(m_internal->matrixValues);

    [m_internal->gradient release];
    m_internal->gradient = nil;

    free(m_internal);
    
    [super dealloc];
}


- (CGFloat)         bias           { return m_internal->bias;           }
- (CGFloat)         divisor        { return m_internal->divisor;        }
- (CGFloat)         angle          { return m_internal->angle;          }
- (CGFloat)         blurX          { return m_internal->blurX;          }
- (CGFloat)         blurY          { return m_internal->blurY;          }
- (CGFloat)         distance       { return m_internal->distance;       }
- (CGFloat)         strength       { return m_internal->strength;       }
- (float *)         matrixValues   { return m_internal->matrixValues;   }
- (SwiffGradient *) gradient       { return m_internal->gradient;       }
- (SwiffColor)      color          { return m_internal->color1;         }
- (SwiffColor)      shadowColor    { return m_internal->color1;         }
- (SwiffColor)      highlightColor { return m_internal->color2;         }
- (SwiffFilterType) filterType     { return m_internal->filterType;     }
- (UInt8)           matrixHeight   { return m_internal->matrixHeight;   }
- (UInt8)           matrixWidth    { return m_internal->matrixWidth;    }
- (UInt8)           numberOfPasses { return m_internal->numberOfPasses; }
- (BOOL)            isClamp        { return m_internal->clamp;          }
- (BOOL)            isInnerGlow    { return m_internal->inner;          }
- (BOOL)            isInnerShadow  { return m_internal->inner;          }
- (BOOL)            isKnockout     { return m_internal->knockout;       }
- (BOOL)            isOnTop        { return m_internal->flag1;          }
- (BOOL)            preservesAlpha { return m_internal->flag1;          }

@end
