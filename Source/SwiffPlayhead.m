/*
    SwiffPlayhead.m
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

#import "SwiffPlayhead.h"

#import "SwiffFrame.h"
#import "SwiffMovie.h"
#import "SwiffScene.h"
#import "SwiffUtils.h"
#import "SwiffSoundPlayer.h"

#import <QuartzCore/QuartzCore.h>


extern void SwiffPlayheadWarnForInvalidGotoArguments(void);

void SwiffPlayheadWarnForInvalidGotoArguments()
{
    SwiffWarn(@"View", @"Invalid arguments sent to -[SwiffPlayhead goto...].  Break on SwiffPlayheadWarnForInvalidGotoArguments to debug");
}


@interface SwiffPlayhead ()
- (void) handleTimerTick:(NSTimer *)timer;
@end


@implementation SwiffPlayhead {
    NSInteger      _frameIndex;
    NSInteger      _frameIndexForNextStep;
    NSTimer       *_timer;
    CADisplayLink *_displayLink;
    CFTimeInterval _timerPlayStart;
    long           _timerPlayIndex;
    BOOL           _hasFrameIndexForNextStep;
}

@synthesize delegate      = _delegate,
            movie         = _movie,
            loopsMovie    = _loopsMovie,
            loopsScene    = _loopsScene;


- (id) initWithMovie:(SwiffMovie *)movie delegate:(id<SwiffPlayheadDelegate>)delegate
{
    if ((self = [super init])) {
        _frameIndex = -1;
        _movie = movie;
        _delegate = delegate;
    }
    
    return self;
}


#pragma mark -
#pragma mark - Private Methods

- (void) invalidateTimers
{
    [_timer invalidate];
    _timer = nil;

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    [_displayLink setPaused:YES];
    [_displayLink invalidate];
    _displayLink = nil;
#endif
}


- (void) handleTimerTick:(id)sender
{
    long currentIndex = (long)((CACurrentMediaTime() - _timerPlayStart) * [_movie frameRate]);

    if (_timerPlayIndex != currentIndex) {
        [self step];
        _timerPlayIndex = currentIndex;
    }
}


#pragma mark -
#pragma mark Public Methods

- (void) _gotoFrameWithIndex:(NSUInteger)frameIndex play:(BOOL)play
{
    BOOL isPlaying   = [self isPlaying];
    BOOL needsUpdate = NO;
    
    if (isPlaying) {
        [[SwiffSoundPlayer sharedInstance] stopAllSoundsForMovie:_movie];
    }

    if (play && isPlaying) {
        _frameIndexForNextStep = frameIndex;
        _hasFrameIndexForNextStep = YES;

        return;
    }
    
    if (_frameIndex != frameIndex) {
        _frameIndex = frameIndex;
        needsUpdate = YES;
    }

    if (isPlaying != play) {
        [self invalidateTimers];

        if (play) {

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
            if ([CADisplayLink class]) {
                _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleTimerTick:)];
                [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

            } else
#endif

            {
                NSMethodSignature *signature = [self methodSignatureForSelector:@selector(handleTimerTick:)];
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                
                [invocation setTarget:self];
                [invocation setSelector:@selector(handleTimerTick:)];
                
                _timer = [NSTimer timerWithTimeInterval:(1 / 60.0) invocation:invocation repeats:YES];
                [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
                
                [invocation setArgument:(__bridge void *)_timer atIndex:2];
            }
            
            _timerPlayStart = CACurrentMediaTime();
            _timerPlayIndex = 0;
        }
        
        needsUpdate = YES;
    }
    
    if (needsUpdate) {
        [_delegate playheadDidUpdate:self step:NO];
    }
}


- (void) gotoScene:(SwiffScene *)inScene frameLabel:(NSString *)frameLabel play:(BOOL)play
{
    SwiffScene *scene = ([inScene movie] == _movie) ? inScene : nil;
    SwiffFrame *frame = [scene frameWithLabel:frameLabel];

    if (frame) {
        [self _gotoFrameWithIndex:[frame indexInMovie] play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoScene:(SwiffScene *)inScene frameIndex1:(NSUInteger)frameIndex1 play:(BOOL)play
{
    SwiffScene *scene = ([inScene movie] == _movie) ? inScene : nil;
    SwiffFrame *frame = [scene frameAtIndex1:frameIndex1];

    if (frame) {
        [self _gotoFrameWithIndex:[frame indexInMovie] play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoScene:(SwiffScene *)inScene frameIndex:(NSUInteger)frameIndex play:(BOOL)play
{
    SwiffScene *scene = [inScene movie] == _movie ? inScene : nil;
    SwiffFrame *frame = [scene frameAtIndex:frameIndex];

    if (frame) {
        [self _gotoFrameWithIndex:[frame indexInMovie] play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoSceneWithName:(NSString *)sceneName frameLabel:(NSString *)frameLabel play:(BOOL)play
{
    SwiffScene *scene = [_movie sceneWithName:sceneName];
    SwiffFrame *frame = [scene frameWithLabel:frameLabel];

    if (frame) {
        [self _gotoFrameWithIndex:[frame indexInMovie] play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoSceneWithName:(NSString *)sceneName frameIndex1:(NSUInteger)frameIndex1 play:(BOOL)play
{
    SwiffScene *scene = [_movie sceneWithName:sceneName];
    SwiffFrame *frame = [scene frameAtIndex1:frameIndex1];

    if (frame) {
        [self _gotoFrameWithIndex:[frame indexInMovie] play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoSceneWithName:(NSString *)sceneName frameIndex:(NSUInteger)frameIndex play:(BOOL)play
{
    SwiffScene *scene = [_movie sceneWithName:sceneName];
    SwiffFrame *frame = [scene frameAtIndex:frameIndex];

    if (frame) {
        [self _gotoFrameWithIndex:[frame indexInMovie] play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoFrameWithIndex1:(NSUInteger)frameIndex1 play:(BOOL)play
{
    if (frameIndex1 > 0 && frameIndex1 <= [[_movie frames] count]) {
        [self _gotoFrameWithIndex:(frameIndex1 - 1) play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoFrameWithIndex:(NSUInteger)frameIndex play:(BOOL)play
{
    if (frameIndex < [[_movie frames] count]) {
        [self _gotoFrameWithIndex:frameIndex play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) gotoFrame:(SwiffFrame *)frame play:(BOOL)play
{
    NSUInteger frameIndex = [_movie indexOfFrame:frame];
    
    if (frameIndex != NSNotFound) {
        [self _gotoFrameWithIndex:frameIndex play:play];
    } else {
        SwiffPlayheadWarnForInvalidGotoArguments();
    }
}


- (void) play
{
    if (![self isPlaying]) {
        [self _gotoFrameWithIndex:_frameIndex play:YES];
    }
}


- (void) stop
{
    if ([self isPlaying]) {
        [self _gotoFrameWithIndex:_frameIndex play:NO];
    }
}


- (void) step
{
    SwiffScene *lastScene = [self scene];

    if (_hasFrameIndexForNextStep) {
        _frameIndex = _frameIndexForNextStep;
        _hasFrameIndexForNextStep = NO;
    } else {
        _frameIndex++;
    }

    SwiffScene *currentScene = [self scene];
    BOOL atEnd = NO;

    // If we switched scenes, see if we should loop
    if (lastScene != currentScene) {
        if (_loopsScene) {
            _frameIndex = [lastScene indexInMovie];
        }

    // If frame is now nil, we hit the end of the movie
    } else if (![self frame]) {
        if (_loopsMovie) {
            _frameIndex = 0;
        } else {
            atEnd = YES;
            _frameIndex--;
        }
    }
    
    if (atEnd) {
        [self stop];
    }

    [_delegate playheadDidUpdate:self step:YES];
}


#pragma mark -
#pragma mark Accessors

- (SwiffFrame *) frame
{
    NSArray *frames = [_movie frames];

    if (_frameIndex < [frames count]) {
        return [frames objectAtIndex:_frameIndex];
    }
    
    return nil;
}


- (SwiffScene *) scene
{
    return [[self frame] scene];
}


- (BOOL) isPlaying
{
    return _timer || _displayLink;
}

@end
