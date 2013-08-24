/*
    SwiffGradient.m
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

#import "SwiffGradient.h"
#import "SwiffParser.h"
#import <SwiffUtils.h>


@implementation SwiffGradient {
    CGFloat       _ratios[15];
    SwiffColor    _colors[15];
}


- (id) initWithParser:(SwiffParser *)parser isFocalGradient:(BOOL)isFocalGradient
{
    if ((self = [super init])) {
        SwiffTag  tag     = SwiffParserGetCurrentTag(parser);
        NSInteger version = SwiffParserGetCurrentTagVersion(parser);

        UInt32 spreadMode, interpolationMode, count, i;

        // 
        if ((tag == SwiffTagPlaceObject) && (version >= 3)) {
            UInt8 tmp;
            SwiffParserReadUInt8(parser, &tmp);
            count = tmp;
            interpolationMode = 0;
            spreadMode = 0;

            if (count > 16) count = 16;

            for (i = 0; i < count; i++) {
                SwiffParserReadColorRGBA(parser, &_colors[i]);
            }
            
            for (i = 0; i < count; i++) {
                UInt8 ratio;
                SwiffParserReadUInt8(parser, &ratio);
                _ratios[i] = ratio / 255.0;
            }

        } else {
            SwiffParserByteAlign(parser);

            SwiffParserReadUBits(parser, 2, &spreadMode);
            SwiffParserReadUBits(parser, 2, &interpolationMode);
            SwiffParserReadUBits(parser, 4, &count);

            BOOL usesAlphaColors = ((tag == SwiffTagDefineShape) && (version >= 3));

            for (i = 0; i < count; i++) {
                UInt8 ratio;
                SwiffParserReadUInt8(parser, &ratio);
                _ratios[i] = ratio / 255.0;
                
                if (usesAlphaColors) {
                    SwiffParserReadColorRGBA(parser, &_colors[i]);
                } else {
                    SwiffParserReadColorRGB(parser,  &_colors[i]);
                }
            }
            
            if (isFocalGradient) {
                SwiffParserReadFixed8(parser, &_focalPoint);
            }

            SwiffParserByteAlign(parser);
        }
        
        _spreadMode        = spreadMode;
        _interpolationMode = interpolationMode;
        _recordCount       = count;

        if (!SwiffParserIsValid(parser)) {
            return nil;
        }
    }
    
    return self;
}


- (CGGradientRef) copyCGGradientWithColorTransformStack:(CFArrayRef)stack
{
    return [self copyCGGradientWithColorTransformStack:stack colorModificationBlock:NULL];
}


- (CGGradientRef) copyCGGradientWithColorTransformStack:(CFArrayRef)stack colorModificationBlock:(SwiffColorModificationBlock)colorModificationBlock
{
    CGColorSpaceRef   colorSpace = CGColorSpaceCreateDeviceRGB();
    CFMutableArrayRef colors     = CFArrayCreateMutable(NULL, _recordCount, &kCFTypeArrayCallBacks);

    for (NSInteger i = 0; i < _recordCount; i++) {
        SwiffColor color = SwiffColorApplyColorTransformStack(_colors[i], stack);
    
        if (colorModificationBlock) {
            colorModificationBlock(&color);
        }
    
        CGColorRef cgColor = CGColorCreate(colorSpace, &color.red);
        CFArrayAppendValue(colors, cgColor);
        CGColorRelease(cgColor);
    }
    
    CGGradientRef result = CGGradientCreateWithColors(colorSpace, colors, _ratios);

    if (colors)     CFRelease(colors);
    if (colorSpace) CFRelease(colorSpace);

    return result;
}


- (void) getColor:(SwiffColor *)outColor ratio:(CGFloat *)outRatio forRecord:(NSUInteger)index
{
    if (index < _recordCount) {
        if (outColor) *outColor = _colors[index];
        if (outRatio) *outRatio = _ratios[index];
    }
}

@end
