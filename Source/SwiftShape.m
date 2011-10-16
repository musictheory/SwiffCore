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


extern void SwiftPathAddOperation(SwiftPath *path, CGFloat type, CGPoint *toPoint, CGPoint *controlPoint);

enum {
    _SwiftShapeOperationTypeHeader = 0,
    _SwiftShapeOperationTypeLine   = 1,
    _SwiftShapeOperationTypeCurve  = 2,
    _SwiftShapeOperationTypeEnd    = 3
};


typedef struct _SwiftShapeOperation {
    UInt8      type;
    BOOL       duplicate;
    UInt16     lineStyleIndex;
    UInt16     fillStyleIndex;
    union {
        struct {
            SwiftPoint fromPoint;
            SwiftPoint controlPoint;
            SwiftPoint toPoint;
        };
        struct {
            NSUInteger operationCount;
        };
    };
} _SwiftShapeOperation;


static void sPathAddShapeOperation(SwiftPath *path, _SwiftShapeOperation *op, SwiftPoint *position)
{
    if ((op->fromPoint.x != position->x) ||
        (op->fromPoint.y != position->y))
    {
        CGPoint toPoint = {
            op->fromPoint.x / 20.0,
            op->fromPoint.y / 20.0
        };
    
        SwiftPathAddOperation(path, SwiftPathOperationMove, &toPoint, NULL);
    }
    
    if (op->type == _SwiftShapeOperationTypeLine) {
        CGPoint toPoint = CGPointMake(op->toPoint.x / 20.0, op->toPoint.y / 20.0);
        SwiftPathAddOperation(path, SwiftPathOperationLine, &toPoint, NULL);
    
    } else if (op->type == _SwiftShapeOperationTypeCurve) {
        CGPoint toPoint      = CGPointMake(op->toPoint.x      / 20.0, op->toPoint.y      / 20.0);
        CGPoint controlPoint = CGPointMake(op->controlPoint.x / 20.0, op->controlPoint.y / 20.0);
        SwiftPathAddOperation(path, SwiftPathOperationCurve, &toPoint, &controlPoint);
    }
    
    *position = op->toPoint;
}
 

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

        NSMutableArray *fillStyles = [[NSMutableArray alloc] init];
        NSMutableArray *lineStyles = [[NSMutableArray alloc] init];

        __block _SwiftShapeOperation *operations = NULL;
        __block NSUInteger operationsCount = 0;
        __block NSUInteger operationsCapacity = 0;

        CFMutableArrayRef groups = CFArrayCreateMutable(NULL, 0, NULL);

        m_fillStyles = fillStyles;
        m_lineStyles = lineStyles;
        m_groups     = groups;
        
        void (^readStyles)() = ^{
            fillStyleOffset = [m_fillStyles count];
            lineStyleOffset = [m_lineStyles count];

            [fillStyles addObjectsFromArray:[SwiftFillStyle fillStyleArrayWithParser:parser tag:tag version:version]];
            [lineStyles addObjectsFromArray:[SwiftLineStyle lineStyleArrayWithParser:parser tag:tag version:version]];
        };
        
        _SwiftShapeOperation *(^nextOperation)() = ^{
            if (operationsCount == operationsCapacity) {
                operationsCapacity *= 2;
                if (!operationsCapacity) operationsCapacity = 32;
                operations = realloc(operations, operationsCapacity * sizeof(_SwiftShapeOperation));
            }
    
            return &operations[operationsCount++];
        };
        
        void (^addEndOperation)() = ^{
            _SwiftShapeOperation *o = nextOperation();

            o->type = _SwiftShapeOperationTypeEnd;
            o->fillStyleIndex = UINT16_MAX;
            o->lineStyleIndex = UINT16_MAX;
        };
        
        void (^addOperation)(NSInteger, SwiftPoint, SwiftPoint, SwiftPoint) = ^(NSInteger type, SwiftPoint from, SwiftPoint control, SwiftPoint to) {
            {
                _SwiftShapeOperation *o = nextOperation();
                o->fromPoint      = from;
                o->controlPoint   = control;
                o->toPoint        = to;
                o->fillStyleIndex = fillStyleIndex0;
                o->lineStyleIndex = lineStyleIndex;
                o->type           = type;
                o->duplicate      = NO;
            }

            if (fillStyleIndex1) {
                _SwiftShapeOperation *o = nextOperation();
                o->fromPoint      = to;
                o->controlPoint   = control;
                o->toPoint        = from;
                o->fillStyleIndex = fillStyleIndex1;
                o->lineStyleIndex = lineStyleIndex;
                o->type           = type;
                o->duplicate      = YES;
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
                        if (operations) {
                            addEndOperation();
                            CFArrayAppendValue(groups, operations);
                        }
                        operations         = NULL;
                        operationsCount    = 0;
                        operationsCapacity = 0;

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

                    addOperation( _SwiftShapeOperationTypeLine, from, control, position );
                
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

                    addOperation( _SwiftShapeOperationTypeCurve, from, control, position );
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

        if (operations) {
            addEndOperation();
            CFArrayAppendValue(groups, operations);
        }
    }

    return self;
}


