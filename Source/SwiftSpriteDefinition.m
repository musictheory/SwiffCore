/*
    SwiftSprite.m
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

#import "SwiftSpriteDefinition.h"

#import "SwiftFrame.h"
#import "SwiftParser.h"
#import "SwiftPlacedObject.h"
#import "SwiftPlacedStaticText.h"
#import "SwiftPlacedText.h"
#import "SwiftSceneAndFrameLabelData.h"

@interface SwiftPlacedObject (FriendMethods)
@property (nonatomic, retain) NSString *instanceName;
@property (nonatomic, assign) UInt16  libraryID;
@property (nonatomic, assign) UInt16  depth;
@property (nonatomic, assign) UInt16  clipDepth;
@property (nonatomic, assign) CGFloat ratio;
@property (nonatomic, assign) CGAffineTransform affineTransform;
@property (nonatomic, assign) SwiftColorTransform colorTransform;
@end


@interface SwiftFrame ()
- (id) _initWithSortedPlacedObjects:(NSArray *)placedObjects;
@end

@interface SwiftSpriteDefinition ()
- (void) _parser:(SwiftParser *)parser didFindTag:(SwiftTag)tag version:(NSInteger)version;
@end

@implementation SwiftSpriteDefinition

- (id) init
{
    if ((self = [super init])) {
        m_frames = [[NSMutableArray alloc] init];
        m_depthToPlacedObjectMap = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    }
    
    return self;
}


- (id) initWithParser:(SwiftParser *)parser movie:(SwiftMovie *)movie
{
    if ((self = [self init])) {
        SwiftParserReadUInt16(parser, &m_libraryID);

        UInt16 frameCount;
        SwiftParserReadUInt16(parser, &frameCount);

        SwiftLog(@"DEFINESPRITE defines id %ld", (long)m_libraryID);

        m_movie = movie;

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
        
        m_movie = nil;

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

    [m_frames          release];  m_frames          = nil;
    [m_labelToFrameMap release];  m_labelToFrameMap = nil;
                                  m_lastFrame       = nil;
    
    [m_sceneAndFrameLabelData release];
    m_sceneAndFrameLabelData = nil;

    [super dealloc];
}


- (void) clearWeakReferences
{
    m_movie = nil;
}


#pragma mark -
#pragma mark Tag Handlers

- (void) _parser:(SwiftParser *)parser didFindPlaceObjectTag:(SwiftTag)tag version:(NSInteger)version
{
    NSString *name = nil;
    UInt32    hasClipActions, hasClipDepth, hasName, hasRatio, hasColorTransform, hasMatrix, hasLibraryID, move;
    UInt16    depth;
    UInt16    libraryID;
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
        SwiftParserReadUBits(parser, 1, &hasLibraryID);
        SwiftParserReadUBits(parser, 1, &move);

        if (version == 3) {
            UInt32 unused;
            SwiftParserReadUBits(parser, 8, &unused);
        }

        SwiftParserReadUInt16(parser, &depth);
        if (hasLibraryID)       SwiftParserReadUInt16(parser, &libraryID);
        if (hasMatrix)          SwiftParserReadMatrix(parser, &matrix);
        if (hasColorTransform)  SwiftParserReadColorTransformWithAlpha(parser, &colorTransform);
        if (hasRatio)           SwiftParserReadUInt16(parser, &ratio);
        if (hasName)            SwiftParserReadString(parser, &name);
        if (hasClipDepth)       SwiftParserReadUInt16(parser, &clipDepth);

    } else {
        move         = YES;
        hasMatrix    = YES;
        hasLibraryID = YES;
        hasClipDepth = NO;
        hasName      = NO;
        hasRatio     = NO;

        SwiftParserReadUInt16(parser, &libraryID);
        SwiftParserReadUInt16(parser, &depth);
        SwiftParserReadMatrix(parser, &matrix);

        SwiftParserByteAlign(parser);
        hasColorTransform = (SwiftParserGetBytesRemainingInCurrentTag(parser) > 0);

        if (hasColorTransform) {
            SwiftParserReadColorTransform(parser, &colorTransform);
        }
    }

    // Not supported yet
    hasClipActions = NO;

    Class cls = [SwiftPlacedObject class];
    SwiftPlacedObject *placedObject = nil;

    id<SwiftDefinition> definition = nil;
    
    if (hasLibraryID) {
        definition = [m_movie definitionWithLibraryID:libraryID];

        if ([definition isKindOfClass:[SwiftStaticTextDefinition class]]) {
            cls = [SwiftPlacedStaticText class];
        } else if ([definition isKindOfClass:[SwiftTextDefinition class]]) {
            cls = [SwiftPlacedText class];
        }
    }

    if (move) {
        SwiftPlacedObject *existing = (SwiftPlacedObject *)CFDictionaryGetValue(m_depthToPlacedObjectMap, (const void *)depth);
        if (!hasLibraryID) cls = [existing class];
        placedObject = [[cls alloc] initWithPlacedObject:existing];
    }

    if (!placedObject) {
        placedObject = [[cls alloc] initWithDepth:depth];
    }
    
    if ([definition conformsToProtocol:@protocol(SwiftPlacableDefinition)]) {
        [placedObject setDefinition:(id<SwiftPlacableDefinition>)definition];
    }
    
    if (hasLibraryID)      [placedObject setLibraryID:libraryID];
    if (hasClipDepth)      [placedObject setClipDepth:clipDepth];
    if (hasName)           [placedObject setInstanceName:name];
    if (hasRatio)          [placedObject setRatio:ratio];
    if (hasColorTransform) [placedObject setColorTransform:colorTransform];
    if (hasMatrix) {
        [placedObject setAffineTransform:matrix];
    }


    if (SwiftShouldLog()) {
        if (move) {
            SwiftLog(@"PLACEOBJECT%ld moves object at depth %ld", (long)version, (long)depth);
        } else {
            SwiftLog(@"PLACEOBJECT%ld places object %ld at depth %ld", (long)version, (long)[placedObject libraryID], (long)depth);
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


- (SwiftFrame *) frameAtIndex1:(NSUInteger)index1
{
    if (index1 > 0 && index1 <= [m_frames count]) {
        return [m_frames objectAtIndex:(index1 - 1)];
    }
    
    return nil;
}


- (NSUInteger) index1OfFrame:(SwiftFrame *)frame
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

- (CGRect) bounds      { return CGRectZero; }
- (CGRect) edgeBounds  { return CGRectZero; }
- (BOOL) hasEdgeBounds { return NO;         }

@synthesize movie      = m_movie,
            libraryID  = m_libraryID,
            frames     = m_frames;

@end
