//
//  SwiftPath.m
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-06.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftPath.h"
#import "SwiftPathOperation.h"

@implementation SwiftPath

- (id) initWithPathOperations: (NSArray *) inOperations
                    lineStyle: (SwiftLineStyle *) lineStyle
                    fillStyle: (SwiftFillStyle *) fillStyle
{
    if ((self = [super init])) {
        CGPoint position = { NAN, NAN };

        NSMutableArray *operations = [[NSMutableArray alloc] init];

        for (SwiftPathOperation *operation in inOperations) {
            CGPoint fromPoint = [operation fromPoint];
            
            if (!CGPointEqualToPoint(fromPoint, position)) {
                SwiftPathOperation *move = [[SwiftPathOperation alloc] initWithType:SwiftPathOperationTypeMove
                                                                          fromPoint:position 
                                                                       controlPoint:CGPointZero 
                                                                            toPoint:fromPoint];

                [operations addObject:move];
                [move release];
            }

            [operations addObject:operation];
            position = [operation toPoint];
        }
        
        m_operations = operations;
        m_fillStyle  = [fillStyle  retain];
        m_lineStyle  = [lineStyle  retain];
    }
    
    return self;
}


- (void) dealloc
{
    [m_operations release];  m_operations = nil;
    [m_fillStyle  release];  m_fillStyle  = nil;
    [m_lineStyle  release];  m_lineStyle  = nil;
    
    [super dealloc];
}


@synthesize operations = m_operations,
            fillStyle  = m_fillStyle,
            lineStyle  = m_lineStyle;

@end
