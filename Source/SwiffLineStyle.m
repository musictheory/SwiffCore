/*
    SwiffLineStyle.m
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

#import "SwiffLineStyle.h"
#import "SwiffParser.h"
#import "SwiffFillStyle.h"
#import "SwiffUtils.h"

const CGFloat SwiffLineStyleHairlineWidth = CGFLOAT_MIN;

@implementation SwiffLineStyle

@synthesize width              = _width,
            color              = _color,
            fillStyle          = _fillStyle,
            startLineCap       = _startLineCap,
            endLineCap         = _endLineCap,
            lineJoin           = _lineJoin,
            miterLimit         = _miterLimit,
            scalesHorizontally = _scalesHorizontally,
            scalesVertically   = _scalesVertically,
            pixelAligned       = _pixelAligned,
            closesStroke       = _closesStroke;


+ (NSArray *) lineStyleArrayWithParser:(SwiffParser *)parser
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
        SwiffLineStyle *lineStyle = [[self alloc] initWithParser:parser];

        if (lineStyle) {
            [array addObject:lineStyle];
        } else {
            return nil;
        }
    }

    return array;
}


- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        UInt16 width;
        SwiffParserReadUInt16(parser, &width);
        if (width == 1) {
            _width = SwiffLineStyleHairlineWidth;
        } else {
            _width = SwiffGetCGFloatFromTwips(width);
        }

        CGLineCap (^getLineCap)(UInt32) = ^(UInt32 capStyle) {
            CGLineCap result = kCGLineCapRound;

            if (capStyle == 1) {
                result = kCGLineCapButt;
            } else if (capStyle == 2) {
                result = kCGLineCapSquare;
            }

            return result;
        };

        CGLineJoin (^getLineJoin)(UInt32) = ^(UInt32 joinStyle) {
            CGLineJoin result = kCGLineJoinRound;

            if (joinStyle == 1) {
                result = kCGLineJoinBevel;
            } else if (joinStyle == 2) {
                result = kCGLineJoinMiter;
            }

            return result;
        };

        NSInteger version = SwiffParserGetCurrentTagVersion(parser);

        if (version < 3) {
            SwiffParserReadColorRGB(parser, &_color);
            _closesStroke = YES;

        } else if (version == 3) {
            SwiffParserReadColorRGBA(parser, &_color);
            _closesStroke = YES;

        } else {
            UInt32 startCapStyle, joinStyle, hasFillFlag, noHScaleFlag, noVScaleFlag, pixelHintingFlag, reserved, noClose, endCapStyle;

            SwiffParserReadUBits(parser, 2, &startCapStyle);
            SwiffParserReadUBits(parser, 2, &joinStyle);
            SwiffParserReadUBits(parser, 1, &hasFillFlag);
            SwiffParserReadUBits(parser, 1, &noHScaleFlag);
            SwiffParserReadUBits(parser, 1, &noVScaleFlag);
            SwiffParserReadUBits(parser, 1, &pixelHintingFlag);
            SwiffParserReadUBits(parser, 5, &reserved);
            SwiffParserReadUBits(parser, 1, &noClose);
            SwiffParserReadUBits(parser, 2, &endCapStyle);
            
            _startLineCap       =  getLineCap(startCapStyle);
            _endLineCap         =  getLineCap(endCapStyle);
            _lineJoin           =  getLineJoin(joinStyle);
            _scalesHorizontally = !noHScaleFlag && (_width != SwiffLineStyleHairlineWidth);
            _scalesVertically   = !noVScaleFlag && (_width != SwiffLineStyleHairlineWidth);
            _pixelAligned       =  pixelHintingFlag;
            _closesStroke       = !noClose;

            if (_lineJoin == kCGLineJoinMiter) {
                SwiffParserReadFixed8(parser, &_miterLimit);
            }

            if (!hasFillFlag) {
                SwiffParserReadColorRGBA(parser, &_color);

            } else {
                _color.red   = 0;
                _color.green = 0;
                _color.blue  = 0;
                _color.alpha = 255;
                
                _fillStyle = [[SwiffFillStyle alloc] initWithParser:parser];
            }
        }

        if (!SwiffParserIsValid(parser)) {
            return nil;
        }
    }
    
    return self;
}


- (SwiffColor *) colorPointer
{
    return &_color;
}


@end
