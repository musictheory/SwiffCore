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
            [fillStyle release];
        } else {
            return nil;
        }
    }

    return array;
}


- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [self init])) {
        UInt8 type;
        SwiffParserReadUInt8(parser, &type);
        m_type = type;

        if (IS_COLOR_TYPE) {
            SwiffTag  tag     = SwiffParserGetCurrentTag(parser);
            NSInteger version = SwiffParserGetCurrentTagVersion(parser);
        
            if ((tag == SwiffTagDefineShape) && (version >= 3)) {
                SwiffParserReadColorRGBA(parser, &m_content.color);
            } else {
                SwiffParserReadColorRGB(parser, &m_content.color);
            }

        } else if (IS_GRADIENT_TYPE) {
            SwiffParserReadMatrix(parser, &m_content.gradientTransform);
            BOOL isFocalGradient = (m_type == SwiffFillStyleTypeFocalRadialGradient);
            m_content.gradient = [[SwiffGradient alloc] initWithParser:parser isFocalGradient:isFocalGradient];

        } else if (IS_BITMAP_TYPE) {
            UInt16 bitmapID;
            SwiffParserReadUInt16(parser, &bitmapID);
            m_content.bitmapID = bitmapID;

            SwiffParserReadMatrix(parser, &m_content.bitmapTransform);

            m_content.bitmapTransform.a /= 20.0;
            m_content.bitmapTransform.d /= 20.0;

        } else {
            [self release];
            return nil;
        }

        if (!SwiffParserIsValid(parser)) {
            [self release];
            return nil;
        }
    }

    return self;
}


- (void) dealloc
{
    if (IS_GRADIENT_TYPE) {
        [m_content.gradient release];
        m_content.gradient = nil;
    }

    [super dealloc];
}


- (NSString *) description
{
    NSString *typeString = nil;

    if (m_type == SwiffFillStyleTypeColor) {

        typeString = [NSString stringWithFormat:@"#%02lX%02lX%02lX, %ld%%",
            (long)(m_content.color.red   * 255.0),
            (long)(m_content.color.green * 255.0),
            (long)(m_content.color.blue  * 255.0),
            (long)(m_content.color.alpha * 100.0)
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
    if (IS_COLOR_TYPE) {
        return &m_content.color;
    } else {
        return NULL;
    }
}


- (SwiffColor) color
{
    if (IS_COLOR_TYPE) {
        return m_content.color;
    } else {
        SwiffColor color = { 0, 0, 0, 0 };
        return color;
    }
}


- (SwiffGradient *) gradient
{
    if (IS_GRADIENT_TYPE) {
        return m_content.gradient;
    } else {
        return nil;
    }
}


- (CGAffineTransform) gradientTransform
{
    if (IS_GRADIENT_TYPE) {
        return m_content.gradientTransform;
    } else {
        return CGAffineTransformIdentity;
    }
}


- (UInt16) bitmapID
{
    return IS_BITMAP_TYPE ? m_content.bitmapID : 0;
}


- (CGAffineTransform) bitmapTransform
{
    if (IS_BITMAP_TYPE) {
        return m_content.bitmapTransform;
    } else {
        return CGAffineTransformIdentity;
    }
}


@synthesize type = m_type;

@end
