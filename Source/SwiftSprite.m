//
//  SWFSprite.m
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftSprite.h"

#import "SwiftFrame.h"
#import "SwiftParser.h"
#import "SwiftPlacedObject.h"
#import "SwiftSceneAndFrameLabelData.h"

@interface SwiftPlacedObject (FriendMethods)
@property (nonatomic, retain) NSString *instanceName;
@property (nonatomic, assign) NSInteger objectID;
@property (nonatomic, assign) NSInteger depth;
@property (nonatomic, assign) NSInteger clipDepth;
@property (nonatomic, assign) CGFloat   ratio;
@property (nonatomic, assign) CGAffineTransform affineTransform;
@property (nonatomic, assign) SwiftColorTransform colorTransform;
@end


@interface SwiftFrame ()
- (id) _initWithSortedPlacedObjects:(NSArray *)placedObjects;
@end

@interface SwiftSprite ()
- (void) _parser:(SwiftParser *)parser didFindTag:(SwiftTag)tag version:(NSInteger)version;
@end

@implementation SwiftSprite

- (id) init
{
    if ((self = [super init])) {
        m_frames = [[NSMutableArray alloc] init];
        m_depthToPlacedObjectMap = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    }
    
    return self;
}


- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)baseTag version:(NSInteger)baseVersion
{
    if ((self = [self init])) {
        UInt16 libraryID;
        SwiftParserReadUInt16(parser, &libraryID);
        m_libraryID = libraryID;

        UInt16 frameCount;
        SwiftParserReadUInt16(parser, &frameCount);

        SwiftLog(@"DEFINESPRITE defines id %d", libraryID);

        while (SwiftParserIsValid(parser) && SwiftParserAdvanceToNextTagInSprite(parser)) {
            [self _parser: parser
               didFindTag: SwiftParserGetCurrentTag(parser)
                  version: SwiftParserGetCurrentTagVersion(parser)];
        }

        if (m_sceneAndFrameLabelData) {
            [m_sceneAndFrameLabelData applyLabelsToFrames:m_frames];
            [m_sceneAndFrameLabelData release];
            m_sceneAndFrameLabelData = nil;
        }

        if (m_depthToPlacedObjectMap) {
            CFRelease(m_depthToPlacedObjectMap);
            m_depthToPlacedObjectMap = NULL;
        }

        SwiftLog(@"END");
    
        if (!SwiftParserIsValid(parser)) {
            [self release];
            return nil;
        }
    }
    
    return self;
}

