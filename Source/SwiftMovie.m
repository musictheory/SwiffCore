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

#import "SwiftParser.h"

#import "SwiftShapeDefinition.h"
#import "SwiftSpriteDefinition.h"
#import "SwiftFontDefinition.h"
#import "SwiftStaticTextDefinition.h"
#import "SwiftSoundDefinition.h"
#import "SwiftTextDefinition.h"

#import "SwiftSceneAndFrameLabelData.h"
#import "SwiftScene.h"


@interface SwiftSpriteDefinition (Protected)
- (void) _parser:(SwiftParser *)parser didFindTag:(SwiftTag)tag version:(NSInteger)version;
@end


@implementation SwiftMovie

- (id) initWithData:(NSData *)data
{
    if ((self = [self init])) {
        m_data = [data retain];
        m_definitionMap = [[NSMutableDictionary alloc] init];

        SwiftColor white = { 1.0, 1.0, 1.0, 1.0 };
        m_backgroundColor = white;
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
        // Not yet implemented: Button Support.
    
    } else if (tag == SwiftTagDefineMorphShape) {
        // Not yet implemented: MorphShape Support

    } else if (tag == SwiftTagDefineBits || tag == SwiftTagDefineBitsLossless) {
        // Not yet implemented: Bitmap Image Support

    } else if (tag == SwiftTagDefineSound) {
        SwiftSoundDefinition *sound = [[SwiftSoundDefinition alloc] initWithParser:parser movie:self];

        if (sound) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[sound libraryID]];
            [m_definitionMap setObject:sound forKey:key];
            [key release];
        }

        [sound release];

    } else if (tag == SwiftTagDefineVideoStream) {
        // Not yet implemented: Video Support

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
        SwiftTextDefinition *text = [[SwiftTextDefinition alloc] initWithParser:parser movie:self];
        
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

- (void) decode:(id<SwiftMovieDecoder>)decoder
{
    if (!m_data) return;
    
    m_decoder = decoder;
    m_decoder_movie_didDecodeFrame = [m_decoder respondsToSelector:@selector(movie:didDecodeFrame:)];

    char bytes[4];
    [m_data getBytes:bytes length:4];
    
    SwiftParser *parser = SwiftParserCreate([m_data bytes], [m_data length]);
    
    SwiftHeader header;
    SwiftParserReadHeader(parser, &header);
    
    m_version   = header.version;
    m_stageRect = header.stageRect;
    m_frameRate = header.frameRate;

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

    if (m_sceneAndFrameLabelData) {
        [m_sceneAndFrameLabelData applyLabelsToFrames:m_frames];
        m_scenes = [[m_sceneAndFrameLabelData scenesForFrames:m_frames] retain];
        
        [m_sceneAndFrameLabelData release];
        m_sceneAndFrameLabelData = nil;

    } else {
        SwiftScene *scene = [[SwiftScene alloc] initWithName:nil indexInMovie:0 frames:m_frames];
        m_scenes = [[NSArray alloc] initWithObjects:scene, nil];
        [scene release];
    }
    
    [m_data release];
    m_data = nil;

    SwiftParserFree(parser);
    
    m_decoder = nil;
    m_decoder_movie_didDecodeFrame = NO;
}


- (id) definitionWithLibraryID:(UInt16)libraryID
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


- (SwiftSpriteDefinition *) spriteDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftSpriteDefinition class]]; }

- (SwiftShapeDefinition *) shapeDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftShapeDefinition class]]; }

- (SwiftFontDefinition *) fontDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftFontDefinition class]]; }

- (SwiftSoundDefinition *) soundDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftSoundDefinition class]]; }

- (SwiftStaticTextDefinition *) staticTextDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftStaticTextDefinition class]]; }

- (SwiftTextDefinition *) textDefinitionWithLibraryID:(UInt16)libraryID
    { return [self _definitionWithLibraryID:libraryID ofClass:[SwiftTextDefinition class]]; }


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
