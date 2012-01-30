/*
    SwiffFillStyle.m
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

#import "SwiffFillStyle.h"
#import "SwiffParser.h"
#import "SwiffGradient.h"

#define IS_COLOR_TYPE    (m_type == SwiffFillStyleTypeColor)

#define IS_GRADIENT_TYPE ((m_type == SwiffFillStyleTypeLinearGradient) || \
                          (m_type == SwiffFillStyleTypeRadialGradient) || \
                          (m_type == SwiffFillStyleTypeFocalRadialGradient))

#define IS_BITMAP_TYPE   ((m_type >= SwiffFillStyleTypeRepeatingBitmap) && (m_type <= SwiffFillStyleTypeNonSmoothedClippedBitmap))

@implementation SwiffFillStyle

+ (NSArray *) fillStyleArrayWithParser:(SwiffParser *)parser
{
    UInt8 count8;
    NSInteger count;

    SwiffParserReadUInt8(parser, &count8);
    if (count8 == 0xFF) {
        UInt16 count16;
        SwiffParserReadUInt16(parser, &count16);
        count = count16;

    } else {
        count = count8;
    }
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];

    for (NSInteger i = 0; i < count; i++) {
        SwiffFillStyle *fillStyle = [[self alloc] initWithParser:parser];

        if (fillStyle) {
            [array addObject:fillStyle];
        } else {
            return nil;
        }
    }

    return array;
}


- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [self init])) {
        SwiffParserReadUInt8(parser, &m_type);

        if (IS_COLOR_TYPE) {
            SwiffTag  tag     = SwiffParserGetCurrentTag(parser);
            NSInteger version = SwiffParserGetCurrentTagVersion(parser);
        
            if ((tag == SwiffTagDefineShape) && (version >= 3)) {
                SwiffParserReadColorRGBA(parser, &m_color);
            } else {
                SwiffParserReadColorRGB(parser, &m_color);
            }

        } else if (IS_GRADIENT_TYPE) {
            SwiffParserReadMatrix(parser, &m_transform);
            BOOL isFocalGradient = (m_type == SwiffFillStyleTypeFocalRadialGradient);

            m_gradient = [[SwiffGradient alloc] initWithParser:parser isFocalGradient:isFocalGradient];

        } else if (IS_BITMAP_TYPE) {
            SwiffParserReadUInt16(parser, &m_bitmapID);
            SwiffParserReadMatrix(parser, &m_transform);

            m_transform.a /= 20.0;
            m_transform.d /= 20.0;

        } else {
            return nil;
        }

        if (!SwiffParserIsValid(parser)) {
            return nil;
        }
    }

    return self;
}


- (NSString *) description
{
    NSString *typeString = nil;

    if (m_type == SwiffFillStyleTypeColor) {

        typeString = [NSString stringWithFormat:@"#%02lX%02lX%02lX, %ld%%",
            (long)(m_color.red   * 255.0),
            (long)(m_color.green * 255.0),
            (long)(m_color.blue  * 255.0),
            (long)(m_color.alpha * 100.0)
        ];

    } else if (m_type == SwiffFillStyleTypeLinearGradient) {
        typeString = @"LinearGradient";
    } else if (m_type == SwiffFillStyleTypeRadialGradient) {
        typeString = @"RadialGradient";
    } else if (m_type == SwiffFillStyleTypeFocalRadialGradient) {
        typeString = @"FocalRadialGradient";
    } else if (m_type == SwiffFillStyleTypeRepeatingBitmap) {
        typeString = @"RepeatingBitmap";
    } else if (m_type == SwiffFillStyleTypeClippedBitmap) {
        typeString = @"ClippedBitmap";
    } else if (m_type == SwiffFillStyleTypeNonSmoothedRepeatingBitmap) {
        typeString = @"NonSmoothedRepeatingBitmap";
    } else if (m_type == SwiffFillStyleTypeNonSmoothedClippedBitmap) {
        typeString = @"NonSmoothedClippedBitmap";
    }

    return [NSString stringWithFormat:@"<%@: %p; %@>", [self class], self, typeString];
}


#pragma mark -
#pragma mark Accessors

- (SwiffColor *) colorPointer
{
    return IS_COLOR_TYPE ? &m_color : NULL;
}


- (CGAffineTransform) gradientTransform
{
    return IS_GRADIENT_TYPE ? m_transform : CGAffineTransformIdentity;
}


- (CGAffineTransform) bitmapTransform
{
    return IS_BITMAP_TYPE ? m_transform : CGAffineTransformIdentity;
}


@synthesize type     = m_type,
            color    = m_color,
            gradient = m_gradient,
            bitmapID = m_bitmapID;


@end
