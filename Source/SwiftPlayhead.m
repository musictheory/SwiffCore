/*
    SwiftPlayhead.m
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

#import "SwiftPlayhead.h"

#import "SwiftFrame.h"
#import "SwiftMovie.h"
#import "SwiftScene.h"

#import <QuartzCore/QuartzCore.h>


@interface SwiftPlayhead ()
- (void) _cleanupTimer;
- (void) _tick;
@end


@implementation SwiftPlayhead

- (id) initWithMovie:(SwiftMovie *)movie delegate:(id<SwiftPlayheadDelegate>)delegate
{
    if ((self = [super init])) {
        m_movie = [movie retain];
        m_delegate = delegate;
    }
    
    return self;
}


- (void) dealloc
{
    [self _cleanupTimer];

    [m_movie release];
    m_movie = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark - Private Methods

- (void) _cleanupTimer
{
    [m_timer invalidate];
    [m_timer release];
    m_timer = nil;
}


- (void) _tick
{
    long currentIndex = (long)((CACurrentMediaTime() - m_timerPlayStart) * [m_movie frameRate]);

    if (m_timerPlayIndex != currentIndex) {
        [self step];
        m_timerPlayIndex = currentIndex;
    }
}


#pragma mark -
#pragma mark Public Methods

- (void) gotoSceneName:(NSString *)sceneName frame:(NSUInteger)frameIndex1 play:(BOOL)play
{
    [self setSceneName:sceneName];
    [self setFrameIndex1:frameIndex1];
    [self setPlaying:play];
}


- (void) gotoAndPlay:(NSUInteger)frameIndex1
{
    [self setFrameIndex1:frameIndex1];
    [self setPlaying:YES];
}


- (void) gotoAndStop:(NSUInteger)frameIndex1
{
    [self setFrameIndex1:frameIndex1];
    [self setPlaying:NO];
}


- (void) stop
{
    [self setPlaying:NO];
}


- (void) step
{
    SwiftScene *lastScene = [self scene];
    m_rawFrameIndex++;
    SwiftScene *currentScene = [self scene];
    BOOL atEnd = NO;

    // If we switched scenes, see if we should loop
    if (lastScene != currentScene) {
        if (m_loopsScene) {
            m_rawFrameIndex = [lastScene indexInMovie];
        }

    // If frame is now nil, we hit the end of the movie
    } else if (![self frame]) {
        if (m_loopsMovie) {
            m_rawFrameIndex = 0;
        } else {
            atEnd = YES;
            m_rawFrameIndex--;
        }
    }
    
    if (atEnd) {
        [self setPlaying:NO];
    }

    [m_delegate playheadDidUpdate:self];
}


#pragma mark -
#pragma mark Accessors

- (void) setRawFrameIndex:(NSUInteger)rawFrameIndex
{
    if (rawFrameIndex != m_rawFrameIndex) {
        m_rawFrameIndex = rawFrameIndex;
        [m_delegate playheadDidUpdate:self];
    }
}


- (void) setFrame:(SwiftFrame *)frame
{
    NSArray   *frames = [m_movie frames];
    NSUInteger index  = [frames indexOfObject:frame];
    
    if (index != NSNotFound) {
        [self setRawFrameIndex:index];
    }
}


- (void) setScene:(SwiftScene *)scene
{
    NSArray *scenes = [m_movie scenes];
    if ([scenes containsObject:scene]) {
        [self setRawFrameIndex:[scene indexInMovie]];
    }
}


- (void) setSceneName:(NSString *)sceneName
{
    SwiftScene *scene = [m_movie sceneWithName:sceneName];
    if (scene) [self setScene:scene];
}


- (void) setFrameLabel:(NSString *)frameLabel
{
    SwiftFrame *frame = [m_movie frameWithLabel:frameLabel];
    if (frame) [self setFrame:frame];
}


- (void) setFrameIndex1:(NSUInteger)frameIndex1
{
    NSUInteger  index  = (frameIndex1 - 1);
    NSArray    *frames = [[self scene] frames];
    SwiftFrame *frame  = nil;

    if (index < [frames count]) {
        frame = [frames objectAtIndex:index];
    }
    
    if (frame) [self setFrame:frame];
}


- (SwiftFrame *) frame
{
    NSArray *frames = [m_movie frames];

    if (m_rawFrameIndex < [frames count]) {
        return [frames objectAtIndex:m_rawFrameIndex];
    }
    
    return nil;
}

- (NSString   *) frameLabel  { return [[self frame] label];         }
- (SwiftScene *) scene       { return [[self frame] scene];         }
- (NSString   *) sceneName   { return [[self scene] name];          }
- (NSUInteger)   frameIndex1 { return [[self frame] index1InScene]; }


- (void) setDelegate:(id<SwiftPlayheadDelegate>)delegate
{
    if (m_delegate != delegate) {
        m_delegate = delegate;
        m_delegate_playheadDidUpdate = [m_delegate respondsToSelector:@selector(playheadDidUpdate:)];
    }
}


- (void) setPlaying:(BOOL)playing
{
    if ([self isPlaying] != playing) {
        [self _cleanupTimer];

        if (playing) {
            NSMethodSignature *signature = [self methodSignatureForSelector:@selector(_tick)];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            
            [invocation setTarget:self];
            [invocation setSelector:@selector(_tick)];
            
            m_timer = [[NSTimer scheduledTimerWithTimeInterval:(1 / 60.0) invocation:invocation repeats:YES] retain];
            m_timerPlayStart = CACurrentMediaTime();
            m_timerPlayIndex = 0;
        }
    }
}


- (BOOL) isPlaying
{
    return m_timer != nil;
}


@synthesize delegate      = m_delegate,
            movie         = m_movie,
            rawFrameIndex = m_rawFrameIndex,
            loopsMovie    = m_loopsMovie,
            loopsScene    = m_loopsScene;

@end
