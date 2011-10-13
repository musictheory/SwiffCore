//
//  SWFLineStyle.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 musictheory.net, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SwiftFillStyle;

extern const CGFloat SwiftLineStyleHairlineWidth;

@interface SwiftLineStyle : NSObject {
    CGFloat         m_width;
    SwiftColor      m_color;
    SwiftFillStyle *m_fillStyle;

    CGLineCap       m_startLineCap;
    CGLineCap       m_endLineCap;
    CGLineJoin      m_lineJoin;
    CGFloat         m_miterLimit;

    BOOL            m_scalesHorizontally;
    BOOL            m_scalesVertically;
    BOOL            m_pixelAligned;
    BOOL            m_closesStroke;
}

// Reads a LINESTYLEARRAY from the parser
+ (NSArray *) lineStyleArrayWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)tagVersion;

// Reads a LINESTYLE from the parser
- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)tagVersion;

@property (nonatomic, readonly, assign) CGFloat width;
@property (nonatomic, readonly, assign) SwiftColor color;
@property (nonatomic, readonly, retain) SwiftFillStyle *fillStyle;

// Inside pointer, valid for lifetime of the SwiftLineStyle
@property (nonatomic, assign, readonly) SwiftColor *colorPointer;

@property (nonatomic, readonly, assign) CGLineCap startLineCap;
@property (nonatomic, readonly, assign) CGLineCap endLineCap;
@property (nonatomic, readonly, assign) CGLineJoin lineJoin;
@property (nonatomic, readonly, assign) CGFloat miterLimit;

@property (nonatomic, readonly, assign, getter=isPixelAligned) BOOL pixelAligned;
@property (nonatomic, readonly, assign) BOOL scalesHorizontally;
@property (nonatomic, readonly, assign) BOOL scalesVertically;
@property (nonatomic, readonly, assign) BOOL closesStroke;

@end
