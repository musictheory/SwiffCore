/*
    SwiffSceneAndFrameLabelData.m
    Copyright (c) 2011-2012, musictheory.net, LLC.  All rights reserved.

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

#import "SwiffSceneAndFrameLabelData.h"

#import "SwiffScene.h"
#import "SwiffFrame.h"


@interface SwiffFrame (FriendMethods)
- (void) _updateLabel:(NSString *)label;
@end


@implementation SwiffSceneAndFrameLabelData

- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie
{
    if ((self = [super init])) {
        m_movie = movie;
    
        @autoreleasepool {
            UInt32 sceneCount;
            SwiffParserReadEncodedU32(parser, &sceneCount);

            // Read scene names and offsets
            if (sceneCount) {
                NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:sceneCount];
                m_offsetToSceneNameMap = map;

                for (UInt32 i = 0; i < sceneCount; i++) {
                    UInt32 frameOffset = 0;
                    SwiffParserReadEncodedU32(parser, &frameOffset);
                    
                    NSString *name = nil;
                    SwiffParserReadString(parser, &name);
                    
                    if (name) {
                        [map setObject:name forKey:[NSNumber numberWithUnsignedInt:frameOffset]];
                    }
                }
            }

            UInt32 labelCount;
            SwiffParserReadEncodedU32(parser, &labelCount);

            // Read frame labels
            if (labelCount) {
                NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:labelCount];
                m_numberToFrameLabelMap = map;

                for (UInt32 i = 0; i < labelCount; i++) {
                    UInt32 frameNumber;
                    SwiffParserReadEncodedU32(parser, &frameNumber);

                    NSString *label = nil;
                    SwiffParserReadString(parser, &label);

                    if (label) {
                        [map setObject:label forKey:[NSNumber numberWithUnsignedInt:frameNumber]];
                    }
                }
            }
        }
    }
    
    return self;
}


- (void) dealloc
{
    [m_offsetToSceneNameMap  release];  m_offsetToSceneNameMap  = nil;
    [m_numberToFrameLabelMap release];  m_numberToFrameLabelMap = nil;

    [super dealloc];
}


- (void) clearWeakReferences
{
    m_movie = nil;
}


- (NSArray *) scenesForFrames:(NSArray *)frames
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[m_offsetToSceneNameMap count]];
    NSArray        *keys   = [[m_offsetToSceneNameMap allKeys] sortedArrayUsingSelector:@selector(compare:)];

    NSString *lastName   = nil;
    UInt32    lastOffset = 0;

    void (^addScene)(UInt32, UInt32, NSString *) = ^(UInt32 startOffset, UInt32 endOffset, NSString *name) {
        NSRange     range       = NSMakeRange(startOffset, endOffset - startOffset);
        NSArray    *sceneFrames = [frames subarrayWithRange:range];

        SwiffScene *scene = [[SwiffScene alloc] initWithMovie:m_movie name:name indexInMovie:startOffset frames:sceneFrames];
        [result addObject:scene];
        [scene release];
    };

    for (NSNumber *key in keys) {
        UInt32 offset = [key unsignedIntValue];

        if (lastName) addScene(lastOffset, offset, lastName);

        lastName   = [m_offsetToSceneNameMap objectForKey:key];
        lastOffset = offset;
    }

    addScene(lastOffset, [frames count], lastName);
    
    return result;
}


- (void) applyLabelsToFrames:(NSArray *)frames
{
    NSUInteger count = [frames count];

    for (NSNumber *key in m_offsetToSceneNameMap) {
        UInt32 frameNumber = [key unsignedIntValue];
        
        if (frameNumber < count) {
            [[frames objectAtIndex:frameNumber] _updateLabel:[m_offsetToSceneNameMap objectForKey:key]];
        }
    }
}


@end
