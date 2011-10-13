//
//  SwiftFillStyle.m
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftFillStyle.h"
#import "SwiftParser.h"
#import "SwiftGradient.h"

@implementation SwiftFillStyle


+ (NSArray *) fillStyleArrayWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)version
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
        SwiftFillStyle *fillStyle = [[self alloc] initWithParser:parser tag:tag version:version];

        if (fillStyle) {
            [array addObject:fillStyle];
            [fillStyle release];
        } else {
            return nil;
        }
    }

    return array;
}


- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)version
{
    if ((self = [super init])) {
        UInt8 type;
        SwiftParserReadUInt8(parser, &type);
        m_type = type;

        // 0x00 = solid fill
        if (type == 00) {
            if (version >= 3) {
                SwiftParserReadColorRGBA(parser, &m_color);
            } else {
                SwiftParserReadColorRGB(parser, &m_color);
            }

        // 0x10 = linear gradient fill
        // 0x12 = radial gradient fill
        // 0x13 = focal radial gradient fill
        } else if ((type == 0x10) || (type == 0x12) || (type == 0x13)) {
            SwiftParserReadMatrix(parser, &m_gradientTransform);
            BOOL isFocalGradient = (m_type == SwiftFillStyleTypeFocalRadialGradient);
            m_gradient = [[SwiftGradient alloc] initWithParser:parser tag:tag version:version isFocalGradient:isFocalGradient];

        // 0x40 = repeating bitmap fill
        // 0x41 = clipped bitmap fill
        // 0x42 = non-smoothed repeating bitmap
        // 0x43 = non-smoothed clipped bitmap
        } else if (type >= 0x40 && type <= 0x43) {
            UInt16 unused;
            SwiftParserReadUInt16(parser, &unused);

            CGAffineTransform unused2;
            SwiftParserReadMatrix(parser, &unused2);

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
    [m_gradient release];
    m_gradient = nil;

    [super dealloc];
}


- (NSString *) description
{
    NSString *typeString = nil;

    if (m_type == SwiftFillStyleTypeColor) {

        typeString = [NSString stringWithFormat:@"#%02lX%02lX%02lX, %ld%%",
            (long)(m_color.red   * 255.0),
            (long)(m_color.green * 255.0),
            (long)(m_color.blue  * 255.0),
            (long)(m_color.alpha * 100.0)
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


- (SwiftColor *) colorPointer
{
    return &m_color;
}


@synthesize type = m_type,
            color = m_color,
            gradient = m_gradient,
            gradientTransform = m_gradientTransform;

@end
