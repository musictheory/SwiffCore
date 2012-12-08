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


@implementation SwiffScene {
    NSDictionary *_labelToFrameMap;
}

@synthesize movie        = _movie,
            name         = _name,
            frames       = _frames,
            indexInMovie = _indexInMovie;


- (id) initWithMovie:(SwiffMovie *)movie name:(NSString *)name indexInMovie:(NSUInteger)indexInMovie frames:(NSArray *)frames
{
    if ((self = [super init])) {
        _movie        = movie;
        _name         = name;
        _frames       = frames;
        _indexInMovie = indexInMovie;
        
        NSInteger i = 0;
        for (SwiffFrame *frame in frames) {
            [frame _updateScene:self indexInScene:i++];
        }
    }
    
    return self;
}


- (void) dealloc
{
    [_frames makeObjectsPerformSelector:@selector(clearWeakReferences) withObject:nil];
}


- (void) clearWeakReferences
{
    _movie = nil;
}


- (NSString *) description
{
    NSString *nameString = _name ? [NSString stringWithFormat:@"name='%@', ", _name] : @"";
    return [NSString stringWithFormat:@"<%@: %p; %@%lu frames>", [self class], self, nameString, (unsigned long) [_frames count]];
}


- (SwiffFrame *) frameWithLabel:(NSString *)label
{
    if (!_labelToFrameMap) {
        NSMutableDictionary *map = [[NSMutableDictionary alloc] init];

        for (SwiffFrame *frame in _frames) {
            NSString *frameLabel = [frame label];
            if (frameLabel) [map setObject:frame forKey:frameLabel];
        }
        
        _labelToFrameMap = map;
    }

    return [_labelToFrameMap objectForKey:label];
}


- (SwiffFrame *) firstFrame
{
    return [self frameAtIndex:0];
}


- (SwiffFrame *) frameAtIndex1:(NSUInteger)index1
{
    if (index1 > 0 && index1 <= [_frames count]) {
        return [_frames objectAtIndex:(index1 - 1)];
    }
    
    return nil;
}


- (NSUInteger) index1OfFrame:(SwiffFrame *)frame
{
    NSUInteger index = [_frames indexOfObject:frame];
    return index == NSNotFound ? NSNotFound : (index + 1);
}


- (SwiffFrame *) frameAtIndex:(NSUInteger)index
{
    if (index < [_frames count]) {
        return [_frames objectAtIndex:index];
    }
    
    return nil;
}


- (NSUInteger) indexOfFrame:(SwiffFrame *)frame
{
    return [_frames indexOfObject:frame];
}


- (NSUInteger) index1InMovie
{
    return _indexInMovie + 1;
}


@end
