/*
    SwiffPlayhead.m
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

#import "SwiffPlayhead.h"

#import "SwiffFrame.h"
#import "SwiffMovie.h"
#import "SwiffScene.h"

#import <QuartzCore/QuartzCore.h>


@interface SwiffPlayhead ()
- (void) _cleanupTimer;
- (void) _tick;
@end

extern void SwiffPlayheadWarnForInvalidGotoArguments(void);

void SwiffPlayheadWarnForInvalidGotoArguments()
{
    SwiffWarn(@"View", @"Invalid arguments sent to -[SwiffPlayhead goto...].  Break on SwiffPlayheadWarnForInvalidGotoArguments to debug");
}


@implementation SwiffPlayhead

- (id) initWithMovie:(SwiffMovie *)movie delegate:(id<SwiffPlayheadDelegate>)delegate
{
    if ((self = [super init])) {
        m_frameIndex = -1;
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

- (void) _gotoFrameWithIndex:(NSUInteger)frameIndex play:(BOOL)play
{
    BOOL isPlaying   = [self isPlaying];
    BOOL needsUpdate = NO;
    
    if (play && isPlaying) {
        m_frameIndexForNextStep = frameIndex;
        m_hasFrameIndexForNextStep = YES;

        return;
    }
    
    if (m_frameIndex != frameIndex) {
        m_frameIndex = frameIndex;
        needsUpdate = YES;
    }

    if (isPlaying != play) {
        [self _cleanupTimer];

        if (play) {
            NSMethodSignature *signature = [self methodSignatureForSelector:@selector(_tick)];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            
            [invocation setTarget:self];
            [invocation setSelector:@selector(_tick)];
            
            m_timer = [[NSTimer scheduledTimerWithTimeInterval:(1 / 60.0) invocation:invocation repeats:YES] retain];
            m_timerPlayStart = CACurrentMediaTime();
            m_timerPlayIndex = 0;
        }
        
        needsUpdate = YES;
    }
    
    if (needsUpdate) {
        [m_delegate playheadDidUpdate:self];
    }
}


- (void) gotoScene:(SwiffScene *)inScene frameLabel:(NSString *)frameLabel play:(BOOL)play
{
    SwiffScene *scene = ([inScene movie] == m_movie) ? inScene : nil;
    SwiffFrame *frame = [scene frameWithLabel:frameLabel];

    if (frame) {
        [self _gotoFrameWithIndex:[frame indexInMovie] play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoScene:(SwiffScene *)inScene frameIndex1:(NSUInteger)frameIndex1 play:(BOOL)play
{
    SwiffScene *scene = ([inScene movie] == m_movie) ? inScene : nil;
    SwiffFrame *frame = [scene frameAtIndex1:frameIndex1];

    if (frame) {
        [self _gotoFrameWithIndex:[frame indexInMovie] play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoScene:(SwiffScene *)inScene frameIndex:(NSUInteger)frameIndex play:(BOOL)play
{
    SwiffScene *scene = [inScene movie] == m_movie ? inScene : nil;
    SwiffFrame *frame = [scene frameAtIndex:frameIndex];

    if (frame) {
        [self _gotoFrameWithIndex:[frame indexInMovie] play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoSceneWithName:(NSString *)sceneName frameLabel:(NSString *)frameLabel play:(BOOL)play
{
    SwiffScene *scene = [m_movie sceneWithName:sceneName];
    SwiffFrame *frame = [scene frameWithLabel:frameLabel];

    if (frame) {
        [self _gotoFrameWithIndex:[frame indexInMovie] play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoSceneWithName:(NSString *)sceneName frameIndex1:(NSUInteger)frameIndex1 play:(BOOL)play
{
    SwiffScene *scene = [m_movie sceneWithName:sceneName];
    SwiffFrame *frame = [scene frameAtIndex1:frameIndex1];

    if (frame) {
        [self _gotoFrameWithIndex:[frame indexInMovie] play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoSceneWithName:(NSString *)sceneName frameIndex:(NSUInteger)frameIndex play:(BOOL)play
{
    SwiffScene *scene = [m_movie sceneWithName:sceneName];
    SwiffFrame *frame = [scene frameAtIndex:frameIndex];

    if (frame) {
        [self _gotoFrameWithIndex:[frame indexInMovie] play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoFrameWithIndex1:(NSUInteger)frameIndex1 play:(BOOL)play
{
    if (frameIndex1 > 0 && frameIndex1 <= [[m_movie frames] count]) {
        [self _gotoFrameWithIndex:(frameIndex1 - 1) play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoFrameWithIndex:(NSUInteger)frameIndex play:(BOOL)play
{
    if (frameIndex < [[m_movie frames] count]) {
        [self _gotoFrameWithIndex:frameIndex play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoFrame:(SwiffFrame *)frame play:(BOOL)play
{
    NSUInteger frameIndex = [m_movie indexOfFrame:frame];
    
    if (frameIndex != NSNotFound) {
        [self _gotoFrameWithIndex:frameIndex play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) stop
{
    [self _gotoFrameWithIndex:m_frameIndex play:NO];
}


- (void) step
{
    SwiffScene *lastScene = [self scene];

    if (m_hasFrameIndexForNextStep) {
        m_frameIndex = m_frameIndexForNextStep;
        m_hasFrameIndexForNextStep = NO;
    } else {
        m_frameIndex++;
    }

    SwiffScene *currentScene = [self scene];
    BOOL atEnd = NO;

    // If we switched scenes, see if we should loop
    if (lastScene != currentScene) {
        if (m_loopsScene) {
            m_frameIndex = [lastScene indexInMovie];
        }

    // If frame is now nil, we hit the end of the movie
    } else if (![self frame]) {
        if (m_loopsMovie) {
            m_frameIndex = 0;
        } else {
            atEnd = YES;
            m_frameIndex--;
        }
    }
    
    if (atEnd) {
        [self stop];
    }

    [m_delegate playheadDidUpdate:self];
}


#pragma mark -
#pragma mark Accessors

- (SwiffFrame *) frame
{
    NSArray *frames = [m_movie frames];

    if (m_frameIndex < [frames count]) {
        return [frames objectAtIndex:m_frameIndex];
    }
    
    return nil;
}


- (SwiffScene *) scene
{
    return [[self frame] scene];
}


- (BOOL) isPlaying
{
    return m_timer != nil;
}


@synthesize delegate      = m_delegate,
            movie         = m_movie,
            loopsMovie    = m_loopsMovie,
            loopsScene    = m_loopsScene;

@end
