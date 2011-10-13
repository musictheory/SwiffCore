//
//  SwiftFillStyle.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    SwiftFillStyleTypeColor = 0,

    SwiftFillStyleTypeLinearGradient             = 0x10,
    SwiftFillStyleTypeRadialGradient             = 0x12,
    SwiftFillStyleTypeFocalRadialGradient        = 0x13,

    SwiftFillStyleTypeRepeatingBitmap            = 0x40,
    SwiftFillStyleTypeClippedBitmap              = 0x41,
    SwiftFillStyleTypeNonSmoothedRepeatingBitmap = 0x42,
    SwiftFillStyleTypeNonSmoothedClippedBitmap   = 0x43
};
typedef NSInteger SwiftFillStyleType;

@class SwiftGradient;

@interface SwiftFillStyle : NSObject {
@private
    SwiftFillStyleType m_type;
    SwiftColor         m_color;
    SwiftGradient     *m_gradient;
    CGAffineTransform  m_gradientTransform;
}

// Reads a FILLSTYLEARRAY from the parser
+ (NSArray *) fillStyleArrayWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)tagVersion;

// Reads a FILLSTYLE from the parser
- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)tagVersion;

@property (nonatomic, readonly, assign) SwiftFillStyleType type;

@property (nonatomic, readonly, assign) SwiftColor color;

// Inside pointer, valid for lifetime of the SwiftFillStyle
@property (nonatomic, assign, readonly) SwiftColor *colorPointer;

@property (nonatomic, readonly, retain) SwiftGradient *gradient;
@property (nonatomic, readonly, assign) CGAffineTransform gradientTransform;

@end
