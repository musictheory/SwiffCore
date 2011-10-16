/*
    SwiftScene.m
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
