/*
    SwiffMovie.m
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


#import "SwiffMovie.h"

#import "SwiffBitmapDefinition.h"
#import "SwiffDynamicTextDefinition.h"
#import "SwiffFontDefinition.h"
#import "SwiffParser.h"
#import "SwiffScene.h"
#import "SwiffSceneAndFrameLabelData.h"
#import "SwiffShapeDefinition.h"
#import "SwiffSoundDefinition.h"
#import "SwiffSpriteDefinition.h"
#import "SwiffStaticTextDefinition.h"


// Associated value for parser - NSData of the movie-global JPEG tables
static NSString * const SwiffMovieJPEGTablesDataKey = @"SwiffMovieJPEGTablesData";

// Associated value for parser - NSArray of SwiffBitmapDefinition objects that need JPEG tables
static NSString * const SwiffMovieNeedsJPEGTablesDataKey = @"SwiffMovieNeedsJPEGTablesData";


@interface SwiffBitmapDefinition (Friend)
- (void) _setJPEGTablesData:(NSData *)data;
@end

@interface SwiffSpriteDefinition (Protected)
- (void) _decodeData:(NSData *)data;
- (void) _parser:(SwiffParser *)parser didFindTag:(SwiffTag)tag version:(NSInteger)version;
@end


@implementation SwiffMovie

- (id) initWithData:(NSData *)data
{
    if ((self = [self init])) {
        SwiffColor white = { 1.0, 1.0, 1.0, 1.0 };
        m_backgroundColor = white;
        
        [self _decodeData:data];
    }

    return self;
}


- (void) dealloc
{
    SwiffSparseArrayEnumerateValues(&m_definitions, ^(void *v) { [(id)v release]; });
    SwiffSparseArrayFree(&m_definitions);

    [m_scenes              release];  m_scenes              = nil;
    [m_sceneNameToSceneMap release];  m_sceneNameToSceneMap = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods

- (void) _decodeData:(NSData *)data
{
    if (!data) return;
    
    SwiffParser *parser = SwiffParserCreate([data bytes], [data length]);
    
    SwiffHeader header;
    SwiffParserReadHeader(parser, &header);
    
    m_version   = header.version;
    m_stageRect = header.stageRect;
    m_frameRate = header.frameRate;

    if (m_version < 6) {
        SwiffParserSetStringEncoding(parser, SwiffGetLegacyStringEncoding());
    }

    // Parse tags
    {
        m_movie = self;

        while (SwiffParserIsValid(parser)) {
            SwiffParserAdvanceToNextTag(parser);
            
            SwiffTag  tag     = SwiffParserGetCurrentTag(parser);
            NSInteger version = SwiffParserGetCurrentTagVersion(parser);

            if (tag == SwiffTagEnd) break;

            [self _parser:parser didFindTag:tag version:version];
        }
        
        m_movie = nil;
    }

    NSData *jpegTablesData = SwiffParserGetAssociatedValue(parser, SwiffMovieJPEGTablesDataKey);
    if (jpegTablesData) {
        NSArray *needsTables = SwiffParserGetAssociatedValue(parser, SwiffMovieNeedsJPEGTablesDataKey);

        for (SwiffBitmapDefinition *bitmap in needsTables) {
            [bitmap _setJPEGTablesData:jpegTablesData];
        }
    }

    if (m_sceneAndFrameLabelData) {
        [m_sceneAndFrameLabelData applyLabelsToFrames:m_frames];
        m_scenes = [[m_sceneAndFrameLabelData scenesForFrames:m_frames] retain];
        
        [m_sceneAndFrameLabelData clearWeakReferences];
        [m_sceneAndFrameLabelData release];
        m_sceneAndFrameLabelData = nil;

    } else {
        SwiffScene *scene = [[SwiffScene alloc] initWithMovie:self name:nil indexInMovie:0 frames:m_frames];
        m_scenes = [[NSArray alloc] initWithObjects:scene, nil];
        [scene release];
    }
    
    SwiffParserFree(parser);
}


- (void) _parser:(SwiffParser *)parser didFindTag:(SwiffTag)tag version:(NSInteger)version
{
    id<SwiffDefinition> definitionToAdd = nil;

    if (tag == SwiffTagDefineShape) {
        definitionToAdd = [[SwiffShapeDefinition alloc] initWithParser:parser movie:self];

    } else if (tag == SwiffTagDefineButton) {
        //!issue2: Button Support
    
    } else if (tag == SwiffTagDefineMorphShape) {
        //!issue1: MorphShape Support

    } else if (tag == SwiffTagJPEGTables) {
        UInt32 remaining = SwiffParserGetBytesRemainingInCurrentTag(parser);

        if (!SwiffParserGetAssociatedValue(parser, SwiffMovieJPEGTablesDataKey)) {
            NSData *data = nil;
            SwiffParserReadData(parser, remaining, &data);
            SwiffParserSetAssociatedValue(parser, SwiffMovieJPEGTablesDataKey, data);
        }

    } else if (tag == SwiffTagDefineBits || tag == SwiffTagDefineBitsLossless) {
        SwiffBitmapDefinition *bitmap = [[SwiffBitmapDefinition alloc] initWithParser:parser movie:self];

        if (tag == SwiffTagDefineBits) {
            NSMutableArray *needsTables = SwiffParserGetAssociatedValue(parser, SwiffMovieNeedsJPEGTablesDataKey);

            if (!needsTables) {
                needsTables = [[NSMutableArray alloc] init];
                SwiffParserSetAssociatedValue(parser, SwiffMovieNeedsJPEGTablesDataKey, needsTables);
                [needsTables release];
            }
            
            [needsTables addObject:bitmap];
        }

        definitionToAdd = bitmap;

    } else if (tag == SwiffTagDefineVideoStream) {
        //!issue3: Video Support
    
    } else if (tag == SwiffTagDefineSound) {
        definitionToAdd = [[SwiffSoundDefinition alloc] initWithParser:parser movie:self];

    } else if (tag == SwiffTagDefineSprite) {
        definitionToAdd = [[SwiffSpriteDefinition alloc] initWithParser:parser movie:self];

    } else if ((tag == SwiffTagDefineFont)     ||
               (tag == SwiffTagDefineFontInfo) ||
               (tag == SwiffTagDefineFontName) ||
               (tag == SwiffTagDefineFontAlignZones))
    {
        UInt16 fontID;
        SwiffParserReadUInt16(parser, &fontID);

        NSNumber  *key  = [[NSNumber alloc] initWithInteger:(NSInteger)fontID];
        SwiffFontDefinition *font = SwiffMovieGetDefinition(self, fontID);
        
        if (![font isKindOfClass:[SwiffFontDefinition class]]) {
            definitionToAdd = font = [[SwiffFontDefinition alloc] initWithLibraryID:fontID movie:self];
        }
        
        if (tag == SwiffTagDefineFont) {
            [font readDefineFontTagFromParser:parser];
        } else if (tag == SwiffTagDefineFontInfo) {
            [font readDefineFontInfoTagFromParser:parser];
        } else if (tag == SwiffTagDefineFontName) {
            [font readDefineFontNameTagFromParser:parser];
        } else if (tag == SwiffTagDefineFontAlignZones) {
            [font readDefineFontAlignZonesFromParser:parser];
        }

        [key release];
    
    } else if (tag == SwiffTagDefineText) {
        definitionToAdd = [[SwiffStaticTextDefinition alloc] initWithParser:parser movie:self];
    
    } else if (tag == SwiffTagDefineEditText) {
        definitionToAdd = [[SwiffDynamicTextDefinition alloc] initWithParser:parser movie:self];

    } else if (tag == SwiffTagSetBackgroundColor) {
        SwiffParserReadColorRGB(parser, &m_backgroundColor);

    } else {
        [super _parser:parser didFindTag:tag version:version];
    }

    if (definitionToAdd) {
        UInt16 libraryID = [definitionToAdd libraryID];

        id existingValue = SwiffSparseArrayGetValueAtIndex(&m_definitions, libraryID);
        if (existingValue) [existingValue release];

        SwiffSparseArraySetConsumedObjectAtIndex(&m_definitions, libraryID, definitionToAdd);
    }
}


#pragma mark -
#pragma mark Public Methods

id<SwiffDefinition> SwiffMovieGetDefinition(SwiffMovie *movie, UInt16 libraryID)
{
    return SwiffSparseArrayGetValueAtIndex(&movie->m_definitions, libraryID);
}


- (id<SwiffDefinition>) definitionWithLibraryID:(UInt16)libraryID
{
    return SwiffMovieGetDefinition(self, libraryID);
}


- (id) _definitionWithLibraryID:(UInt16)libraryID ofClass:(Class)cls
{
    id<SwiffDefinition> definition = [self definitionWithLibraryID:libraryID];
    return [definition isKindOfClass:cls] ? definition : nil;
}

- (SwiffBitmapDefinition *) bitmapDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiffBitmapDefinition class]]; }

- (SwiffDynamicTextDefinition *) dynamicTextDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiffDynamicTextDefinition class]]; }

- (SwiffFontDefinition *) fontDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiffFontDefinition class]]; }

- (SwiffSpriteDefinition *) spriteDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiffSpriteDefinition class]]; }

- (SwiffShapeDefinition *) shapeDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiffShapeDefinition class]]; }

- (SwiffSoundDefinition *) soundDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiffSoundDefinition class]]; }

- (SwiffStaticTextDefinition *) staticTextDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiffStaticTextDefinition class]]; }


- (SwiffScene *) sceneWithName:(NSString *)name
{
    if (!m_sceneNameToSceneMap) {
        NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:[m_scenes count]];
        
        for (SwiffScene *scene in m_scenes) {
            [map setObject:scene forKey:[scene name]];
        }
    
        m_sceneNameToSceneMap = map;
    }

    return [m_sceneNameToSceneMap objectForKey:name];
}


#pragma mark -
#pragma mark Accessors

- (SwiffColor *) backgroundColorPointer
{
    return &m_backgroundColor;
}

@synthesize scenes          = m_scenes,
            version         = m_version,
            frameRate       = m_frameRate,
            stageRect       = m_stageRect,
            backgroundColor = m_backgroundColor;

@end
