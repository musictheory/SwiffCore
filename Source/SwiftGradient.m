//
//  SwiftGradient.m
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 musictheory.net, LLC. All rights reserved.
//

#import "SwiftGradient.h"
#import "SwiftParser.h"

@implementation SwiftGradient

- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)version isFocalGradient:(BOOL)isFocalGradient
{
    if ((self = [super init])) {
        BOOL alpha = (version > 2);

        UInt32 spreadMode, interpolationMode, count, i;

        SwiftParserByteAlign(parser);

        SwiftParserReadUBits(parser, 2, &spreadMode);
        SwiftParserReadUBits(parser, 2, &interpolationMode);
        SwiftParserReadUBits(parser, 4, &count);
        
        m_spreadMode        = spreadMode;
        m_interpolationMode = interpolationMode;
        m_recordCount       = count;
        
        for (i = 0; i < count; i++) {
            UInt8 ratio;
            SwiftParserReadUInt8(parser, &ratio);
            m_ratios[i] = ratio / 255.0;
            
            if (alpha) {
                SwiftParserReadColorRGBA(parser, &m_colors[i]);
            } else {
                SwiftParserReadColorRGB(parser,  &m_colors[i]);
            }
        }
        
        if (isFocalGradient) {
            SwiftParserReadFixed8(parser, &m_focalPoint);
        }

        SwiftParserByteAlign(parser);

        if (!SwiftParserIsValid(parser)) {
            [self release];
            return nil;
        }
    }
    
    return self;
}


- (void) dealloc
{
    CGGradientRelease(m_cgGradient);
    m_cgGradient = NULL;
    
    [super dealloc];
}


- (CGGradientRef) CGGradient
{
    if (!m_cgGradient) {
        CGColorSpaceRef   colorSpace = CGColorSpaceCreateDeviceRGB();
        CFMutableArrayRef colors     = CFArrayCreateMutable(NULL, m_recordCount, &kCFTypeArrayCallBacks);

        for (NSInteger i = 0; i < m_recordCount; i++) {
            CGColorRef color = CGColorCreate(colorSpace, &m_colors[i].red);
            CFArrayAppendValue(colors, color);
            CGColorRelease(color);
        }
    
        m_cgGradient = CGGradientCreateWithColors(colorSpace, colors, m_ratios);

        if (colors)     CFRelease(colors);
        if (colorSpace) CFRelease(colorSpace);
    }
    
    return m_cgGradient;
}


- (void) getColor:(SwiftColor *)outColor ratio:(CGFloat *)outRatio forRecord:(NSInteger)index
{
    if ((index >= 0) && (index < m_recordCount)) {
        if (outColor) *outColor = m_colors[index];
        if (outRatio) *outRatio = m_ratios[index];
    }
}


@synthesize recordCount       = m_recordCount,
            spreadMode        = m_spreadMode,
            interpolationMode = m_interpolationMode,
            focalPoint        = m_focalPoint;

@end
