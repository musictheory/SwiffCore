//
//  SwiftScene.m
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftScene.h"

@implementation SwiftScene

- (id) initWithName:(NSString *)name frames:(NSArray *)frames
{
    if ((self = [super init])) {
        m_name = [name retain];

        m_frames = [frames retain];
        
        NSInteger i = 0;
        for (SwiftFrame *frame in frames) {
            [frame setParentScene:self];
            [frame setIndexInScene:i++];
        }
    }
    
    return self;
}


- (void) dealloc
{
    [m_frames makeObjectsPerformSelector:@selector(setParentScene:) withObject:nil];

    [m_name            release];  m_name            = nil;
    [m_frames          release];  m_frames          = nil;
    [m_labelToFrameMap release];  m_labelToFrameMap = nil;
    
    [super dealloc];
}


- (NSString *) description
{
    NSString *nameString = m_name ? [NSString stringWithFormat:@"name='%@', ", m_name] : @"";
    return [NSString stringWithFormat:@"<%@: %p; %@%d frames>", [self class], self, nameString, [m_frames count]];
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


@synthesize name   = m_name,
            frames = m_frames;

@end
