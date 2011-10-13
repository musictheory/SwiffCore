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

- (id) init
{
    if ((self = [super init])) {
        m_depthToPlacedObjectMap = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}


- (void) dealloc
{
    [m_depthToPlacedObjectMap release];  m_depthToPlacedObjectMap = nil;
    [m_label                  release];  m_label                  = nil;
    [m_placedObjects          release];  m_placedObjects          = nil;

    [super dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
    SwiftFrame *newFrame = (SwiftFrame *)NSCopyObject(self, 0, zone);

    newFrame->m_depthToPlacedObjectMap = [m_depthToPlacedObjectMap mutableCopy];
    newFrame->m_placedObjects = nil;
    newFrame->m_label = [m_label copy];
    
    return newFrame;
}


- (void) setPlacedObject:(SwiftPlacedObject *)object atDepth:(NSInteger)i
{
    NSNumber *depth = [[NSNumber alloc] initWithInteger:i];
    [m_depthToPlacedObjectMap setObject:object forKey:depth];
    [depth release];

    [m_placedObjects release];
    m_placedObjects = nil;
}


- (void) removePlacedObjectAtDepth:(NSInteger)i
{
    NSNumber *depth = [[NSNumber alloc] initWithInteger:i];
    [m_depthToPlacedObjectMap removeObjectForKey:depth];
    [depth release];

    [m_placedObjects release];
    m_placedObjects = nil;
}


- (SwiftPlacedObject *) placedObjectAtDepth:(NSInteger)i
{
    NSNumber *depth = [[NSNumber alloc] initWithInteger:i];
    SwiftPlacedObject *po = [m_depthToPlacedObjectMap objectForKey:depth];
    [depth release];
    
    return po;
}


- (NSArray *) placedObjects
{
    if (!m_placedObjects) {
        m_placedObjects = [[[m_depthToPlacedObjectMap allValues] sortedArrayUsingComparator: ^NSComparisonResult(id a, id b) {
            return [(SwiftPlacedObject *)a depth] - [(SwiftPlacedObject *)b depth];
        }] retain];
    }

    return m_placedObjects;
}


- (SwiftColor *) backgroundColorPointer
{
    return &m_backgroundColor;
}


@synthesize indexInScene    = m_indexInScene,
            parentSprite    = m_parentSprite,
            parentScene     = m_parentScene,
            nextFrame       = m_nextFrame,
            label           = m_label,
            backgroundColor = m_backgroundColor;

@end
