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

#import "SwiftShape.h"
#import "SwiftSprite.h"
#import "SwiftFont.h"
#import "SwiftStaticText.h"
#import "SwiftDynamicText.h"
#import "SwiftParser.h"
#import "SwiftSceneAndFrameLabelData.h"
#import "SwiftScene.h"


@interface SwiftSprite (Protected)
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
        
        m_objects      = [[NSMutableDictionary alloc] init];
        m_shapes       = [[NSMutableDictionary alloc] init];
        m_sprites      = [[NSMutableDictionary alloc] init];
        m_fonts        = [[NSMutableDictionary alloc] init];
        m_dynamicTexts = [[NSMutableDictionary alloc] init];
        m_staticTexts  = [[NSMutableDictionary alloc] init];
        
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

    [m_objects             release];  m_objects             = nil;
    [m_shapes              release];  m_shapes              = nil;
    [m_sprites             release];  m_sprites             = nil;
    [m_fonts               release];  m_fonts               = nil;
    [m_dynamicTexts        release];  m_dynamicTexts        = nil;
    [m_staticTexts         release];  m_staticTexts         = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods

- (void) _parser:(SwiftParser *)parser didFindTag:(SwiftTag)tag version:(NSInteger)version
{
    if (tag == SwiftTagDefineShape) {
        SwiftShape *shape = [[SwiftShape alloc] initWithParser:parser tag:tag version:version];

        if (shape) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[shape libraryID]];
            [m_shapes  setObject:shape forKey:key];
            [m_objects setObject:shape forKey:key];
            [key release];
        }

        [shape release];

    } else if (tag == SwiftTagDefineMorphShape) {
        NSLog(@"Found morph shape!");

    } else if (tag == SwiftTagDefineSprite) {
        SwiftSprite *sprite = [[SwiftSprite alloc] initWithParser:parser tag:tag version:version];

        if (sprite) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[sprite libraryID]];
            [m_sprites setObject:sprite forKey:key];
            [m_objects setObject:sprite forKey:key];
            [key release];
        }
        
        [sprite release];

    } else if ((tag == SwiftTagDefineFont) || (tag == SwiftTagDefineFontInfo) || (tag == SwiftTagDefineFontName)) {
        UInt16 fontID;
        SwiftParserReadUInt16(parser, &fontID);

        NSNumber  *key  = [[NSNumber alloc] initWithInteger:(NSInteger)fontID];
        SwiftFont *font = [m_fonts objectForKey:key];
        
        if (!font) {
            font = [[SwiftFont alloc] initWithLibraryID:fontID];
            [m_fonts setObject:font forKey:key];
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
        SwiftStaticText *text = [[SwiftStaticText alloc] initWithParser:parser tag:tag version:version];
        
        if (text) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[text libraryID]];
            [m_staticTexts setObject:text forKey:key];
            [m_objects setObject:text forKey:key];
            [key release];
        }
        
        [text release];
    
    } else if (tag == SwiftTagDefineEditText) {
        SwiftDynamicText *text = [[SwiftDynamicText alloc] initWithParser:parser tag:tag version:version];
        
        if (text) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:[text libraryID]];
            [m_dynamicTexts setObject:text forKey:key];
            [m_objects setObject:text forKey:key];
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

- (id) objectWithID:(NSInteger)objectID
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:objectID];
    id object = [m_objects objectForKey:number];
    [number release];
    
    return object;
}


- (SwiftSprite *) spriteWithID:(NSInteger)spriteID
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:spriteID];
    SwiftSprite *sprite = [m_sprites objectForKey:number];
    [number release];
    
    return sprite;
}


- (SwiftShape *) shapeWithID:(NSInteger)shapeID
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:shapeID];
    SwiftShape *shape  = [m_shapes objectForKey:number];
    [number release];
    
    return shape;
}


- (SwiftFont *) fontWithID:(NSInteger)fontID
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:fontID];
    SwiftFont *font  = [m_shapes objectForKey:number];
    [number release];
    
    return font;
}


- (SwiftStaticText *) staticTextWithID:(NSInteger)textID
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:textID];
    SwiftStaticText *text = [m_staticTexts objectForKey:number];
    [number release];

    return text;
}


- (SwiftDynamicText *) dynamicTextWithID:(NSInteger)textID;
{
    NSNumber *number = [[NSNumber alloc] initWithInteger:textID];
    SwiftDynamicText *text = [m_dynamicTexts objectForKey:number];
    [number release];

    return text;
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
