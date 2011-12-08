/*
    SwiftPlayhead.h
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

#import <SwiftImport.h>

@class SwiftScene, SwiftFrame, SwiftMovie;
@protocol SwiftPlayheadDelegate;


@interface SwiftPlayhead : NSObject {
@private
    id<SwiftPlayheadDelegate> m_delegate;

    SwiftMovie    *m_movie;
    NSInteger      m_frameIndex;

    NSTimer       *m_timer;
    CFTimeInterval m_timerPlayStart;
    long           m_timerPlayIndex;

    BOOL           m_loopsMovie;
    BOOL           m_loopsScene;
    BOOL           m_delegate_playheadDidUpdate;
}

- (id) initWithMovie:(SwiftMovie *)movie delegate:(id<SwiftPlayheadDelegate>)delegate;

- (void) gotoScene:(SwiftScene *)scene frameLabel: (NSString *)frameLabel  play:(BOOL)play;
- (void) gotoScene:(SwiftScene *)scene frameIndex1:(NSUInteger)frameIndex1 play:(BOOL)play;
- (void) gotoScene:(SwiftScene *)scene frameIndex: (NSUInteger)frameIndex  play:(BOOL)play;

- (void) gotoSceneWithName:(NSString *)sceneName frameLabel: (NSString *)frameLabel  play:(BOOL)play;
- (void) gotoSceneWithName:(NSString *)sceneName frameIndex1:(NSUInteger)frameIndex1 play:(BOOL)play;
- (void) gotoSceneWithName:(NSString *)sceneName frameIndex: (NSUInteger)frameIndex  play:(BOOL)play;

- (void) gotoFrameWithIndex1:(NSUInteger)frameIndex1 play:(BOOL)play;
- (void) gotoFrameWithIndex: (NSUInteger)frameIndex  play:(BOOL)play;

- (void) gotoFrame:(SwiftFrame *)frame play:(BOOL)play;

- (void) stop;
- (void) step;

@property (nonatomic, assign) id<SwiftPlayheadDelegate> delegate;
@property (nonatomic, assign) BOOL loopsMovie;
@property (nonatomic, assign) BOOL loopsScene;

@property (nonatomic, readonly, retain) SwiftMovie *movie;
@property (nonatomic, readonly, assign) SwiftScene *scene;
@property (nonatomic, readonly, assign) SwiftFrame *frame;
@property (nonatomic, readonly, getter=isPlaying) BOOL playing;

@end


@protocol SwiftPlayheadDelegate <NSObject>
@optional
- (void) playheadDidUpdate:(SwiftPlayhead *)playhead;
@end
