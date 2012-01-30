/*
    SwiffFrame.m
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


#import "SwiffFrame.h"
#import "SwiffPlacedObject.h"
#import "SwiffScene.h"
#import "SwiffSoundDefinition.h"
#import "SwiffSoundStreamBlock.h"

@interface SwiffFrame (FriendMethods)
- (void) _updateLabel:(NSString *)label;
- (void) _updateScene:(SwiffScene *)scene indexInScene:(NSUInteger)index1InScene;
@end

@implementation SwiffFrame

- (id) _initWithSortedPlacedObjects: (NSArray *) placedObjects
                          withNames: (NSArray *) placedObjectsWithNames
                        soundEvents: (NSArray *) soundEvents
                        streamSound: (SwiffSoundDefinition *) streamSound
                        streamBlock: (SwiffSoundStreamBlock *) streamBlock
{
    if ((self = [super init])) {
        m_placedObjects = placedObjects;
        m_soundEvents   = soundEvents;
        m_streamSound   = streamSound;
        m_streamBlock   = streamBlock;

        m_placedObjectsWithNames = placedObjectsWithNames;
    }
    
    return self;
}


- (void) clearWeakReferences
{
    m_scene = nil;
}


- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@: %p; %lu>", [self class], self, (long unsigned)[self index1InMovie]];
}


#pragma mark -
#pragma mark Friend Methods

- (void) _updateScene:(SwiffScene *)scene indexInScene:(NSUInteger)indexInScene
{
    m_scene = scene;
    m_indexInScene = indexInScene;
}


- (void) _updateLabel:(NSString *)label 
{
    m_label = [label copy];
}


#pragma mark -
#pragma mark Public Methods

- (SwiffPlacedObject *) placedObjectWithName:(NSString *)name
{
    for (SwiffPlacedObject *object in m_placedObjectsWithNames) {
        if ([[object name] isEqualToString:name]) {
            return object;
        }
    }

    return nil;
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


- (NSArray *) placedObjectsWithNames
{
    return m_placedObjectsWithNames;
}


@synthesize indexInScene  = m_indexInScene,
            placedObjects = m_placedObjects,
            scene         = m_scene,
            label         = m_label,
            soundEvents   = m_soundEvents,
            streamSound   = m_streamSound,
            streamBlock   = m_streamBlock;

@end