- (void) dealloc
{
    if (m_depthToPlacedObjectMap) {
        CFRelease(m_depthToPlacedObjectMap);
        m_depthToPlacedObjectMap = NULL;
    }

    [m_frames makeObjectsPerformSelector:@selector(setParentSprite:) withObject:nil];
    [m_frames makeObjectsPerformSelector:@selector(setNextFrame:)    withObject:nil];

    [m_frames          release];  m_frames          = nil;
    [m_labelToFrameMap release];  m_labelToFrameMap = nil;
                                  m_lastFrame       = nil;
    
    [m_sceneAndFrameLabelData release];
    m_sceneAndFrameLabelData = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Tag Handlers

- (void) _parser:(SwiftParser *)parser didFindPlaceObjectTag:(SwiftTag)tag version:(NSInteger)version
{
    NSString *name = nil;
    UInt32    hasClipActions, hasClipDepth, hasName, hasRatio, hasColorTransform, hasMatrix, hasCharacter, move;
    UInt16    depth;
    UInt16    characterID;
    UInt16    ratio;
    UInt16    clipDepth;
    
    CGAffineTransform matrix = CGAffineTransformIdentity;
    SwiftColorTransform colorTransform;

    if (version == 2 || version == 3) {
        SwiftParserReadUBits(parser, 1, &hasClipActions);
        SwiftParserReadUBits(parser, 1, &hasClipDepth);
        SwiftParserReadUBits(parser, 1, &hasName);
        SwiftParserReadUBits(parser, 1, &hasRatio);
        SwiftParserReadUBits(parser, 1, &hasColorTransform);
        SwiftParserReadUBits(parser, 1, &hasMatrix);
        SwiftParserReadUBits(parser, 1, &hasCharacter);
        SwiftParserReadUBits(parser, 1, &move);

        if (version == 3) {
            UInt32 unused;
            SwiftParserReadUBits(parser, 8, &unused);
        }

        SwiftParserReadUInt16(parser, &depth);
        if (hasCharacter)       SwiftParserReadUInt16(parser, &characterID);
        if (hasMatrix)          SwiftParserReadMatrix(parser, &matrix);
        if (hasColorTransform)  SwiftParserReadColorTransformWithAlpha(parser, &colorTransform);
        if (hasRatio)           SwiftParserReadUInt16(parser, &ratio);
        if (hasName)            SwiftParserReadString(parser, &name);
        if (hasClipDepth)       SwiftParserReadUInt16(parser, &clipDepth);

    } else {
        hasColorTransform = YES;
        hasMatrix         = YES;
        hasCharacter      = YES;

        SwiftParserReadUInt16(parser, &characterID);
        SwiftParserReadUInt16(parser, &depth);
        SwiftParserReadMatrix(parser, &matrix);
        SwiftParserReadColorTransform(parser, &colorTransform);
    }

    // Not supported yet
    hasClipActions = NO;
    SwiftPlacedObject *placedObject = nil;

    if (move) {
        placedObject = [(SwiftPlacedObject *)CFDictionaryGetValue(m_depthToPlacedObjectMap, (const void *)depth) copy];
    } else {
        placedObject = [[SwiftPlacedObject alloc] initWithDepth:depth];
    }
    
    if (hasCharacter)      [placedObject setObjectID:characterID];
    if (hasClipDepth)      [placedObject setClipDepth:clipDepth];
    if (hasName)           [placedObject setInstanceName:name];
    if (hasRatio)          [placedObject setRatio:ratio];
    if (hasColorTransform) [placedObject setColorTransform:colorTransform];
    if (hasMatrix) {
        [placedObject setAffineTransform:matrix];
    }


    if (SwiftShouldLog()) {
        if (move) {
            SwiftLog(@"PLACEOBJECT%d moves object at depth %d", version, depth);
        } else {
            SwiftLog(@"PLACEOBJECT%d places object %d at depth %d", version, characterID, depth);
        }
    }

    CFDictionarySetValue(m_depthToPlacedObjectMap, (void *)depth, placedObject);
    m_lastFrame = nil;

    [placedObject release];
}


- (void) _parser:(SwiftParser *)parser didFindRemoveObjectTag:(SwiftTag)tag version:(NSInteger)version
{
    UInt16 characterID = 0;
    UInt16 depth       = 0;

    if (version == 1) {
        SwiftParserReadUInt16(parser, &characterID);
    }

    SwiftParserReadUInt16(parser, &depth);

    if (SwiftShouldLog()) {
        if (version == 1) {
            SwiftLog(@"REMOVEOBJECT removes object %d from depth %d", characterID, depth);
        } else {
            SwiftLog(@"REMOVEOBJECT2 removes object from depth %d", depth);
        }
    }

    CFDictionaryRemoveValue(m_depthToPlacedObjectMap, (void *)depth);
    m_lastFrame = nil;
}


- (void) _parser:(SwiftParser *)parser didFindShowFrameTag:(SwiftTag)tag version:(NSInteger)version
{
    // If _lastFrame is still valid, there were no modifications to it, push it
    if (m_lastFrame) {
        [m_frames addObject:m_lastFrame];

    } else {
        CFIndex count = CFDictionaryGetCount(m_depthToPlacedObjectMap);
        NSMutableArray *placedObjects = nil;

        if (count > 0) {
            void **values = (void **)calloc(count, sizeof(void *));
            CFDictionaryGetKeysAndValues(m_depthToPlacedObjectMap, NULL, (const void **)values);
            
            placedObjects = [[NSMutableArray alloc] initWithObjects:(const id *)values count:count];
            [placedObjects sortUsingComparator:^(id a, id b) {
                NSInteger aDepth = [((SwiftPlacedObject *)a) depth];
                NSInteger bDepth = [((SwiftPlacedObject *)b) depth];
                return aDepth - bDepth;
            }];
            
            free(values);
        }

        SwiftFrame *frame = [[SwiftFrame alloc] _initWithSortedPlacedObjects:placedObjects];

        [frame setParentSprite:self];
        [[m_frames lastObject] setNextFrame:frame];
        [m_frames addObject:frame];

        m_lastFrame = frame;

        [frame release];
        [placedObjects release];
    }

    if (SwiftShouldLog()) {
        SwiftLog(@"SHOWFRAME");
    }
}


- (void) _parser:(SwiftParser *)parser didFindFrameLabelTag:(SwiftTag)tag version:(NSInteger)version
{
    NSString *label = nil;
    SwiftParserReadString(parser, &label);

//    [m_workingFrame setLabel:label];
}


- (void) _parser:(SwiftParser *)parser didFindTag:(SwiftTag)tag version:(NSInteger)version
{
    if (tag == SwiftTagDefineSceneAndFrameLabelData) {
        [m_sceneAndFrameLabelData release];
        m_sceneAndFrameLabelData = [[SwiftSceneAndFrameLabelData alloc] initWithParser:parser tag:tag version:version];

    } else if (tag == SwiftTagPlaceObject) {
        [self _parser:parser didFindPlaceObjectTag:tag version:version];
            
    } else if (tag == SwiftTagRemoveObject) {
        [self _parser:parser didFindRemoveObjectTag:tag version:version];

    } else if (tag == SwiftTagShowFrame) {
        [self _parser:parser didFindShowFrameTag:tag version:version];

    } else if (tag == SwiftTagFrameLabel) {
        [self _parser:parser didFindFrameLabelTag:tag version:version];
    }
}


- (SwiftFrame *) frameWithLabel:(NSString *)label
{
    if (!m_labelToFrameMap) {
        NSMutableDictionary *map = [[NSMutableDictionary alloc] init];

        for (SwiftFrame *frame in m_frames) {
            NSString *frameLabel = [frame label];
            if (frameLabel) [map setObject:frame forKey:frameLabel];
        }
        
        m_labelToFrameMap = map;
    }

    return [m_labelToFrameMap objectForKey:label];
}


- (SwiftFrame *) frameAtIndex1:(NSInteger)index1
{
    if (index1 > 0 && index1 <= [m_frames count]) {
        return [m_frames objectAtIndex:(index1 - 1)];
    }
    
    return nil;
}


- (NSInteger) index1OfFrame:(SwiftFrame *)frame
{
    NSUInteger index = [m_frames indexOfObject:frame];

    if (index == NSNotFound) {
        return NSNotFound;
    } else {
        return index + 1;
    }
}


#pragma mark -
#pragma mark Accessors

- (CGRect) bounds       { return CGRectZero; }
- (CGRect) edgeBounds {    return CGRectZero;}

- (BOOL) hasEdgeBounds { return NO; }


@synthesize libraryID  = m_libraryID,
            frames     = m_frames;

@end
