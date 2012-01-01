/*
    SwiffSprite.m
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

#import "SwiffSpriteDefinition.h"

#import "SwiffFrame.h"
#import "SwiffMovie.h"
#import "SwiffParser.h"
#import "SwiffPlacedObject.h"
#import "SwiffPlacedDynamicText.h"
#import "SwiffSceneAndFrameLabelData.h"
#import "SwiffSoundDefinition.h"
#import "SwiffSoundEvent.h"
#import "SwiffFilter.h"

@interface SwiffPlacedObject (FriendMethods)
@property (nonatomic, retain) NSString *instanceName;
@property (nonatomic, assign) UInt16  libraryID;
@property (nonatomic, assign) UInt16  depth;
@property (nonatomic, assign) UInt16  clipDepth;
@property (nonatomic, assign) CGFloat ratio;
@property (nonatomic, assign) CGAffineTransform affineTransform;
@property (nonatomic, assign) SwiffColorTransform colorTransform;
@end


@interface SwiffFrame ()
- (id) _initWithSortedPlacedObjects: (NSArray *) placedObjects
                          withNames: (NSArray *) placedObjectsWithNames
                        soundEvents: (NSArray *) soundEvents
                        streamSound: (SwiffSoundDefinition *) streamSound
                   streamBlockIndex: (NSUInteger) streamBlockIndex;
@end

@interface SwiffSpriteDefinition ()
- (void) _parser:(SwiffParser *)parser didFindTag:(SwiffTag)tag version:(NSInteger)version;
@end


@implementation SwiffSpriteDefinition

- (id) init
{
    if ((self = [super init])) {
        m_frames = [[NSMutableArray alloc] init];
    }
    
    return self;
}


- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie
{
    if ((self = [self init])) {
        SwiffParserReadUInt16(parser, &m_libraryID);

        UInt16 frameCount;
        SwiffParserReadUInt16(parser, &frameCount);

        m_movie = movie;

        SwiffParser *subparser = SwiffParserCreate(SwiffParserGetCurrentBytePointer(parser), SwiffParserGetBytesRemainingInCurrentTag(parser));
        SwiffParserSetStringEncoding(subparser, SwiffParserGetStringEncoding(parser));

        SwiffLog(@"Sprite", @"DEFINESPRITE defines id %ld", (long)m_libraryID);

        while (SwiffParserIsValid(subparser)) {
            SwiffParserAdvanceToNextTag(subparser);
            
            SwiffTag  tag     = SwiffParserGetCurrentTag(subparser);
            NSInteger version = SwiffParserGetCurrentTagVersion(subparser);

            if (tag == SwiffTagEnd) break;

            [self _parser:subparser didFindTag:tag version:version];
        }

        if (m_sceneAndFrameLabelData) {
            [m_sceneAndFrameLabelData applyLabelsToFrames:m_frames];
            [m_sceneAndFrameLabelData clearWeakReferences];
            [m_sceneAndFrameLabelData release];
            m_sceneAndFrameLabelData = nil;
        }

        SwiffSparseArrayEnumerateValues(&m_placedObjects, ^(void *v) { [(id)v release]; });
        SwiffSparseArrayFree(&m_placedObjects);

        SwiffParserFree(subparser);

        SwiffLog(@"Sprite", @"END");
    
        if (!SwiffParserIsValid(parser)) {
            [self release];
            return nil;
        }
    }
    
    return self;
}


- (void) dealloc
{
    SwiffSparseArrayEnumerateValues(&m_placedObjects, ^(void *v) { [(id)v release]; });
    SwiffSparseArrayFree(&m_placedObjects);

    [m_frames          release];  m_frames          = nil;
    [m_labelToFrameMap release];  m_labelToFrameMap = nil;
                                  m_lastFrame       = nil;

    [m_sceneAndFrameLabelData clearWeakReferences];
    [m_sceneAndFrameLabelData release];
    m_sceneAndFrameLabelData = nil;

    [m_currentSoundEvents release];
    m_currentSoundEvents = nil;

    [m_currentStreamSoundDefinition release];
    m_currentStreamSoundDefinition = nil;

    [super dealloc];
}


- (void) clearWeakReferences
{
    m_movie = nil;
}


#pragma mark -
#pragma mark Tag Handlers

- (void) _parser:(SwiffParser *)parser didFindPlaceObjectTag:(SwiffTag)tag version:(NSInteger)version
{
    NSString *name = nil;
    BOOL      hasClipActions = NO, hasClipDepth = NO, hasName = NO, hasRatio = NO, hasColorTransform = NO, hasMatrix = NO, hasLibraryID = NO, move = NO;
    BOOL      hasImage = NO, hasClassName = NO, hasCacheAsBitmap = NO, hasBlendMode = NO, hasFilterList = NO;
    UInt16    depth;
    UInt16    libraryID;
    UInt16    ratio;
    UInt16    clipDepth;

    CGAffineTransform matrix     = CGAffineTransformIdentity;
    SwiffBlendMode    blendMode  = SwiffBlendModeNormal;
    NSArray          *filterList = nil;
    NSString         *className  = nil;
    SwiffColorTransform colorTransform;

    if (version == 2 || version == 3) {
        UInt32 tmp;

        SwiffParserReadUBits(parser, 1, &tmp);  hasClipActions    = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  hasClipDepth      = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  hasName           = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  hasRatio          = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  hasColorTransform = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  hasMatrix         = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  hasLibraryID      = tmp;
        SwiffParserReadUBits(parser, 1, &tmp);  move              = tmp;

        if (version == 3) {
            SwiffParserReadUBits(parser, 3, &tmp);
            SwiffParserReadUBits(parser, 1, &tmp);  hasImage         = tmp;
            SwiffParserReadUBits(parser, 1, &tmp);  hasClassName     = tmp;
            SwiffParserReadUBits(parser, 1, &tmp);  hasCacheAsBitmap = tmp;
            SwiffParserReadUBits(parser, 1, &tmp);  hasBlendMode     = tmp;
            SwiffParserReadUBits(parser, 1, &tmp);  hasFilterList    = tmp;

        } else {
            hasImage         = NO;
            hasClassName     = NO;
            hasCacheAsBitmap = NO;
            hasBlendMode     = NO;
            hasFilterList    = NO;
        }

        SwiffParserReadUInt16(parser, &depth);

        if (hasClassName || (hasImage && hasLibraryID)) {
            SwiffParserReadString(parser, &className);
        }

        if (hasLibraryID)       SwiffParserReadUInt16(parser, &libraryID);
        if (hasMatrix)          SwiffParserReadMatrix(parser, &matrix);
        if (hasColorTransform)  SwiffParserReadColorTransformWithAlpha(parser, &colorTransform);
        if (hasRatio)           SwiffParserReadUInt16(parser, &ratio);
        if (hasName)            SwiffParserReadString(parser, &name);
        if (hasClipDepth)       SwiffParserReadUInt16(parser, &clipDepth);

        if (hasFilterList) {
            filterList = [SwiffFilter filterListWithParser:parser];
        }
        
        if (hasBlendMode) {
            UInt8 tmp8;
            SwiffParserReadUInt8(parser, &tmp8);
            blendMode = tmp8;
        }
        
        if (hasCacheAsBitmap) {
            UInt8 rawCacheAsBitmap;
            SwiffParserReadUInt8(parser, &rawCacheAsBitmap);
            hasCacheAsBitmap = (rawCacheAsBitmap > 0);
        }

        if (hasClipActions) {
            //!nyi: Clip actions
        }

    } else {
        move         = YES;
        hasMatrix    = YES;
        hasLibraryID = YES;

        SwiffParserReadUInt16(parser, &libraryID);
        SwiffParserReadUInt16(parser, &depth);
        SwiffParserReadMatrix(parser, &matrix);

        SwiffParserByteAlign(parser);
        hasColorTransform = (SwiffParserGetBytesRemainingInCurrentTag(parser) > 0);

        if (hasColorTransform) {
            SwiffParserReadColorTransform(parser, &colorTransform);
        }
    }

    SwiffPlacedObject *existingPlacedObject = SwiffSparseArrayGetValueAtIndex(&m_placedObjects, depth);
    SwiffPlacedObject *placedObject = SwiffPlacedObjectCreate(m_movie, hasLibraryID ? libraryID : 0, move ? existingPlacedObject : nil);

    [placedObject setDepth:depth];

    if (hasImage) {
        [placedObject setPlacesImage:YES];
        [placedObject setClassName:className];
    }

    if (hasClassName)      [placedObject setClassName:className];
    if (hasClipDepth)      [placedObject setClipDepth:clipDepth];
    if (hasName)           [placedObject setName:name];
    if (hasRatio)          [placedObject setRatio:ratio];
    if (hasColorTransform) [placedObject setColorTransform:colorTransform];
    if (hasBlendMode)      [placedObject setBlendMode:blendMode];
    if (hasFilterList)     [placedObject setFilters:filterList];
    if (hasCacheAsBitmap)  [placedObject setCachesAsBitmap:YES];

    if (hasMatrix) {
        [placedObject setAffineTransform:matrix];
    }

    if (SwiffLogIsCategoryEnabled(@"Sprite")) {
        if (move) {
            SwiffLog(@"Sprite", @"PLACEOBJECT%ld moves object at depth %ld", (long)version, (long)depth);
        } else {
            SwiffLog(@"Sprite", @"PLACEOBJECT%ld places object %ld at depth %ld", (long)version, (long)[placedObject libraryID], (long)depth);
        }
    }

    [existingPlacedObject release];
    SwiffSparseArraySetConsumedObjectAtIndex(&m_placedObjects, depth, placedObject);
    m_lastFrame = nil;
}


- (void) _parser:(SwiffParser *)parser didFindRemoveObjectTag:(SwiffTag)tag version:(NSInteger)version
{
    UInt16 characterID = 0;
    UInt16 depth       = 0;

    if (version == 1) {
        SwiffParserReadUInt16(parser, &characterID);
    }

    SwiffParserReadUInt16(parser, &depth);

    if (SwiffLogIsCategoryEnabled(@"Sprite")) {
        if (version == 1) {
            SwiffLog(@"Sprite", @"REMOVEOBJECT removes object %d from depth %d", characterID, depth);
        } else {
            SwiffLog(@"Sprite", @"REMOVEOBJECT2 removes object from depth %d", depth);
        }
    }

    SwiffPlacedObject *placedObject = SwiffSparseArrayGetValueAtIndex(&m_placedObjects, depth);
    [placedObject release];

    SwiffSparseArraySetValueAtIndex(&m_placedObjects, depth, nil);
    m_lastFrame = nil;
}


- (void) _parser:(SwiffParser *)parser didFindShowFrameTag:(SwiffTag)tag version:(NSInteger)version
{
    NSArray *placedObjects = nil;
    NSArray *placedObjectsWithNames = nil;

    // If _lastFrame is still valid, there were no modifications to it, use the same placed objects array
    //
    if (m_lastFrame) {
        placedObjects = [[m_lastFrame placedObjects] retain];
        placedObjectsWithNames = [[m_lastFrame placedObjectsWithNames] retain];

    } else {
        NSMutableArray *sortedPlacedObjects = [[NSMutableArray alloc] init];
        NSMutableArray *sortedPlacedObjectsWithNames = [[NSMutableArray alloc] init];         
        
        SwiffSparseArrayEnumerateValues(&m_placedObjects, ^(void *value) {
            SwiffPlacedObject *po = value;
            [sortedPlacedObjects addObject:po];
            if ([po name]) [sortedPlacedObjectsWithNames addObject:po];
        });

        if ([sortedPlacedObjects count]) {
            placedObjects          = sortedPlacedObjects;
            placedObjectsWithNames = sortedPlacedObjectsWithNames;
        } else {
            [sortedPlacedObjects release];
            [sortedPlacedObjectsWithNames release];
        }
    }

    SwiffSoundDefinition *streamSound      = m_currentStreamBlockIndex >= 0 ? m_currentStreamSoundDefinition : nil;
    NSInteger             streamBlockIndex = m_currentStreamBlockIndex >= 0 ? m_currentStreamBlockIndex      : 0;

    SwiffFrame *frame = [[SwiffFrame alloc] _initWithSortedPlacedObjects: placedObjects
                                                               withNames: placedObjectsWithNames
                                                             soundEvents: m_currentSoundEvents
                                                             streamSound: streamSound
                                                        streamBlockIndex: streamBlockIndex];

    [m_frames addObject:frame];
    m_lastFrame = frame;

    [frame release];
    [placedObjects release];
    [placedObjectsWithNames release];

    SwiffLog(@"Sprite", @"SHOWFRAME");
}


- (void) _parser:(SwiffParser *)parser didFindFrameLabelTag:(SwiffTag)tag version:(NSInteger)version
{
    NSString *label = nil;
    SwiffParserReadString(parser, &label);

//    [m_workingFrame setLabel:label];
}


- (void) _parser:(SwiffParser *)parser didFindTag:(SwiffTag)tag version:(NSInteger)version
{
    if (tag == SwiffTagDefineSceneAndFrameLabelData) {
        [m_sceneAndFrameLabelData clearWeakReferences];
        [m_sceneAndFrameLabelData release];
        m_sceneAndFrameLabelData = [[SwiffSceneAndFrameLabelData alloc] initWithParser:parser movie:m_movie];

    } else if (tag == SwiffTagPlaceObject) {
        [self _parser:parser didFindPlaceObjectTag:tag version:version];
            
    } else if (tag == SwiffTagRemoveObject) {
        [self _parser:parser didFindRemoveObjectTag:tag version:version];

    } else if (tag == SwiffTagShowFrame) {
        [self _parser:parser didFindShowFrameTag:tag version:version];

        m_currentStreamBlockIndex = -1;
        [m_currentSoundEvents release];
        m_currentSoundEvents = nil;

    } else if (tag == SwiffTagFrameLabel) {
        [self _parser:parser didFindFrameLabelTag:tag version:version];

    } else if (tag == SwiffTagSoundStreamHead) {
        [m_currentStreamSoundDefinition release];
        m_currentStreamSoundDefinition = [[SwiffSoundDefinition alloc] initWithParser:parser movie:m_movie];
        m_currentStreamBlockIndex = -1;

    } else if (tag == SwiffTagSoundStreamBlock) {
        m_currentStreamBlockIndex = [m_currentStreamSoundDefinition readSoundStreamBlockTagFromParser:parser];

    } else if (tag == SwiffTagStartSound) {
        SwiffSoundEvent *event = [[SwiffSoundEvent alloc] initWithParser:parser];
    
        if (!m_currentSoundEvents) m_currentSoundEvents = [[NSMutableArray alloc] init];
        [m_currentSoundEvents addObject:event];
        
        [event release];
    }
}


- (SwiffFrame *) frameWithLabel:(NSString *)label
{
    if (!m_labelToFrameMap) {
        NSMutableDictionary *map = [[NSMutableDictionary alloc] init];

        for (SwiffFrame *frame in m_frames) {
            NSString *frameLabel = [frame label];
            if (frameLabel) [map setObject:frame forKey:frameLabel];
        }
        
        m_labelToFrameMap = map;
    }

    return [m_labelToFrameMap objectForKey:label];
}


- (SwiffFrame *) frameAtIndex1:(NSUInteger)index1
{
    if (index1 > 0 && index1 <= [m_frames count]) {
        return [m_frames objectAtIndex:(index1 - 1)];
    }
    
    return nil;
}


- (NSUInteger) index1OfFrame:(SwiffFrame *)frame
{
    NSUInteger index = [m_frames indexOfObject:frame];
    return (index == NSNotFound) ? NSNotFound : (index + 1);
}


- (SwiffFrame *) frameAtIndex:(NSUInteger)index
{
    if (index < [m_frames count]) {
        return [m_frames objectAtIndex:index];
    }
    
    return nil;
}


- (NSUInteger) indexOfFrame:(SwiffFrame *)frame
{
    return [m_frames indexOfObject:frame];
}


#pragma mark -
#pragma mark Accessors

- (void) _makeBounds
{
    for (SwiffFrame *frame in m_frames) {
        for (SwiffPlacedObject *placedObject in [frame placedObjects]) {
            id<SwiffDefinition> definition = SwiffMovieGetDefinition(m_movie, placedObject->m_libraryID);
            
            CGRect bounds       = CGRectApplyAffineTransform([definition bounds],       placedObject->m_affineTransform);
            CGRect renderBounds = CGRectApplyAffineTransform([definition renderBounds], placedObject->m_affineTransform);
            
            if (CGRectIsEmpty(m_bounds)) {
                m_bounds = bounds;
            } else {
                m_bounds = CGRectUnion(m_bounds, bounds);
            }

            if (CGRectIsEmpty(m_renderBounds)) {
                m_renderBounds = renderBounds;
            } else {
                m_renderBounds = CGRectUnion(m_renderBounds, renderBounds);
            }
        }
    }
}


- (CGRect) renderBounds
{
    if (CGRectIsEmpty(m_renderBounds)) {
        [self _makeBounds];
    }

    return m_renderBounds;
}


- (CGRect) bounds
{
    if (CGRectIsEmpty(m_bounds)) {
        [self _makeBounds];
    }
    
    return m_bounds;
}


@synthesize movie      = m_movie,
            libraryID  = m_libraryID,
            frames     = m_frames;

@end
