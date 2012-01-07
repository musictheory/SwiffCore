/*
    SwiffGradient.m
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

#import "SwiffGradient.h"
#import "SwiffParser.h"
#import <SwiffUtils.h>


@implementation SwiffGradient

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
                SwiffParserReadColorRGBA(parser, &m_colors[i]);
            }
            
            for (i = 0; i < count; i++) {
                UInt8 ratio;
                SwiffParserReadUInt8(parser, &ratio);
                m_ratios[i] = ratio / 255.0;
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
                m_ratios[i] = ratio / 255.0;
                
                if (usesAlphaColors) {
                    SwiffParserReadColorRGBA(parser, &m_colors[i]);
                } else {
                    SwiffParserReadColorRGB(parser,  &m_colors[i]);
                }
            }
            
            if (isFocalGradient) {
                SwiffParserReadFixed8(parser, &m_focalPoint);
            }

            SwiffParserByteAlign(parser);
        }
        
        m_spreadMode        = spreadMode;
        m_interpolationMode = interpolationMode;
        m_recordCount       = count;

        if (!SwiffParserIsValid(parser)) {
            [self release];
            return nil;
        }
    }
    
    return self;
}


- (CGGradientRef) copyCGGradientWithColorTransformStack:(CFArrayRef)stack;
{
    CGColorSpaceRef   colorSpace = CGColorSpaceCreateDeviceRGB();
    CFMutableArrayRef colors     = CFArrayCreateMutable(NULL, m_recordCount, &kCFTypeArrayCallBacks);

    for (NSInteger i = 0; i < m_recordCount; i++) {
        SwiffColor color = SwiffColorApplyColorTransformStack(m_colors[i], stack);
    
        CGColorRef cgColor = CGColorCreate(colorSpace, &color.red);
        CFArrayAppendValue(colors, cgColor);
        CGColorRelease(cgColor);
    }
    
    CGGradientRef result = CGGradientCreateWithColors(colorSpace, colors, m_ratios);

    if (colors)     CFRelease(colors);
    if (colorSpace) CFRelease(colorSpace);

    return result;
}


- (void) getColor:(SwiffColor *)outColor ratio:(CGFloat *)outRatio forRecord:(NSUInteger)index
{
    if (index < m_recordCount) {
        if (outColor) *outColor = m_colors[index];
        if (outRatio) *outRatio = m_ratios[index];
    }
}


@synthesize recordCount       = m_recordCount,
            spreadMode        = m_spreadMode,
            interpolationMode = m_interpolationMode,
            focalPoint        = m_focalPoint;

@end
