//
//  SwiftPath.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-06.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


extern const CGFloat SwiftPathOperationMove;  // Followed by { toX, toY }
extern const CGFloat SwiftPathOperationLine;  // Followed by { toX, toY }
extern const CGFloat SwiftPathOperationCurve; // Followed by { toX, toY, controlX, controlY }
extern const CGFloat SwiftPathOperationEnd;   // Followed by { NAN, NAN }.  Designates end of CGFloat array

@class SwiftLineStyle;
@class SwiftFillStyle;

@interface SwiftPath : NSObject {
@private
    CGFloat        *m_operations;
    NSUInteger      m_operationsCount;
    NSUInteger      m_operationsCapacity;
    SwiftLineStyle *m_lineStyle;
    SwiftFillStyle *m_fillStyle;
}

- (id) initWithLineStyle: (SwiftLineStyle *) lineStyle fillStyle: (SwiftFillStyle *) fillStyle;

@property (nonatomic, assign, readonly) CGFloat *operations; // Inside pointer, valid for lifetime of the SwiftPath

@property (nonatomic, retain, readonly) SwiftLineStyle *lineStyle;
@property (nonatomic, retain, readonly) SwiftFillStyle *fillStyle;

@end
