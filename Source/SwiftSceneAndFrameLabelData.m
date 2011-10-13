//
//  SwiftSceneAndFrameLabelData.m
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-12.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftSceneAndFrameLabelData.h"
#import "SwiftScene.h"

@implementation SwiftSceneAndFrameLabelData

- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)version
{
    if ((self = [super init])) {
        @autoreleasepool {
            UInt32 sceneCount;
            SwiftParserReadEncodedU32(parser, &sceneCount);

            // Read scene names and offsets
            if (sceneCount) {
                NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:sceneCount];
                m_offsetToSceneNameMap = map;

                for (UInt32 i = 0; i < sceneCount; i++) {
                    UInt32 frameOffset = 0;
                    SwiftParserReadEncodedU32(parser, &frameOffset);
                    
                    NSString *name = nil;
                    SwiftParserReadString(parser, &name);
                    
                    if (name) {
                        [map setObject:name forKey:[NSNumber numberWithUnsignedInt:frameOffset]];
                    }
                }
            }

            UInt32 labelCount;
            SwiftParserReadEncodedU32(parser, &labelCount);

            // Read frame labels
            if (labelCount) {
                NSMutableDictionary *map = [[NSMutableDictionary alloc] initWithCapacity:labelCount];
                m_numberToFrameLabelMap = map;

                for (UInt32 i = 0; i < labelCount; i++) {
                    UInt32 frameNumber;
                    SwiftParserReadEncodedU32(parser, &frameNumber);

                    NSString *label = nil;
                    SwiftParserReadString(parser, &label);

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


- (NSArray *) scenesForFrames:(NSArray *)frames
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[m_offsetToSceneNameMap count]];
    NSArray        *keys   = [[m_offsetToSceneNameMap allKeys] sortedArrayUsingSelector:@selector(compare:)];

    NSString *lastName   = nil;
    UInt32    lastOffset = 0;

    void (^addScene)(UInt32, UInt32, NSString *) = ^(UInt32 startOffset, UInt32 endOffset, NSString *name) {
        NSRange     range       = NSMakeRange(startOffset, endOffset - startOffset);
        NSArray    *sceneFrames = [frames subarrayWithRange:range];

        SwiftScene *scene = [[SwiftScene alloc] initWithName:name frames:sceneFrames];
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
            [[frames objectAtIndex:frameNumber] setLabel:[m_offsetToSceneNameMap objectForKey:key]];
        }
    }
}


@end