- (void) dealloc
{
    [m_tagData release];  m_tagData = nil;
    [m_paths   release];  m_paths  = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods

- (NSArray *) _linePathsForOperations:(_SwiftShapeOperation *)inOperations
{
    UInt16 index;
    NSMutableArray *result = [NSMutableArray array];

    NSUInteger lineStyleCount = [m_lineStyles count];

    for (index = 1; index <= lineStyleCount; index++) {
        _SwiftShapeOperation *operation = inOperations;
        SwiftPoint position = { NSIntegerMax, NSIntegerMax };
        SwiftPath *path = nil;
        
        while (operation->type != _SwiftShapeOperationTypeEnd) {
            BOOL   isDuplicate    = operation->duplicate;
            UInt16 lineStyleIndex = operation->lineStyleIndex; 
            
            if (!isDuplicate && (lineStyleIndex == index)) {
                if (!path) {
                    SwiftLineStyle *lineStyle = [m_lineStyles objectAtIndex:(index - 1)];
                    path = [[SwiftPath alloc] initWithLineStyle:lineStyle fillStyle:nil];
                }

                sPathAddShapeOperation(path, operation, &position);
            }
            
            operation++;
        }
        
        if (path) {
            CGPoint nanPoint = { NAN, NAN };
            SwiftPathAddOperation(path, SwiftPathOperationEnd, &nanPoint, NULL);

            [result addObject:path];
            [path release];
        }
    }
    
    return result;
}


- (NSArray *) _fillPathsForOperations:(_SwiftShapeOperation *)inOperations
{
    NSMutableArray *results = [NSMutableArray array];
    CFMutableDictionaryRef map = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    
    // Collect operations by fill style
    _SwiftShapeOperation *operation = inOperations;
    while (operation->type != _SwiftShapeOperationTypeEnd) {
        const void *key = (const void *)operation->fillStyleIndex;
        if (!key) {
            operation++;
            continue;
        }

        CFMutableArrayRef operations = (CFMutableArrayRef)CFDictionaryGetValue(map, key);

        if (!operations) {
            operations = CFArrayCreateMutable(NULL, 0, NULL);
            CFDictionarySetValue(map, key, operations);
            CFRelease(operations);
        }
    
        CFArrayAppendValue(operations, operation);
        operation++;
    }

    CFIndex      i, j;
    CFIndex      count  = CFDictionaryGetCount(map);
    CFIndex     jCount;
    const void **keys   = malloc(count * sizeof(void *));
    const void **values = malloc(count * sizeof(void *));

    CFDictionaryGetKeysAndValues(map, keys, values);
    
    for (i = 0; i < count; i++) {
        NSInteger fillStyleIndex = (NSInteger)keys[i];
        CFMutableArrayRef operations = (CFMutableArrayRef)values[i];

        CFMutableArrayRef sortedOperations = CFArrayCreateMutable(NULL, 0, NULL);

        _SwiftShapeOperation *currentOperation = (_SwiftShapeOperation *)CFArrayGetValueAtIndex(operations, 0);
        _SwiftShapeOperation *firstOperation   = NULL;

        CFArrayAppendValue(sortedOperations, currentOperation);
        CFArrayRemoveValueAtIndex(operations, 0);
        firstOperation = currentOperation;
        
        while ((jCount = CFArrayGetCount(operations)) > 0) {
            for (j = 0; j < jCount; j++) {
                _SwiftShapeOperation *o = (_SwiftShapeOperation *)CFArrayGetValueAtIndex(operations, j);
                SwiftPoint point1 = o->fromPoint;
                SwiftPoint point2 = currentOperation->toPoint;
                
                if ((point1.x == point2.x) && (point1.y == point2.y)) {
                    SwiftLog(@"Shape: Found connecting path operation");

                    CFArrayAppendValue(sortedOperations, o);
                    currentOperation = o;
                    SwiftLog(@"Shape: currentOperation = %p", currentOperation);
                    break;
                }
            }
            
            
            CFRange entireRange = { 0, CFArrayGetCount(operations) };
            CFIndex indexOfCurrent = CFArrayGetFirstIndexOfValue(operations, entireRange, currentOperation);
            if (indexOfCurrent != kCFNotFound) {
                CFArrayRemoveValueAtIndex(operations, indexOfCurrent);

            } else {
                while ((jCount = CFArrayGetCount(operations)) > 0) {
                    currentOperation = (_SwiftShapeOperation *)CFArrayGetValueAtIndex(operations, 0);
                    CFArrayRemoveValueAtIndex(operations, 0);

                    SwiftLog(@"Shape: No connecting path operation found");
                    SwiftLog(@"Shape: currentOperation = %p", currentOperation);

                    SwiftPoint point1 = firstOperation->fromPoint;
                    SwiftPoint point2 = currentOperation->toPoint;

                    if ((point1.x == point2.x) && (point1.y == point2.y)) {
                        CFArrayInsertValueAtIndex(sortedOperations, 0, currentOperation);
                        firstOperation = currentOperation;
                        SwiftLog(@"Shape: firstOperation = %p", firstOperation);

                    } else {
                        CFArrayAppendValue(sortedOperations, currentOperation);
                        SwiftLog(@"Shape: No join found, moving to:\n    %p\n", currentOperation);
                        break;
                    }
                }
            }
        }
        
        jCount = CFArrayGetCount(sortedOperations);
        if (jCount > 0) {
            SwiftFillStyle *fillStyle = [m_fillStyles objectAtIndex:(fillStyleIndex - 1)];
            
            if (fillStyle) {
                SwiftPath *path = [[SwiftPath alloc] initWithLineStyle:nil fillStyle:fillStyle];
                SwiftPoint position = { NSIntegerMax, NSIntegerMax };

                for (j = 0; j < jCount; j++) {
                    _SwiftShapeOperation *op = (_SwiftShapeOperation *)CFArrayGetValueAtIndex(sortedOperations, j);
                    sPathAddShapeOperation(path, op, &position);
                }

                CGPoint nanPoint = { NAN, NAN };
                SwiftPathAddOperation(path, SwiftPathOperationEnd, &nanPoint, NULL);

                [results addObject:path];
                [path release];
            }
        }

        CFRelease(sortedOperations);
    }
    
    CFRelease(map);
    
    if (keys) free(keys);
    if (values) free(values);

    return results;
}


#pragma mark -
#pragma mark Accessors

- (NSArray *) paths
{
    if (!m_paths && m_groups) {
        @autoreleasepool {
            NSMutableArray *result = [[NSMutableArray alloc] init];

            CFIndex length = CFArrayGetCount(m_groups);
            for (CFIndex i = 0; i < length; i++) {
                _SwiftShapeOperation *operations = (_SwiftShapeOperation *)CFArrayGetValueAtIndex(m_groups, i);
               
                [result addObjectsFromArray:[self _fillPathsForOperations:operations]];
                [result addObjectsFromArray:[self _linePathsForOperations:operations]];
            
                free(operations);
            }
            
            CFRelease(m_groups);
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

