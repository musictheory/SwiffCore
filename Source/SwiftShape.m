//
//  SwiftShape.m
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftShape.h"
#import "SwiftFillStyle.h"
#import "SwiftLineStyle.h"
#import "SwiftParser.h"
#import "SwiftPath.h"
#import "SwiftPathOperation.h"


@implementation SwiftShape

#pragma mark -
#pragma mark Lifecycle

- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(SwiftVersion)version
{
    if ((self = [super init])) {
        SwiftParserByteAlign(parser);

        if (tag == SwiftTagDefineShape) {
            UInt16 libraryID;
            SwiftParserReadUInt16(parser, &libraryID);
            m_libraryID = libraryID;

            SwiftLog(@"DEFINESHAPE defines id %d", libraryID);
            
            SwiftParserReadRect(parser, &m_bounds);

            if (version > 3) {
                m_hasEdgeBounds = YES;
                SwiftParserReadRect(parser, &m_edgeBounds);
                
                UInt32 reserved, usesFillWindingRule, usesNonScalingStrokes, usesScalingStrokes;
                SwiftParserReadUBits(parser, 5, &reserved);
                SwiftParserReadUBits(parser, 1, &usesFillWindingRule);
                SwiftParserReadUBits(parser, 1, &usesNonScalingStrokes);
                SwiftParserReadUBits(parser, 1, &usesScalingStrokes);

                m_usesFillWindingRule   = usesFillWindingRule;
                m_usesNonScalingStrokes = usesNonScalingStrokes;
                m_usesScalingStrokes    = usesScalingStrokes;
            }
        }

        SwiftPoint position = { 0, 0 };

        __block UInt16 fillStyleOffset = 0;
        __block UInt16 lineStyleOffset = 0;
        __block UInt16 lineStyleIndex  = 0;
        __block UInt16 fillStyleIndex0 = 0;
        __block UInt16 fillStyleIndex1 = 0;

        NSMutableArray *fillStyles      = [[NSMutableArray alloc] init];
        NSMutableArray *lineStyles      = [[NSMutableArray alloc] init];
        NSMutableArray *operationGroups = [[NSMutableArray alloc] init];

        __block NSMutableArray *operations = [[NSMutableArray alloc] init];
        [operationGroups addObject:operations];

        m_fillStyles = fillStyles;
        m_lineStyles = lineStyles;
        m_operationGroups = operationGroups;
        
        void (^flushOperations)() = ^{
            [operations release];
            operations = [[NSMutableArray alloc] init];
            [operationGroups addObject:operations];
        };

        void (^readStyles)() = ^{
            fillStyleOffset = [m_fillStyles count];
            lineStyleOffset = [m_lineStyles count];

            [fillStyles addObjectsFromArray:[SwiftFillStyle fillStyleArrayWithParser:parser tag:tag version:version]];
            [lineStyles addObjectsFromArray:[SwiftLineStyle lineStyleArrayWithParser:parser tag:tag version:version]];
        };
        
        void (^addOperation)(SwiftPathOperationType, SwiftPoint, SwiftPoint, SwiftPoint) = ^(SwiftPathOperationType type, SwiftPoint from, SwiftPoint control, SwiftPoint to) {
            CGPoint fromCGPoint    = CGPointMake(from.x    / 20.0, from.y    / 20.0);
            CGPoint controlCGPoint = CGPointMake(control.x / 20.0, control.y / 20.0);
            CGPoint toCGPoint      = CGPointMake(to.x      / 20.0, to.y      / 20.0);

            {
                SwiftPathOperation *o = [[SwiftPathOperation alloc] initWithType:type fromPoint:fromCGPoint controlPoint:controlCGPoint toPoint:toCGPoint];
                [operations addObject:o];
                o->m_fillStyleIndex = fillStyleIndex0;
                o->m_lineStyleIndex = lineStyleIndex;
                o->m_fromSwiftPoint = from;
                o->m_toSwiftPoint   = to;
                
                [o release];
            }

            if (fillStyleIndex1) {
                SwiftPathOperation *o = [[SwiftPathOperation alloc] initWithType:type fromPoint:toCGPoint controlPoint:controlCGPoint toPoint:fromCGPoint];
                [operations addObject:o];

                o->m_fillStyleIndex = fillStyleIndex1;
                o->m_lineStyleIndex = lineStyleIndex;
                o->m_fromSwiftPoint = to;
                o->m_toSwiftPoint   = from;
                o->m_duplicate      = YES;

                [o release];
            }
        };

        if (tag == SwiftTagDefineShape) {
            readStyles();
        }

        UInt32 fillBits, lineBits;
        SwiftParserReadUBits(parser, 4, &fillBits);
        SwiftParserReadUBits(parser, 4, &lineBits);

        BOOL foundEndRecord = NO;
        while (!foundEndRecord) {
            UInt32 typeFlag;
            SwiftParserReadUBits(parser, 1, &typeFlag);

            if (typeFlag == 0) {
                UInt32 newStyles, changeLineStyle, changeFillStyle0, changeFillStyle1, moveTo;
                SwiftParserReadUBits(parser, 1, &newStyles);
                SwiftParserReadUBits(parser, 1, &changeLineStyle);
                SwiftParserReadUBits(parser, 1, &changeFillStyle1);
                SwiftParserReadUBits(parser, 1, &changeFillStyle0);
                SwiftParserReadUBits(parser, 1, &moveTo);
                
                // ENDSHAPERECORD
                if ((newStyles + changeLineStyle + changeFillStyle1 + changeFillStyle0 + moveTo) == 0) {
                    foundEndRecord = YES;

                // STYLECHANGERECORD
                } else {
                    if (moveTo) {
                        UInt32 moveBits;
                        SwiftParserReadUBits(parser, 5, &moveBits);
                        
                        SInt32 x, y;
                        SwiftParserReadSBits(parser, moveBits, &x);
                        SwiftParserReadSBits(parser, moveBits, &y);

                        position.x = x;
                        position.y = y;
                    }
                    
                    if (changeFillStyle0) {
                        UInt32 i;
                        SwiftParserReadUBits(parser, fillBits, &i);
                        fillStyleIndex0 = i > 0 ? (i + fillStyleOffset) : 0;
                    }

                    if (changeFillStyle1) {
                        UInt32 i;
                        SwiftParserReadUBits(parser, fillBits, &i);
                        fillStyleIndex1 = i > 0 ? (i + fillStyleOffset) : 0;
                    }

                    if (changeLineStyle) {
                        UInt32 i;
                        SwiftParserReadUBits(parser, lineBits, &i);
                        lineStyleIndex = i > 0 ? (i + lineStyleOffset) : 0;
                    }

                    if (newStyles) {
                        flushOperations();
                        readStyles();
                        SwiftParserReadUBits(parser, 4, &fillBits);
                        SwiftParserReadUBits(parser, 4, &lineBits);
                    }
                }
                
            } else {
                UInt32 straightFlag, numBits;
                SwiftParserReadUBits(parser, 1, &straightFlag);
                SwiftParserReadUBits(parser, 4, &numBits);
                
                // STRAIGHTEDGERECORD
                if (straightFlag) {
                    UInt32 generalLineFlag;
                    SInt32 vertLineFlag = 0, deltaX = 0, deltaY = 0;

                    SwiftParserReadUBits(parser, 1, &generalLineFlag);

                    if (generalLineFlag == 0) {
                        SwiftParserReadSBits(parser, 1, &vertLineFlag);
                    }

                    if (generalLineFlag || !vertLineFlag) {
                        SwiftParserReadSBits(parser, numBits + 2, &deltaX);
                    }

                    if (generalLineFlag || vertLineFlag) {
                        SwiftParserReadSBits(parser, numBits + 2, &deltaY);
                    }

                    SwiftPoint control = { 0, 0 };
                    SwiftPoint from = position;
                    position.x += deltaX;
                    position.y += deltaY;

                    addOperation( SwiftPathOperationTypeLine, from, control, position );
                
                // CURVEDEDGERECORD
                } else {
                    SInt32 controlDeltaX = 0, controlDeltaY = 0, anchorDeltaX = 0, anchorDeltaY = 0;
                           
                    SwiftParserReadSBits(parser, numBits + 2, &controlDeltaX);
                    SwiftParserReadSBits(parser, numBits + 2, &controlDeltaY);
                    SwiftParserReadSBits(parser, numBits + 2, &anchorDeltaX);
                    SwiftParserReadSBits(parser, numBits + 2, &anchorDeltaY);

                    SwiftPoint control = {
                        position.x + controlDeltaX,
                        position.y + controlDeltaY,
                    };

                    SwiftPoint from = position;
                    position.x = control.x + anchorDeltaX;
                    position.y = control.y + anchorDeltaY;

                    addOperation( SwiftPathOperationTypeCurve, from, control, position );
                }
            }
            
            // According to the specification:
            //
            // "Each individual shape record is byte-aligned within
            //  an array of shape records"
            //
            // In practice, this is not the case.
            //
            // SwiftParserByteAlign(parser);
        }
        
        [operations release];
    }

    return self;
}


