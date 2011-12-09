/*
    SwiftMovie.m
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


#import "SwiftMovie.h"

#import "SwiftBitmapDefinition.h"
#import "SwiftDynamicTextDefinition.h"
#import "SwiftFontDefinition.h"
#import "SwiftParser.h"
#import "SwiftScene.h"
#import "SwiftSceneAndFrameLabelData.h"
#import "SwiftShapeDefinition.h"
#import "SwiftSoundDefinition.h"
#import "SwiftSpriteDefinition.h"
#import "SwiftStaticTextDefinition.h"


// Associated value for parser - NSData of the movie-global JPEG tables
static NSString * const SwiftMovieJPEGTablesDataKey = @"SwiftMovieJPEGTablesData";

// Associated value for parser - NSArray of SwiftBitmapDefinition objects that need JPEG tables
static NSString * const SwiftMovieNeedsJPEGTablesDataKey = @"SwiftMovieNeedsJPEGTablesData";


@interface SwiftBitmapDefinition (Friend)
- (void) _setJPEGTablesData:(NSData *)data;
@end

@interface SwiftSpriteDefinition (Protected)
- (void) _decodeData:(NSData *)data;
- (void) _parser:(SwiftParser *)parser didFindTag:(SwiftTag)tag version:(NSInteger)version;
@end


@implementation SwiftMovie

- (id) initWithData:(NSData *)data
{
    if ((self = [self init])) {
        m_definitionMap = [[NSMutableDictionary alloc] init];

        SwiftColor white = { 1.0, 1.0, 1.0, 1.0 };
        m_backgroundColor = white;
        
        [self _decodeData:data];
    }

    return self;
}


- (void) dealloc
{
    [[m_definitionMap allValues] makeObjectsPerformSelector:@selector(clearWeakReferences)];

    [m_scenes              release];  m_scenes              = nil;
    [m_sceneNameToSceneMap release];  m_sceneNameToSceneMap = nil;
    [m_definitionMap       release];  m_definitionMap       = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods

- (void) _decodeData:(NSData *)data
{
    if (!data) return;
    
    SwiftParser *parser = SwiftParserCreate([data bytes], [data length]);
    
    SwiftHeader header;
    SwiftParserReadHeader(parser, &header);
    
    m_version   = header.version;
    m_stageRect = header.stageRect;
    m_frameRate = header.frameRate;

    if (m_version < 6) {
        SwiftParserSetStringEncoding(parser, SwiftGetLegacyStringEncoding());
    }

    // Parse tags
    {
        m_movie = self;

        while (SwiftParserIsValid(parser)) {
            SwiftParserAdvanceToNextTag(parser);
            
            SwiftTag  tag     = SwiftParserGetCurrentTag(parser);
            NSInteger version = SwiftParserGetCurrentTagVersion(parser);

            if (tag == SwiftTagEnd) break;

            [self _parser:parser didFindTag:tag version:version];
        }
        
        m_movie = nil;
    }

    NSData *jpegTablesData = SwiftParserGetAssociatedValue(parser, SwiftMovieJPEGTablesDataKey);
    if (jpegTablesData) {
        NSArray *needsTables = SwiftParserGetAssociatedValue(parser, SwiftMovieNeedsJPEGTablesDataKey);

        for (SwiftBitmapDefinition *bitmap in needsTables) {
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
        SwiftScene *scene = [[SwiftScene alloc] initWithMovie:self name:nil indexInMovie:0 frames:m_frames];
        m_scenes = [[NSArray alloc] initWithObjects:scene, nil];
        [scene release];
    }
    
    SwiftParserFree(parser);
}


- (void) _parser:(SwiftParser *)parser didFindTag:(SwiftTag)tag version:(NSInteger)version
{
    if (tag == SwiftTagDefineShape) {
        SwiftShapeDefinition *shape = [[SwiftShapeDefinition alloc] initWithParser:parser movie:self];

        if (shape) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[shape libraryID]];
            [m_definitionMap setObject:shape forKey:key];
            [key release];
        }

        [shape release];

    } else if (tag == SwiftTagDefineButton) {
        //!nyi: Button Support.
    
    } else if (tag == SwiftTagDefineMorphShape) {
        //!nyi: MorphShape Support

    } else if (tag == SwiftTagJPEGTables) {
        UInt32 remaining = SwiftParserGetBytesRemainingInCurrentTag(parser);

        if (!SwiftParserGetAssociatedValue(parser, SwiftMovieJPEGTablesDataKey)) {
            NSData *data = nil;
            SwiftParserReadData(parser, remaining, &data);
            SwiftParserSetAssociatedValue(parser, SwiftMovieJPEGTablesDataKey, data);
        }

    } else if (tag == SwiftTagDefineBits || tag == SwiftTagDefineBitsLossless) {
        SwiftBitmapDefinition *bitmap = [[SwiftBitmapDefinition alloc] initWithParser:parser movie:self];

        if (bitmap) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[bitmap libraryID]];
            [m_definitionMap setObject:bitmap forKey:key];
            [key release];
        }

        if (tag == SwiftTagDefineBits) {
            NSMutableArray *needsTables = SwiftParserGetAssociatedValue(parser, SwiftMovieNeedsJPEGTablesDataKey);

            if (!needsTables) {
                needsTables = [[NSMutableArray alloc] init];
                SwiftParserSetAssociatedValue(parser, SwiftMovieNeedsJPEGTablesDataKey, needsTables);
                [needsTables release];
            }
            
            [needsTables addObject:bitmap];
        }

        [bitmap release];

    } else if (tag == SwiftTagDefineVideoStream) {
        //!nyi: Video Support

    } else if (tag == SwiftTagDefineSound) {
        SwiftSoundDefinition *sound = [[SwiftSoundDefinition alloc] initWithParser:parser movie:self];

        if (sound) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[sound libraryID]];
            [m_definitionMap setObject:sound forKey:key];
            [key release];
        }

        [sound release];

    } else if (tag == SwiftTagDefineSprite) {
        SwiftSpriteDefinition *sprite = [[SwiftSpriteDefinition alloc] initWithParser:parser movie:self];

        if (sprite) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[sprite libraryID]];
            [m_definitionMap setObject:sprite forKey:key];
            [key release];
        }
        
        [sprite release];

    } else if ((tag == SwiftTagDefineFont)     ||
               (tag == SwiftTagDefineFontInfo) ||
               (tag == SwiftTagDefineFontName) ||
               (tag == SwiftTagDefineFontAlignZones))
    {
        UInt16 fontID;
        SwiftParserReadUInt16(parser, &fontID);

        NSNumber  *key  = [[NSNumber alloc] initWithInteger:(NSInteger)fontID];
        SwiftFontDefinition *font = [m_definitionMap objectForKey:key];
        
        if (![font isKindOfClass:[SwiftFontDefinition class]]) {
            font = [[SwiftFontDefinition alloc] initWithLibraryID:fontID movie:self];
            [m_definitionMap setObject:font forKey:key];
            [font release];
        }
        
        if (tag == SwiftTagDefineFont) {
            [font readDefineFontTagFromParser:parser];
        } else if (tag == SwiftTagDefineFontInfo) {
            [font readDefineFontInfoTagFromParser:parser];
        } else if (tag == SwiftTagDefineFontName) {
            [font readDefineFontNameTagFromParser:parser];
        } else if (tag == SwiftTagDefineFontAlignZones) {
            [font readDefineFontAlignZonesFromParser:parser];
        }

        [key release];
    
    } else if (tag == SwiftTagDefineText) {
        SwiftStaticTextDefinition *text = [[SwiftStaticTextDefinition alloc] initWithParser:parser movie:self];
        
        if (text) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[text libraryID]];
            [m_definitionMap setObject:text forKey:key];
            [key release];
        }
        
        [text release];
    
    } else if (tag == SwiftTagDefineEditText) {
        SwiftDynamicTextDefinition *text = [[SwiftDynamicTextDefinition alloc] initWithParser:parser movie:self];
        
        if (text) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[text libraryID]];
            [m_definitionMap setObject:text forKey:key];
            [key release];
        }
        
        [text release];

    } else if (tag == SwiftTagSetBackgroundColor) {
        SwiftParserReadColorRGB(parser, &m_backgroundColor);

    } else {
        [super _parser:parser didFindTag:tag version:version];
    }
}


#pragma mark -
#pragma mark Public Methods

- (id<SwiftDefinition>) definitionWithLibraryID:(UInt16)libraryID
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:libraryID];
    id definition = [m_definitionMap objectForKey:number];
    [number release];
    
    return definition;
}


- (id) _definitionWithLibraryID:(UInt16)libraryID ofClass:(Class)cls
{
    id<SwiftDefinition> definition = [self definitionWithLibraryID:libraryID];
    return [definition isKindOfClass:cls] ? definition : nil;
}

- (SwiftBitmapDefinition *) bitmapDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftBitmapDefinition class]]; }

- (SwiftDynamicTextDefinition *) dynamicTextDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftDynamicTextDefinition class]]; }

- (SwiftFontDefinition *) fontDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftFontDefinition class]]; }

- (SwiftSpriteDefinition *) spriteDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftSpriteDefinition class]]; }

- (SwiftShapeDefinition *) shapeDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftShapeDefinition class]]; }

- (SwiftSoundDefinition *) soundDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftSoundDefinition class]]; }

- (SwiftStaticTextDefinition *) staticTextDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftStaticTextDefinition class]]; }


- (SwiftScene *) sceneWithName:(NSString *)name
{
    if (!m_sceneNameToSceneMap) {
        NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:[m_scenes count]];
        
        for (SwiftScene *scene in m_scenes) {
            [map setObject:scene forKey:[scene name]];
        }
    
        m_sceneNameToSceneMap = map;
    }

    return [m_sceneNameToSceneMap objectForKey:name];
}


#pragma mark -
#pragma mark Accessors

- (SwiftColor *) backgroundColorPointer
{
    return &m_backgroundColor;
}

@synthesize scenes          = m_scenes,
            version         = m_version,
            frameRate       = m_frameRate,
            stageRect       = m_stageRect,
            backgroundColor = m_backgroundColor;

@end
