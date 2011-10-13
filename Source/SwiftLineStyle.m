//
//  SwiftLineStyle.m
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 musictheory.net, LLC. All rights reserved.
//

#import "SwiftLineStyle.h"
#import "SwiftParser.h"
#import "SwiftFillStyle.h"

const CGFloat SwiftLineStyleHairlineWidth = 0.05;

@implementation SwiftLineStyle

+ (NSArray *) lineStyleArrayWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)version
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
        SwiftLineStyle *lineStyle = [[self alloc] initWithParser:parser tag:tag version:version];

        if (lineStyle) {
            [array addObject:lineStyle];
            [lineStyle release];
        } else {
            return nil;
        }
    }

    return array;
}


- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)version
{
    if ((self = [super init])) {
        UInt16 width;
        SwiftParserReadUInt16(parser, &width);
        if (width == 1) {
            m_width = SwiftLineStyleHairlineWidth;
        } else {
            m_width = (width / 20.0);
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
        
        if (version < 3) {
            SwiftParserReadColorRGB(parser, &m_color);

        } else if (version == 3) {
            SwiftParserReadColorRGBA(parser, &m_color);
        
        } else {
            UInt32 startCapStyle, joinStyle, hasFillFlag, noHScaleFlag, noVScaleFlag, pixelHintingFlag, reserved, noClose, endCapStyle;

            SwiftParserReadUBits(parser, 2, &startCapStyle);
            SwiftParserReadUBits(parser, 2, &joinStyle);
            SwiftParserReadUBits(parser, 1, &hasFillFlag);
            SwiftParserReadUBits(parser, 1, &noHScaleFlag);
            SwiftParserReadUBits(parser, 1, &noVScaleFlag);
            SwiftParserReadUBits(parser, 1, &pixelHintingFlag);
            SwiftParserReadUBits(parser, 5, &reserved);
            SwiftParserReadUBits(parser, 1, &noClose);
            SwiftParserReadUBits(parser, 2, &endCapStyle);
            
            m_startLineCap       =  getLineCap(startCapStyle);
            m_endLineCap         =  getLineCap(endCapStyle);
            m_lineJoin           =  getLineJoin(joinStyle);
            m_scalesHorizontally = !noHScaleFlag;
            m_scalesVertically   = !noVScaleFlag;
            m_pixelAligned       =  pixelHintingFlag;
            m_closesStroke       = !noClose;

            if (m_lineJoin == kCGLineJoinMiter) {
                SwiftParserReadFixed8(parser, &m_miterLimit);
            }

            if (!hasFillFlag) {
                SwiftParserReadColorRGBA(parser, &m_color);

            } else {
                m_color.red   = 0;
                m_color.green = 0;
                m_color.blue  = 0;
                m_color.alpha = 255;
                
                m_fillStyle = [[SwiftFillStyle alloc] initWithParser:parser tag:tag version:version];
            }
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
    [m_fillStyle release];
    m_fillStyle = nil;
    
    [super dealloc];
}


- (SwiftColor *) colorPointer
{
    return &m_color;
}


@synthesize width              = m_width,
            color              = m_color,
            fillStyle          = m_fillStyle,
            startLineCap       = m_startLineCap,
            endLineCap         = m_endLineCap,
            lineJoin           = m_lineJoin,
            miterLimit         = m_miterLimit,
            scalesHorizontally = m_scalesHorizontally,
            scalesVertically   = m_scalesVertically,
            pixelAligned       = m_pixelAligned,
            closesStroke       = m_closesStroke;

@end
