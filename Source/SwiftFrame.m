/*
    SwiftFrame.m
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


#import "SwiftFrame.h"
#import "SwiftPlacedObject.h"
#import "SwiftScene.h"


@interface SwiftFrame (FriendMethods)
- (void) _updateLabel:(NSString *)label;
- (void) _updateScene:(SwiftScene *)scene indexInScene:(NSUInteger)index1InScene;
@end

@implementation SwiftFrame

- (id) _initWithSortedPlacedObjects: (NSArray *) placedObjects
                        soundEvents: (NSArray *) soundEvents
                        streamSound: (SwiftSoundDefinition *) streamSound
                   streamBlockIndex: (NSUInteger) streamBlockIndex
{
    if ((self = [super init])) {
        m_placedObjects = [placedObjects retain];
        m_soundEvents   = [soundEvents   retain];
        m_streamSound   = [streamSound   retain];

        NSMutableDictionary *instanceNameToPlacedObjectMap = [[NSMutableDictionary alloc] initWithCapacity:[placedObjects count]];
        for (SwiftPlacedObject *placedObject in placedObjects) {
            NSString *instanceName = [placedObject instanceName];

            if ([instanceName length]) {
                [instanceNameToPlacedObjectMap setObject:placedObjects forKey:instanceName];
            }
        }
        m_instanceNameToPlacedObjectMap = instanceNameToPlacedObjectMap;

        m_streamBlockIndex = streamBlockIndex;
    }
    
    return self;
}


- (void) clearWeakReferences
{
    m_scene = nil;
}


- (void) dealloc
{
    [m_label         release];  m_label         = nil;
    [m_placedObjects release];  m_placedObjects = nil;
    [m_streamSound   release];  m_streamSound   = nil;
    [m_soundEvents   release];  m_soundEvents   = nil;

    [m_instanceNameToPlacedObjectMap release];
    m_instanceNameToPlacedObjectMap = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Friend Methods

- (void) _updateScene:(SwiftScene *)scene indexInScene:(NSUInteger)indexInScene
{
    m_scene = scene;
    m_indexInScene = indexInScene;
}


- (void) _updateLabel:(NSString *)label 
{
    [m_label release];
    m_label = [label copy];
}


#pragma mark -
#pragma mark Public Methods

- (NSArray *) instanceNames
{
    return [m_instanceNameToPlacedObjectMap allKeys];
}


- (SwiftPlacedObject *) placedObjectWithInstanceName:(NSString *)name
{
    return [m_instanceNameToPlacedObjectMap objectForKey:name];
}


#pragma mark -
#pragma mark Accessors

- (NSUInteger) index1InScene
{
    return m_indexInScene + 1;
}


- (NSUInteger) index1InMovie
{
    return [m_scene index1InMovie] + m_indexInScene;
}


- (NSUInteger) indexInMovie
{
    return [m_scene indexInMovie] + m_indexInScene;
}


@synthesize indexInScene     = m_indexInScene,
            placedObjects    = m_placedObjects,
            scene            = m_scene,
            label            = m_label,
            streamSound      = m_streamSound,
            soundEvents      = m_soundEvents,
            streamBlockIndex = m_streamBlockIndex;

@end
