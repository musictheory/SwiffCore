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
#import "SwiftTextDefinition.h"

#import "SwiftSceneAndFrameLabelData.h"
#import "SwiftScene.h"


@interface SwiftSpriteDefinition (Protected)
- (void) _parser:(SwiftParser *)parser didFindTag:(SwiftTag)tag version:(NSInteger)version;
@end


@implementation SwiftMovie

- (id) initWithData:(NSData *)data
{
    return [self initWithData:data parserOptions:SwiftParserOptionsDefault];
}


- (id) initWithData:(NSData *)data parserOptions:(SwiftParserOptions)parserOptions
{
    if ((self = [super init])) {
        m_data = [data retain];
        
        m_definitionMap = [[NSMutableDictionary alloc] init];
        
        SwiftColor white = { 1.0, 1.0, 1.0, 1.0 };
        m_backgroundColor = white;

        clock_t c = clock();
        SwiftParser *parser = SwiftParserCreate([data bytes], [data length], parserOptions);
        if (parser) {
            CGRect rect;
            SwiftParserReadRect(parser, &rect);
            
            m_version     = SwiftParserGetMovieVersion(parser);
            m_stageOrigin = rect.origin;
            m_stageSize   = rect.size;
            
            SwiftParserReadFixed8(parser, &m_frameRate);

            UInt16 frameCount;
            SwiftParserReadUInt16(parser, &frameCount);

            while (SwiftParserIsValid(parser) && SwiftParserAdvanceToNextTag(parser)) {
                [self _parser: parser
                   didFindTag: SwiftParserGetCurrentTag(parser)
                      version: SwiftParserGetCurrentTagVersion(parser)];
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

            SwiftParserFree(parser);
        }

        NSInteger valueToLog = (((clock() - c) * 1000) / CLOCKS_PER_SEC);
        SwiftLog(@"Parsing <SwiftMovie: %p> took: %dms", self, valueToLog);
    }
    
    return self;
}


- (void) dealloc
{
    [m_data                release];  m_data                = nil;
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
        SwiftShapeDefinition *shape = [[SwiftShapeDefinition alloc] initWithParser:parser tag:tag version:version];

        if (shape) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[shape libraryID]];
            [m_definitionMap setObject:shape forKey:key];
            [key release];
        }

        [shape release];

    } else if (tag == SwiftTagDefineMorphShape) {
        NSLog(@"Found morph shape!");

    } else if (tag == SwiftTagDefineSprite) {
        SwiftSpriteDefinition *sprite = [[SwiftSpriteDefinition alloc] initWithParser:parser tag:tag version:version];

        if (sprite) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[sprite libraryID]];
            [m_definitionMap setObject:sprite forKey:key];
            [key release];
        }
        
        [sprite release];

    } else if ((tag == SwiftTagDefineFont) || (tag == SwiftTagDefineFontInfo) || (tag == SwiftTagDefineFontName)) {
        UInt16 fontID;
        SwiftParserReadUInt16(parser, &fontID);

        NSNumber  *key  = [[NSNumber alloc] initWithInteger:(NSInteger)fontID];
        SwiftFontDefinition *font = [m_definitionMap objectForKey:key];
        
        if (![font isKindOfClass:[SwiftFontDefinition class]]) {
            font = [[SwiftFontDefinition alloc] initWithLibraryID:fontID];
            [m_definitionMap setObject:font forKey:key];
            [font release];
        }
        
        if (tag == SwiftTagDefineFont) {
            [font readDefineFontTagFromParser:parser version:version];
        } else if (tag == SwiftTagDefineFontInfo) {
            [font readDefineFontInfoTagFromParser:parser version:version];
        } else if (tag == SwiftTagDefineFontName) {
            [font readDefineFontNameTagFromParser:parser version:version];
        }

        [key release];
    
    } else if (tag == SwiftTagDefineText) {
        SwiftStaticTextDefinition *text = [[SwiftStaticTextDefinition alloc] initWithParser:parser tag:tag version:version];
        
        if (text) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[text libraryID]];
            [m_definitionMap setObject:text forKey:key];
            [key release];
        }
        
        [text release];
    
    } else if (tag == SwiftTagDefineEditText) {
        SwiftTextDefinition *text = [[SwiftTextDefinition alloc] initWithParser:parser tag:tag version:version];
        
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

- (id) definitionWithLibraryID:(UInt16)libraryID
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:libraryID];
    id definition = [m_definitionMap objectForKey:number];
    [number release];
    
    return definition;
}


- (SwiftSpriteDefinition *) spriteDefinitionWithLibraryID:(UInt16)spriteID
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:spriteID];
    SwiftSpriteDefinition *definition = [m_definitionMap objectForKey:number];
    [number release];
    
    return [definition isKindOfClass:[SwiftSpriteDefinition class]] ? definition : nil;
}


- (SwiftShapeDefinition *) shapeDefinitionWithLibraryID:(UInt16)shapeID
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:shapeID];
    SwiftShapeDefinition *definition = [m_definitionMap objectForKey:number];
    [number release];
    
    return [definition isKindOfClass:[SwiftShapeDefinition class]] ? definition : nil;
}


- (SwiftFontDefinition *) fontDefinitionWithLibraryID:(UInt16)fontID
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:fontID];
    SwiftFontDefinition *definition  = [m_definitionMap objectForKey:number];
    [number release];
    
    return [definition isKindOfClass:[SwiftFontDefinition class]] ? definition : nil;
}


- (SwiftStaticTextDefinition *) staticTextDefinitionWithLibraryID:(UInt16)textID
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:textID];
    SwiftStaticTextDefinition *definition  = [m_definitionMap objectForKey:number];
    [number release];

    return [definition isKindOfClass:[SwiftStaticTextDefinition class]] ? definition : nil;
}


- (SwiftTextDefinition *) textDefinitionWithLibraryID:(UInt16)textID
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:textID];
    SwiftTextDefinition *definition = [m_definitionMap objectForKey:number];
    [number release];

    return [definition isKindOfClass:[SwiftTextDefinition class]] ? definition : nil;
}


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

@synthesize scenes      = m_scenes,
            version     = m_version,
            frameRate   = m_frameRate,
            stageOrigin = m_stageOrigin,
            stageSize   = m_stageSize;

@end
