/*
    SwiffScene.m
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


#import "SwiffScene.h"
#import "SwiffFrame.h"
#import "SwiffMovie.h"


@interface SwiffFrame (FriendMethods)
- (void) _updateScene:(SwiffScene *)scene indexInScene:(NSUInteger)index1InScene;
@end

@implementation SwiffScene

- (id) initWithMovie:(SwiffMovie *)movie name:(NSString *)name indexInMovie:(NSUInteger)indexInMovie frames:(NSArray *)frames
{
    if ((self = [super init])) {
        m_movie        = movie;
        m_name         = name;
        m_frames       = frames;
        m_indexInMovie = indexInMovie;
        
        NSInteger i = 0;
        for (SwiffFrame *frame in frames) {
            [frame _updateScene:self indexInScene:i++];
        }
    }
    
    return self;
}


- (void) dealloc
{
    [m_frames makeObjectsPerformSelector:@selector(clearWeakReferences) withObject:nil];
}


- (void) clearWeakReferences
{
    m_movie = nil;
}


- (NSString *) description
{
    NSString *nameString = m_name ? [NSString stringWithFormat:@"name='%@', ", m_name] : @"";
    return [NSString stringWithFormat:@"<%@: %p; %@%d frames>", [self class], self, nameString, [m_frames count]];
}


- (SwiffFrame *) frameWithLabel:(NSString *)label
{
    if (!m_labelToFrameMap) {
        NSMutableDictionary *map = [[NSMutableDictionary alloc] init];

        for (SwiffFrame *frame in m_frames) {
            NSString *frameLabel = [frame label];
            if (frameLabel) [map setObject:frame forKey:frameLabel];
        }
        
        m_labelToFrameMap = map;
    }

    return [m_labelToFrameMap objectForKey:label];
}


- (SwiffFrame *) firstFrame
{
    return [self frameAtIndex:0];
}


- (SwiffFrame *) frameAtIndex1:(NSUInteger)index1
{
    if (index1 > 0 && index1 <= [m_frames count]) {
        return [m_frames objectAtIndex:(index1 - 1)];
    }
    
    return nil;
}


- (NSUInteger) index1OfFrame:(SwiffFrame *)frame
{
    NSUInteger index = [m_frames indexOfObject:frame];
    return index == NSNotFound ? NSNotFound : (index + 1);
}


- (SwiffFrame *) frameAtIndex:(NSUInteger)index
{
    if (index < [m_frames count]) {
        return [m_frames objectAtIndex:index];
    }
    
    return nil;
}


- (NSUInteger) indexOfFrame:(SwiffFrame *)frame
{
    return [m_frames indexOfObject:frame];
}


- (NSUInteger) index1InMovie
{
    return m_indexInMovie + 1;
}


@synthesize movie        = m_movie,
            name         = m_name,
            frames       = m_frames,
            indexInMovie = m_indexInMovie;

@end
