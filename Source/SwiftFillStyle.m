/*
    SwiftFillStyle.m
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

#import "SwiftFillStyle.h"
#import "SwiftParser.h"
#import "SwiftGradient.h"

#define IS_COLOR_TYPE    (m_type == SwiftFillStyleTypeColor)

#define IS_GRADIENT_TYPE ((m_type == SwiftFillStyleTypeLinearGradient) || \
                          (m_type == SwiftFillStyleTypeRadialGradient) || \
                          (m_type == SwiftFillStyleTypeFocalRadialGradient))

#define IS_BITMAP_TYPE   ((m_type >= SwiftFillStyleTypeRepeatingBitmap) && (m_type <= SwiftFillStyleTypeNonSmoothedClippedBitmap))

@implementation SwiftFillStyle

+ (NSArray *) fillStyleArrayWithParser:(SwiftParser *)parser
{
    UInt8 count8;
    NSInteger count;

    SwiftParserReadUInt8(parser, &count8);
    if (count8 == 0xFF) {
        UInt16 count16;
        SwiftParserReadUInt16(parser, &count16);
        count = count16;

    } else {
        count = count8;
    }
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];

    for (NSInteger i = 0; i < count; i++) {
        SwiftFillStyle *fillStyle = [[self alloc] initWithParser:parser];

        if (fillStyle) {
            [array addObject:fillStyle];
            [fillStyle release];
        } else {
            return nil;
        }
    }

    return array;
}


- (id) initWithParser:(SwiftParser *)parser
{
    if ((self = [self init])) {
        UInt8 type;
        SwiftParserReadUInt8(parser, &type);
        m_type = type;

        if (IS_COLOR_TYPE) {
            SwiftTag  tag     = SwiftParserGetCurrentTag(parser);
            NSInteger version = SwiftParserGetCurrentTagVersion(parser);
        
            if ((tag == SwiftTagDefineShape) && (version >= 3)) {
                SwiftParserReadColorRGBA(parser, &m_content.color);
            } else {
                SwiftParserReadColorRGB(parser, &m_content.color);
            }

        } else if (IS_GRADIENT_TYPE) {
            SwiftParserReadMatrix(parser, &m_content.gradientTransform);
            BOOL isFocalGradient = (m_type == SwiftFillStyleTypeFocalRadialGradient);
            m_content.gradient = [[SwiftGradient alloc] initWithParser:parser isFocalGradient:isFocalGradient];

        } else if (IS_BITMAP_TYPE) {
            UInt16 bitmapID;
            SwiftParserReadUInt16(parser, &bitmapID);
            m_content.bitmapID = bitmapID;

            SwiftParserReadMatrix(parser, &m_content.bitmapTransform);

            m_content.bitmapTransform.a /= 20.0;
            m_content.bitmapTransform.d /= 20.0;

        } else {
            [self release];
            return nil;
        }

        if (!SwiftParserIsValid(parser)) {
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

    if (m_type == SwiftFillStyleTypeColor) {

        typeString = [NSString stringWithFormat:@"#%02lX%02lX%02lX, %ld%%",
            (long)(m_content.color.red   * 255.0),
            (long)(m_content.color.green * 255.0),
            (long)(m_content.color.blue  * 255.0),
            (long)(m_content.color.alpha * 100.0)
        ];

    } else if (m_type == SwiftFillStyleTypeLinearGradient) {
        typeString = @"LinearGradient";
    } else if (m_type == SwiftFillStyleTypeRadialGradient) {
        typeString = @"RadialGradient";
    } else if (m_type == SwiftFillStyleTypeFocalRadialGradient) {
        typeString = @"FocalRadialGradient";
    } else if (m_type == SwiftFillStyleTypeRepeatingBitmap) {
        typeString = @"RepeatingBitmap";
    } else if (m_type == SwiftFillStyleTypeClippedBitmap) {
        typeString = @"ClippedBitmap";
    } else if (m_type == SwiftFillStyleTypeNonSmoothedRepeatingBitmap) {
        typeString = @"NonSmoothedRepeatingBitmap";
    } else if (m_type == SwiftFillStyleTypeNonSmoothedClippedBitmap) {
        typeString = @"NonSmoothedClippedBitmap";
    }

    return [NSString stringWithFormat:@"<%@: %p; %@>", [self class], self, typeString];
}


#pragma mark -
#pragma mark Accessors

- (SwiftColor *) colorPointer
{
    if (IS_COLOR_TYPE) {
        return &m_content.color;
    } else {
        return NULL;
    }
}


- (SwiftColor) color
{
    if (IS_COLOR_TYPE) {
        return m_content.color;
    } else {
        SwiftColor color = { 0, 0, 0, 0 };
        return color;
    }
}


- (SwiftGradient *) gradient
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
