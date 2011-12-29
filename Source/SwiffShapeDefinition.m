/*
    SwiffShape.m
    Copyright (c) 2011, musictheory.net, LLC.  All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
          notice, this list of conditions and the following disclaimer in the
          documentation and/or other materials provided with the distribution.
        * Neither the name of musictheory.net, LLC nor the names of its contributors
          may be used to endorse or promote products derived from this software
          without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL MUSICTHEORY.NET, LLC BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import "SwiffShapeDefinition.h"
#import "SwiffFillStyle.h"
#import "SwiffLineStyle.h"
#import "SwiffParser.h"
#import "SwiffPath.h"


enum {
    _SwiffShapeOperationTypeHeader = 0,
    _SwiffShapeOperationTypeLine   = 1,
    _SwiffShapeOperationTypeCurve  = 2,
    _SwiffShapeOperationTypeEnd    = 3
};


typedef struct _SwiffShapeOperation {
    UInt8      type;
    BOOL       duplicate;
    UInt16     lineStyleIndex;
    UInt16     fillStyleIndex;
    SwiffPoint fromPoint;
    SwiffPoint controlPoint;
    SwiffPoint toPoint;
} _SwiffShapeOperation;


static void sPathAddShapeOperation(SwiffPath *path, _SwiffShapeOperation *op, SwiffPoint *position)
{
    if ((op->fromPoint.x != position->x) ||
        (op->fromPoint.y != position->y))
    {
        CGPoint toPoint = {
            SwiffFloatFromTwips(op->fromPoint.x),
            SwiffFloatFromTwips(op->fromPoint.y)
        };
    
        SwiffPathAddOperation(path, SwiffPathOperationMove, toPoint.x, toPoint.y);
    }
    
    if (op->type == _SwiffShapeOperationTypeLine) {
        if (op->fromPoint.x == op->toPoint.x) {
            SwiffPathAddOperation(path, SwiffPathOperationVerticalLine, SwiffFloatFromTwips(op->toPoint.y));
            
        } else if (op->fromPoint.y == op->toPoint.y) {
            SwiffPathAddOperation(path, SwiffPathOperationHorizontalLine, SwiffFloatFromTwips(op->toPoint.x));
        
        } else {
            CGPoint toPoint = CGPointMake(SwiffFloatFromTwips(op->toPoint.x), SwiffFloatFromTwips(op->toPoint.y));
            SwiffPathAddOperation(path, SwiffPathOperationLine, toPoint.x, toPoint.y);
        }
    
    } else if (op->type == _SwiffShapeOperationTypeCurve) {
        CGPoint toPoint      = CGPointMake(SwiffFloatFromTwips(op->toPoint.x),      SwiffFloatFromTwips(op->toPoint.y));
        CGPoint controlPoint = CGPointMake(SwiffFloatFromTwips(op->controlPoint.x), SwiffFloatFromTwips(op->controlPoint.y));
        SwiffPathAddOperation(path, SwiffPathOperationCurve, toPoint.x, toPoint.y, controlPoint.x, controlPoint.y);
    }
    
    *position = op->toPoint;
}
 

@implementation SwiffShapeDefinition

#pragma mark -
#pragma mark Lifecycle

- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie
{
    if ((self = [super init])) {
        SwiffParserByteAlign(parser);

        m_movie = movie;

        SwiffTag  tag     = SwiffParserGetCurrentTag(parser);
        NSInteger version = SwiffParserGetCurrentTagVersion(parser);

        if (tag == SwiffTagDefineShape) {
            SwiffParserReadUInt16(parser, &m_libraryID);

            SwiffLog(@"DEFINESHAPE defines id %ld", (long)m_libraryID);
            
            SwiffParserReadRect(parser, &m_bounds);

            if (version > 3) {
                m_hasEdgeBounds = YES;
                SwiffParserReadRect(parser, &m_edgeBounds);
                
                UInt32 reserved, usesFillWindingRule, usesNonScalingStrokes, usesScalingStrokes;
                SwiffParserReadUBits(parser, 5, &reserved);
                SwiffParserReadUBits(parser, 1, &usesFillWindingRule);
                SwiffParserReadUBits(parser, 1, &usesNonScalingStrokes);
                SwiffParserReadUBits(parser, 1, &usesScalingStrokes);

                m_usesFillWindingRule   = usesFillWindingRule;
                m_usesNonScalingStrokes = usesNonScalingStrokes;
                m_usesScalingStrokes    = usesScalingStrokes;
            }
        }

        SwiffPoint position = { 0, 0 };

        __block UInt16 fillStyleOffset = 0;
        __block UInt16 lineStyleOffset = 0;
        __block UInt16 lineStyleIndex  = 0;
        __block UInt16 fillStyleIndex0 = 0;
        __block UInt16 fillStyleIndex1 = 0;

        NSMutableArray *fillStyles = [[NSMutableArray alloc] init];
        NSMutableArray *lineStyles = [[NSMutableArray alloc] init];

        __block _SwiffShapeOperation *operations = NULL;
        __block NSUInteger operationsCount = 0;
        __block NSUInteger operationsCapacity = 0;
        __block CGFloat maxWidth = 0.0;

        CFMutableArrayRef groups = CFArrayCreateMutable(NULL, 0, NULL);

        m_fillStyles = fillStyles;
        m_lineStyles = lineStyles;
        m_groups     = groups;
        
        void (^readStyles)() = ^{
            fillStyleOffset = [m_fillStyles count];
            lineStyleOffset = [m_lineStyles count];

            NSArray *moreFillStyles = [SwiffFillStyle fillStyleArrayWithParser:parser];
            NSArray *moreLineStyles = [SwiffLineStyle lineStyleArrayWithParser:parser];

            for (SwiffLineStyle *lineStyle in moreLineStyles) {
                CGFloat width = [lineStyle width];
                if (width > maxWidth) maxWidth = width;
            }

            [fillStyles addObjectsFromArray:moreFillStyles];
            [lineStyles addObjectsFromArray:moreLineStyles];
        };
        
        _SwiffShapeOperation *(^nextOperation)() = ^{
            if (operationsCount == operationsCapacity) {
                operationsCapacity *= 2;
                if (!operationsCapacity) operationsCapacity = 32;
                operations = realloc(operations, operationsCapacity * sizeof(_SwiffShapeOperation));
            }
    
            return &operations[operationsCount++];
        };
        
        void (^addEndOperation)() = ^{
            _SwiffShapeOperation *o = nextOperation();

            o->type = _SwiffShapeOperationTypeEnd;
            o->fillStyleIndex = UINT16_MAX;
            o->lineStyleIndex = UINT16_MAX;
        };
        
        void (^addOperation)(NSInteger, SwiffPoint, SwiffPoint, SwiffPoint) = ^(NSInteger type, SwiffPoint from, SwiffPoint control, SwiffPoint to) {
            {
                _SwiffShapeOperation *o = nextOperation();
                o->fromPoint      = from;
                o->controlPoint   = control;
                o->toPoint        = to;
                o->fillStyleIndex = fillStyleIndex0;
                o->lineStyleIndex = lineStyleIndex;
                o->type           = type;
                o->duplicate      = NO;
            }

            if (fillStyleIndex1) {
                _SwiffShapeOperation *o = nextOperation();
                o->fromPoint      = to;
                o->controlPoint   = control;
                o->toPoint        = from;
                o->fillStyleIndex = fillStyleIndex1;
                o->lineStyleIndex = lineStyleIndex;
                o->type           = type;
                o->duplicate      = YES;
            }
        };

        if (tag == SwiffTagDefineShape) {
            readStyles();
        }

        UInt32 fillBits, lineBits;
        SwiffParserReadUBits(parser, 4, &fillBits);
        SwiffParserReadUBits(parser, 4, &lineBits);

        BOOL foundEndRecord = NO;
        while (!foundEndRecord) {
            UInt32 typeFlag;
            SwiffParserReadUBits(parser, 1, &typeFlag);

            if (typeFlag == 0) {
                UInt32 newStyles, changeLineStyle, changeFillStyle0, changeFillStyle1, moveTo;
                SwiffParserReadUBits(parser, 1, &newStyles);
                SwiffParserReadUBits(parser, 1, &changeLineStyle);
                SwiffParserReadUBits(parser, 1, &changeFillStyle1);
                SwiffParserReadUBits(parser, 1, &changeFillStyle0);
                SwiffParserReadUBits(parser, 1, &moveTo);
                
                // ENDSHAPERECORD
                if ((newStyles + changeLineStyle + changeFillStyle1 + changeFillStyle0 + moveTo) == 0) {
                    foundEndRecord = YES;

                // STYLECHANGERECORD
                } else {
                    if (moveTo) {
                        UInt32 moveBits;
                        SwiffParserReadUBits(parser, 5, &moveBits);
                        
                        SInt32 x, y;
                        SwiffParserReadSBits(parser, moveBits, &x);
                        SwiffParserReadSBits(parser, moveBits, &y);

                        position.x = x;
                        position.y = y;
                    }
                    
                    if (changeFillStyle0) {
                        UInt32 i;
                        SwiffParserReadUBits(parser, fillBits, &i);
                        fillStyleIndex0 = i > 0 ? (i + fillStyleOffset) : 0;
                    }

                    if (changeFillStyle1) {
                        UInt32 i;
                        SwiffParserReadUBits(parser, fillBits, &i);
                        fillStyleIndex1 = i > 0 ? (i + fillStyleOffset) : 0;
                    }

                    if (changeLineStyle) {
                        UInt32 i;
                        SwiffParserReadUBits(parser, lineBits, &i);
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
                        SwiffParserReadUBits(parser, 4, &fillBits);
                        SwiffParserReadUBits(parser, 4, &lineBits);
                    }
                }
                
            } else {
                UInt32 straightFlag, numBits;
                SwiffParserReadUBits(parser, 1, &straightFlag);
                SwiffParserReadUBits(parser, 4, &numBits);
                
                // STRAIGHTEDGERECORD
                if (straightFlag) {
                    UInt32 generalLineFlag;
                    SInt32 vertLineFlag = 0, deltaX = 0, deltaY = 0;

                    SwiffParserReadUBits(parser, 1, &generalLineFlag);

                    if (generalLineFlag == 0) {
                        SwiffParserReadSBits(parser, 1, &vertLineFlag);
                    }

                    if (generalLineFlag || !vertLineFlag) {
                        SwiffParserReadSBits(parser, numBits + 2, &deltaX);
                    }

                    if (generalLineFlag || vertLineFlag) {
                        SwiffParserReadSBits(parser, numBits + 2, &deltaY);
                    }

                    SwiffPoint control = { 0, 0 };
                    SwiffPoint from = position;
                    position.x += deltaX;
                    position.y += deltaY;

                    addOperation( _SwiffShapeOperationTypeLine, from, control, position );
                
                // CURVEDEDGERECORD
                } else {
                    SInt32 controlDeltaX = 0, controlDeltaY = 0, anchorDeltaX = 0, anchorDeltaY = 0;
                           
                    SwiffParserReadSBits(parser, numBits + 2, &controlDeltaX);
                    SwiffParserReadSBits(parser, numBits + 2, &controlDeltaY);
                    SwiffParserReadSBits(parser, numBits + 2, &anchorDeltaX);
                    SwiffParserReadSBits(parser, numBits + 2, &anchorDeltaY);

                    SwiffPoint control = {
                        position.x + controlDeltaX,
                        position.y + controlDeltaY,
                    };

                    SwiffPoint from = position;
                    position.x = control.x + anchorDeltaX;
                    position.y = control.y + anchorDeltaY;

                    addOperation( _SwiffShapeOperationTypeCurve, from, control, position );
                }
            }
            
            //!spec: "Each individual shape record is byte-aligned within
            //        an array of shape records" (page 134)
            //
            // In practice, this is not the case.  Hence, leave the next line commented:
            // SwiffParserByteAlign(parser);
        }

        if (operations) {
            addEndOperation();
            CFArrayAppendValue(groups, operations);
        }
        
        CGFloat padding = ceil(maxWidth / 2.0) + 1;
        m_renderBounds = CGRectInset(m_bounds, -padding, -padding);
    }

    return self;
}


- (void) dealloc
{
    if (m_groups) {
        CFIndex length = CFArrayGetCount(m_groups);
        for (CFIndex i = 0; i < length; i++) {
            free((void *)CFArrayGetValueAtIndex(m_groups, i));
        }

        CFRelease(m_groups);
        m_groups = NULL;
    }

    [m_fillStyles release];  m_fillStyles = nil;
    [m_lineStyles release];  m_lineStyles = nil;
    [m_paths      release];  m_paths      = nil;

    [super dealloc];
}


- (void) clearWeakReferences
{
    m_movie = nil;
}


#pragma mark -
#pragma mark Private Methods

- (NSArray *) _linePathsForOperations:(_SwiffShapeOperation *)inOperations
{
    UInt16 index;
    NSMutableArray *result = [NSMutableArray array];

    NSUInteger lineStyleCount = [m_lineStyles count];

    for (index = 1; index <= lineStyleCount; index++) {
        _SwiffShapeOperation *operation = inOperations;
        SwiffPoint position = { NSIntegerMax, NSIntegerMax };
        SwiffPath *path = nil;
        
        BOOL hadFillStyle = NO;
        
        while (operation->type != _SwiffShapeOperationTypeEnd) {
            BOOL   isDuplicate    = operation->duplicate;
            UInt16 lineStyleIndex = operation->lineStyleIndex; 
            UInt16 fillStyleIndex = operation->fillStyleIndex; 
            
            if (lineStyleIndex == index) {
                if (!isDuplicate) { 
                    if (!path) {
                        SwiffLineStyle *lineStyle = [m_lineStyles objectAtIndex:(index - 1)];
                        path = [[SwiffPath alloc] initWithLineStyle:lineStyle fillStyle:nil];
                    }

                    sPathAddShapeOperation(path, operation, &position);
                }
                
                if (fillStyleIndex) {
                    hadFillStyle = YES;
                }
            }
            
            operation++;
        }
        
        if (hadFillStyle && ([[path lineStyle] width] == SwiffLineStyleHairlineWidth)) {
            [path setUseHairlineWithFillWidth:YES];
        }
        
        if (path) {
            SwiffPathAddOperation(path, SwiffPathOperationEnd);

            [result addObject:path];
            [path release];
        }
    }
    
    return result;
}


- (NSArray *) _fillPathsForOperations:(_SwiffShapeOperation *)inOperations
{
    NSMutableArray *results = [NSMutableArray array];
    CFMutableDictionaryRef map = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    
    // Collect operations by fill style
    _SwiffShapeOperation *operation = inOperations;
    while (operation->type != _SwiffShapeOperationTypeEnd) {
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

        _SwiffShapeOperation *currentOperation = (_SwiffShapeOperation *)CFArrayGetValueAtIndex(operations, 0);
        _SwiffShapeOperation *firstOperation   = NULL;

        CFArrayAppendValue(sortedOperations, currentOperation);
        CFArrayRemoveValueAtIndex(operations, 0);
        firstOperation = currentOperation;
        
        while ((jCount = CFArrayGetCount(operations)) > 0) {
            for (j = 0; j < jCount; j++) {
                _SwiffShapeOperation *o = (_SwiffShapeOperation *)CFArrayGetValueAtIndex(operations, j);
                SwiffPoint point1 = o->fromPoint;
                SwiffPoint point2 = currentOperation->toPoint;
                
                if ((point1.x == point2.x) && (point1.y == point2.y)) {
                    SwiffLog(@"Shape: Found connecting path operation");

                    CFArrayAppendValue(sortedOperations, o);
                    currentOperation = o;
                    SwiffLog(@"Shape: currentOperation = %p", currentOperation);
                    break;
                }
            }
            
            
            CFRange entireRange = { 0, CFArrayGetCount(operations) };
            CFIndex indexOfCurrent = CFArrayGetFirstIndexOfValue(operations, entireRange, currentOperation);
            if (indexOfCurrent != kCFNotFound) {
                CFArrayRemoveValueAtIndex(operations, indexOfCurrent);

            } else {
                while ((jCount = CFArrayGetCount(operations)) > 0) {
                    currentOperation = (_SwiffShapeOperation *)CFArrayGetValueAtIndex(operations, 0);
                    CFArrayRemoveValueAtIndex(operations, 0);

                    SwiffLog(@"Shape: No connecting path operation found");
                    SwiffLog(@"Shape: currentOperation = %p", currentOperation);

                    SwiffPoint point1 = firstOperation->fromPoint;
                    SwiffPoint point2 = currentOperation->toPoint;

                    if ((point1.x == point2.x) && (point1.y == point2.y)) {
                        CFArrayInsertValueAtIndex(sortedOperations, 0, currentOperation);
                        firstOperation = currentOperation;
                        SwiffLog(@"Shape: firstOperation = %p", firstOperation);

                    } else {
                        CFArrayAppendValue(sortedOperations, currentOperation);
                        SwiffLog(@"Shape: No join found, moving to:\n    %p\n", currentOperation);
                        break;
                    }
                }
            }
        }
        
        jCount = CFArrayGetCount(sortedOperations);
        if (jCount > 0) {
            SwiffFillStyle *fillStyle = [m_fillStyles objectAtIndex:(fillStyleIndex - 1)];
            
            if (fillStyle) {
                SwiffPath *path = [[SwiffPath alloc] initWithLineStyle:nil fillStyle:fillStyle];
                SwiffPoint position = { NSIntegerMax, NSIntegerMax };

                for (j = 0; j < jCount; j++) {
                    _SwiffShapeOperation *op = (_SwiffShapeOperation *)CFArrayGetValueAtIndex(sortedOperations, j);
                    sPathAddShapeOperation(path, op, &position);
                }

                SwiffPathAddOperation(path, SwiffPathOperationEnd);

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


- (void) _makePaths
{
    @autoreleasepool {
        NSMutableArray *result = [[NSMutableArray alloc] init];

        CFIndex length = CFArrayGetCount(m_groups);
        for (CFIndex i = 0; i < length; i++) {
            _SwiffShapeOperation *operations = (_SwiffShapeOperation *)CFArrayGetValueAtIndex(m_groups, i);
           
            [result addObjectsFromArray:[self _fillPathsForOperations:operations]];
            [result addObjectsFromArray:[self _linePathsForOperations:operations]];
        
            free(operations);
        }
        
        CFRelease(m_groups);
        m_groups = NULL;

        m_paths = result;
    }
}


#pragma mark -
#pragma mark Accessors

- (NSArray *) paths
{
    if (!m_paths && m_groups) {
        [self _makePaths];
    }

    return m_paths;
}


@synthesize movie                 = m_movie,
            libraryID             = m_libraryID,
            bounds                = m_bounds,
            renderBounds          = m_renderBounds,
            edgeBounds            = m_edgeBounds,
            usesFillWindingRule   = m_usesFillWindingRule,
            usesNonScalingStrokes = m_usesNonScalingStrokes,
            usesScalingStrokes    = m_usesScalingStrokes,
            hasEdgeBounds         = m_hasEdgeBounds;

@end

