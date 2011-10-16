//
//  SwiftPath.m
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-06.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftPath.h"


const CGFloat SwiftPathOperationMove  = 0.0;
const CGFloat SwiftPathOperationLine  = 1.0;
const CGFloat SwiftPathOperationCurve = 2.0;
const CGFloat SwiftPathOperationEnd   = 3.0;

extern void SwiftPathAddOperation(SwiftPath *path, CGFloat type, CGPoint *toPoint, CGPoint *controlPoint);


@implementation SwiftPath

void SwiftPathAddOperation(SwiftPath *path, CGFloat type, CGPoint *toPoint, CGPoint *controlPoint)
{
    NSUInteger spaceNeeded = (type == SwiftPathOperationCurve) ? 5 : 3;
    NSUInteger newCount    = path->m_operationsCount + spaceNeeded;

    if (newCount >= path->m_operationsCapacity) {
        path->m_operationsCapacity *= 2;
        if (!path->m_operationsCapacity) path->m_operationsCapacity = 64;
        path->m_operations = realloc(path->m_operations, sizeof(CGFloat) * path->m_operationsCapacity);
    }
    
    path->m_operations[path->m_operationsCount + 0] = type;
    path->m_operations[path->m_operationsCount + 1] = toPoint->x;
    path->m_operations[path->m_operationsCount + 2] = toPoint->y;

    if (type == SwiftPathOperationCurve) {
        path->m_operations[path->m_operationsCount + 3] = controlPoint->x;
        path->m_operations[path->m_operationsCount + 4] = controlPoint->y;
    }
    
    path->m_operationsCount += spaceNeeded;
}


- (id) initWithLineStyle:(SwiftLineStyle *)lineStyle fillStyle:(SwiftFillStyle *)fillStyle
{
    if ((self = [super init])) {
        m_fillStyle  = [fillStyle  retain];
        m_lineStyle  = [lineStyle  retain];
    }
    
    return self;
}


- (void) dealloc
{
    if (m_operations) {
        free(m_operations);
        m_operations = NULL;
    }

    [m_fillStyle  release];  m_fillStyle  = nil;
    [m_lineStyle  release];  m_lineStyle  = nil;
    
    [super dealloc];
}


@synthesize operations      = m_operations,
            fillStyle       = m_fillStyle,
            lineStyle       = m_lineStyle;

@end
