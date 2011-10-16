//
//  SWFFrame.m
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftFrame.h"
#import "SwiftPlacedObject.h"

@implementation SwiftFrame

- (id) _initWithSortedPlacedObjects:(NSArray *)placedObjects
{
    if ((self = [super init])) {
        m_placedObjects = [placedObjects retain];
    }
    
    return self;
}


- (void) dealloc
{
    [m_label                  release];  m_label                  = nil;
    [m_placedObjects          release];  m_placedObjects          = nil;

    [super dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
    SwiftFrame *newFrame = (SwiftFrame *)NSCopyObject(self, 0, zone);

    newFrame->m_placedObjects = [m_placedObjects retain];
    newFrame->m_label = [m_label copy];
    
    return newFrame;
}


- (SwiftColor *) backgroundColorPointer
{
    return &m_backgroundColor;
}


@synthesize indexInScene    = m_indexInScene,
            placedObjects   = m_placedObjects,
            parentSprite    = m_parentSprite,
            parentScene     = m_parentScene,
            nextFrame       = m_nextFrame,
            label           = m_label,
            backgroundColor = m_backgroundColor;

@end
