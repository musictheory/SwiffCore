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

#define IS_COLOR_TYPE    (_type == SwiffFillStyleTypeColor)

#define IS_GRADIENT_TYPE ((_type == SwiffFillStyleTypeLinearGradient) || \
                          (_type == SwiffFillStyleTypeRadialGradient) || \
                          (_type == SwiffFillStyleTypeFocalRadialGradient))

#define IS_BITMAP_TYPE   ((_type >= SwiffFillStyleTypeRepeatingBitmap) && (_type <= SwiffFillStyleTypeNonSmoothedClippedBitmap))

@implementation SwiffFillStyle {
    CGAffineTransform  _transform;
}

@synthesize type     = _type,
            color    = _color,
            gradient = _gradient,
            bitmapID = _bitmapID;


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
        SwiffParserReadUInt8(parser, &_type);

        if (IS_COLOR_TYPE) {
            SwiffTag  tag     = SwiffParserGetCurrentTag(parser);
            NSInteger version = SwiffParserGetCurrentTagVersion(parser);
        
            if ((tag == SwiffTagDefineShape) && (version >= 3)) {
                SwiffParserReadColorRGBA(parser, &_color);
            } else {
                SwiffParserReadColorRGB(parser, &_color);
            }

        } else if (IS_GRADIENT_TYPE) {
            SwiffParserReadMatrix(parser, &_transform);
            BOOL isFocalGradient = (_type == SwiffFillStyleTypeFocalRadialGradient);

            _gradient = [[SwiffGradient alloc] initWithParser:parser isFocalGradient:isFocalGradient];

        } else if (IS_BITMAP_TYPE) {
            SwiffParserReadUInt16(parser, &_bitmapID);
            SwiffParserReadMatrix(parser, &_transform);

            _transform.a /= 20.0;
            _transform.d /= 20.0;

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

    if (_type == SwiffFillStyleTypeColor) {

        typeString = [NSString stringWithFormat:@"#%02lX%02lX%02lX, %ld%%",
            (long)(_color.red   * 255.0),
            (long)(_color.green * 255.0),
            (long)(_color.blue  * 255.0),
            (long)(_color.alpha * 100.0)
        ];

    } else if (_type == SwiffFillStyleTypeLinearGradient) {
        typeString = @"LinearGradient";
    } else if (_type == SwiffFillStyleTypeRadialGradient) {
        typeString = @"RadialGradient";
    } else if (_type == SwiffFillStyleTypeFocalRadialGradient) {
        typeString = @"FocalRadialGradient";
    } else if (_type == SwiffFillStyleTypeRepeatingBitmap) {
        typeString = @"RepeatingBitmap";
    } else if (_type == SwiffFillStyleTypeClippedBitmap) {
        typeString = @"ClippedBitmap";
    } else if (_type == SwiffFillStyleTypeNonSmoothedRepeatingBitmap) {
        typeString = @"NonSmoothedRepeatingBitmap";
    } else if (_type == SwiffFillStyleTypeNonSmoothedClippedBitmap) {
        typeString = @"NonSmoothedClippedBitmap";
    }

    return [NSString stringWithFormat:@"<%@: %p; %@>", [self class], self, typeString];
}


#pragma mark -
#pragma mark Accessors

- (SwiffColor *) colorPointer
{
    return IS_COLOR_TYPE ? &_color : NULL;
}


- (CGAffineTransform) gradientTransform
{
    return IS_GRADIENT_TYPE ? _transform : CGAffineTransformIdentity;
}


- (CGAffineTransform) bitmapTransform
{
    return IS_BITMAP_TYPE ? _transform : CGAffineTransformIdentity;
}

@end
