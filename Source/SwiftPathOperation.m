//
//  SwiftPathOperation.m
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-06.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftPathOperation.h"


@implementation SwiftPathOperation

- (id) initWithType: (SwiftPathOperationType) type
          fromPoint: (CGPoint) fromPoint
       controlPoint: (CGPoint) controlPoint
            toPoint: (CGPoint) toPoint
{
    if ((self = [super init])) {
        m_type         = type;
        m_fromPoint    = fromPoint;
        m_controlPoint = controlPoint;
        m_toPoint      = toPoint;
    }
    
    return self;
}


- (NSString *) description
{
    NSString *typeString = nil;

    if (m_type == SwiftPathOperationTypeLine) {
        typeString = [NSString stringWithFormat:@"line from(%.2lf, %.2lf) to(%.2lf, %.2lf)",
            (double)m_fromPoint.x,
            (double)m_fromPoint.y,
            (double)m_toPoint.x,
            (double)m_toPoint.y];

    } else if (m_type == SwiftPathOperationTypeCurve) {
        typeString = [NSString stringWithFormat:@"curve from(%.2lf, %.2lf) control(%.2lf, %.2lf) to(%.2lf, %.2lf)",
            (double)m_fromPoint.x,
            (double)m_fromPoint.y,
            (double)m_controlPoint.x,
            (double)m_controlPoint.y,
            (double)m_toPoint.x,
            (double)m_toPoint.y];

    } else {
        typeString = [NSString stringWithFormat:@"move to (%.2lf,%.2lf)",
            (double)m_toPoint.x,
            (double)m_toPoint.y];
    }

    return [NSString stringWithFormat:@"<%@: %p; %@>", [self class], self, typeString, (long)m_lineStyleIndex, (long)m_fillStyleIndex];
}


@synthesize type         = m_type,
            fromPoint    = m_fromPoint,
            controlPoint = m_controlPoint,
            toPoint      = m_toPoint;

@end
