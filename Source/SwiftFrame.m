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

@interface SwiftFrame (FriendMethods)
- (void) _updateLabel:(NSString *)label;
- (void) _updateScene:(SwiftScene *)scene index1InScene:(NSUInteger)index1InScene;
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

    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods


- (void) _updateScene:(SwiftScene *)scene index1InScene:(NSUInteger)index1InScene
{
    m_scene = scene;
    m_index1InScene = index1InScene;
}


- (void) _updateLabel:(NSString *)label 
{
    [m_label release];
    m_label = [label copy];
}


#pragma mark -
#pragma mark Accessors

@synthesize index1InScene    = m_index1InScene,
            placedObjects    = m_placedObjects,
            scene            = m_scene,
            label            = m_label,
            streamSound      = m_streamSound,
            soundEvents      = m_soundEvents,
            streamBlockIndex = m_streamBlockIndex;

@end