- (void) dealloc
{
    [m_operationGroups release];  m_operationGroups = nil;
    [m_fillStyles      release];  m_fillStyles      = nil;
    [m_lineStyles      release];  m_lineStyles      = nil;
    [m_paths           release];  m_paths           = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods

- (NSArray *) _linePathsForOperations:(NSArray *)inOperations
{
    SwiftLineStyle *(^getLineStyleAtIndex1)(NSUInteger) = ^(NSUInteger i) {
        if (i >= 1 && i <= [m_lineStyles count]) {
            return [m_lineStyles objectAtIndex:(i - 1)];
        } else {
            return nil;
        }
    };

    UInt16 index;
    NSMutableArray *result = [NSMutableArray array];
    
    NSUInteger lineStyleCount = [m_lineStyles count];
    
    for (index = 1; index <= lineStyleCount; index++) {
        NSMutableArray *outOperations = [[NSMutableArray alloc] init];

        for (SwiftPathOperation *o in inOperations) {
            BOOL   isDuplicate    = o->m_duplicate;
            UInt16 lineStyleIndex = o->m_lineStyleIndex; 
            
            if (!isDuplicate && (lineStyleIndex == index)) {
                [outOperations addObject:o];
            }
        }

        if ([outOperations count]) {
            SwiftLineStyle *lineStyle = getLineStyleAtIndex1(index);
            
            SwiftPath *path = [[SwiftPath alloc] initWithPathOperations:outOperations lineStyle:lineStyle fillStyle:nil];
            [result addObject:path];
            [path release];
        }
        
        [outOperations release];
    }
    
    return result;
}


- (NSArray *) _fillPathsForOperations:(NSArray *)inOperations
{
    SwiftFillStyle *(^getFillStyleAtIndex1)(NSUInteger) = ^(NSUInteger i) {
        if (i >= 1 && i <= [m_fillStyles count]) {
            return [m_fillStyles objectAtIndex:(i - 1)];
        } else {
            return nil;
        }
    };

    NSMutableArray      *results       = [NSMutableArray array];
    NSMutableDictionary *operationsMap = [[NSMutableDictionary alloc] init];

    // Collect operations by fill style
    for (SwiftPathOperation *inOperation in inOperations) {
        NSNumber       *number     = [[NSNumber alloc] initWithInteger:(NSInteger)inOperation->m_fillStyleIndex];
        NSMutableArray *operations = [operationsMap objectForKey:number];
        
        if (!operations) {
            operations = [[NSMutableArray alloc] init];
            [operationsMap setObject:operations forKey:number];
            [operations release];
        }

        [operations addObject:inOperation];
        [number release];
    }

    for (NSNumber *number in [[operationsMap allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        SwiftLog(@"Shape: sorting fillStyle %@: %@", number, getFillStyleAtIndex1([number integerValue]));
        
        NSMutableArray     *operations       = [operationsMap objectForKey:number];
        NSMutableArray     *sortedOperations = [[NSMutableArray alloc] init];
        SwiftPathOperation *currentOperation = [operations objectAtIndex:0];
        SwiftPathOperation *firstOperation   = nil;
        
        [sortedOperations addObject:currentOperation];
        [operations removeObjectAtIndex:0];
        firstOperation = currentOperation;

        SwiftLog(@"Shape: currentOperation = %@", currentOperation);

        while ([operations count]) {
            for (SwiftPathOperation *o in operations) {
                SwiftPoint point1 = o->m_fromSwiftPoint;
                SwiftPoint point2 = currentOperation->m_toSwiftPoint;
                
                if ((point1.x == point2.x) && (point1.y == point2.y)) {
                    SwiftLog(@"Shape: Found connecting path operation");

                    [sortedOperations addObject:o];
                    currentOperation = o;
                    SwiftLog(@"Shape: currentOperation = %@", currentOperation);
                    break;
                }
            }
            
            if ([operations containsObject:currentOperation]) {            
                [operations removeObject:currentOperation];

            } else {
                while ([operations count]) {
                    currentOperation = [operations objectAtIndex:0];
                    [operations removeObjectAtIndex:0];

                    SwiftLog(@"Shape: No connecting path operation found");
                    SwiftLog(@"Shape: currentOperation = %@", currentOperation);

                    SwiftPoint point1 = firstOperation->m_fromSwiftPoint;
                    SwiftPoint point2 = currentOperation->m_toSwiftPoint;

                    if ((point1.x == point2.x) && (point1.y == point2.y)) {
                        [sortedOperations insertObject:currentOperation atIndex:0];
                        firstOperation = currentOperation;
                        SwiftLog(@"Shape: firstOperation = %@", firstOperation);

                    } else {
                        [sortedOperations addObject:currentOperation];
                        SwiftLog(@"Shape: No join found, moving to:\n    %@\n", currentOperation);
                        break;
                    }
                }
            }
        }
    
        if ([sortedOperations count]) {
            SwiftFillStyle *fillStyle = getFillStyleAtIndex1([number integerValue]);

            if (fillStyle) {
                SwiftPath *path = [[SwiftPath alloc] initWithPathOperations:sortedOperations lineStyle:nil fillStyle:fillStyle];
                [results addObject:path];
                [path release];
            }
        }

        [sortedOperations release];
    }

    [operationsMap release];

    return results;
}


#pragma mark -
#pragma mark Accessors

- (NSArray *) paths
{
    if (!m_paths) {
        @autoreleasepool {
            NSMutableArray *result = [[NSMutableArray alloc] init];

            for (NSArray *operations in m_operationGroups) {
                [result addObjectsFromArray:[self _fillPathsForOperations:operations]];
                [result addObjectsFromArray:[self _linePathsForOperations:operations]];
            }
            
            [m_operationGroups release];
            m_operationGroups = nil;

            m_paths = result;
        }
    }

    return m_paths;
}

@synthesize libraryID             = m_libraryID,
            bounds                = m_bounds,
            edgeBounds            = m_edgeBounds,
            usesFillWindingRule   = m_usesFillWindingRule,
            usesNonScalingStrokes = m_usesNonScalingStrokes,
            usesScalingStrokes    = m_usesScalingStrokes,
            hasEdgeBounds         = m_hasEdgeBounds;

@end

