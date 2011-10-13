//
//  SwiftMovieView.m
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftMovieView.h"

#import "SwiftLayer.h"
#import "SwiftScene.h"
#import "SwiftFrame.h"

@interface SwiftMovieView ()
- (void) _displayLinkDidFire:(CADisplayLink *)displayLink;
@end


@implementation SwiftMovieView

- (void) dealloc
{
    [m_displayLink invalidate];

    [m_movie        release];  m_movie        = nil;
    [m_currentScene release];  m_currentScene = nil;
    [m_currentFrame release];  m_currentFrame = nil;
    [m_displayLink  release];  m_displayLink  = nil;
    [m_layer        release];  m_layer        = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Superclass Overrides

- (void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsLayout];
}


- (void) layoutSubviews
{
    UIViewContentMode mode = [self contentMode];

    CGRect bounds    = [self bounds];
    CGSize movieSize = [m_movie stageSize];
    CGRect frame     = { CGPointZero, movieSize };

    if (mode == UIViewContentModeScaleToFill) {
        frame = bounds;

    } else if ((mode == UIViewContentModeScaleAspectFit) || (mode == UIViewContentModeScaleAspectFit)) {
        
        
    } else if (mode == UIViewContentModeScaleAspectFill) {
        
    
    } else {
        CGFloat x = 0.0, y = 0.0;

        if ((mode == UIViewContentModeTopLeft) || (mode == UIViewContentModeLeft) || (mode == UIViewContentModeBottomLeft)) {
            x = 0.0;
        } else if ((mode == UIViewContentModeTop) || (mode == UIViewContentModeCenter) || (mode == UIViewContentModeBottom)) {
            x = round((bounds.size.width - movieSize.width) / 2.0);
        } else if ((mode == UIViewContentModeTopRight) || (mode == UIViewContentModeRight) || (mode == UIViewContentModeBottomRight)) {
            x = bounds.size.width - movieSize.width;
        }

        if ((mode == UIViewContentModeTopLeft) || (mode == UIViewContentModeTop) || (mode == UIViewContentModeTopRight)) {
            y = 0.0;
        } else if ((mode == UIViewContentModeLeft) || (mode == UIViewContentModeCenter) || (mode == UIViewContentModeRight)) {
            y = round((bounds.size.height - movieSize.height) / 2.0);
        } else if ((mode == UIViewContentModeBottomLeft) || (mode == UIViewContentModeBottom) || (mode == UIViewContentModeBottomRight)) {
            y = bounds.size.height - movieSize.height;
        }

        frame = CGRectMake(x, y, movieSize.width, movieSize.height);
    }

    [m_layer setFrame:frame];
}


- (void) setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    [self setNeedsLayout];
}


- (void) willMoveToWindow:(UIWindow *)newWindow
{
    if (newWindow != [self window]) {
        CGFloat scale = [newWindow contentScaleFactor];
        if (scale < 1) scale = 1;
        [self setContentScaleFactor:scale];
        [m_layer setContentsScale:scale];

        [m_displayLink invalidate];
        [m_displayLink release];
        m_displayLink = nil;
        
        m_displayLink = [[[newWindow screen] displayLinkWithTarget:self selector:@selector(_displayLinkDidFire:)] retain]; 
        [m_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [m_displayLink setPaused:!m_playing];
        m_playStart = CACurrentMediaTime();
        m_playIndex = 0;
    }
}


- (void) _gotoNextFrame
{
    SwiftFrame *currentFrame = m_currentFrame;
    SwiftFrame *nextFrame    = [currentFrame nextFrame];
    
    // If nextFrame is nil, we are at the end of the movie.  Loop movie if requested
    if (!nextFrame && m_loopsMovie) {
        NSArray *frames = [m_movie frames];
        nextFrame = [frames count] ? [frames objectAtIndex:0] : nil;
    }
    
    // If indexOfScene is lower than the old indexOfScene, we switched scenes.  Loop scene if requested
    if (nextFrame && ([nextFrame indexInScene] < [currentFrame indexInScene]) && m_loopsScene) {
        NSArray *frames = [m_currentScene frames];
        nextFrame = [frames count] ? [frames objectAtIndex:0] : nil;
    }

    if (nextFrame) {
        [nextFrame retain]; // Be paranoid, as setCurrentScene: calls setCurrentFrame:

        [self setCurrentScene:[nextFrame parentScene]];
        [self setCurrentFrame:nextFrame];

        [nextFrame release];

    } else {
        [self stop];
    }
}


- (void) _displayLinkDidFire:(CADisplayLink *)displayLink
{
    CFTimeInterval elapsed = ([m_displayLink timestamp] - m_playStart);
    
    long currentFrame = (long)(elapsed * m_framesPerSecond);

    if (m_playIndex != currentFrame) {
        [self _gotoNextFrame];
        m_playIndex = currentFrame;
    }
}


- (void) play
{
    m_playing = YES;
    [m_displayLink setPaused:!m_playing];
    m_playStart = CACurrentMediaTime();
    m_playIndex = 0;
}

- (void) stop
{
    m_playing = NO;
    [m_displayLink setPaused:!m_playing];
}


#pragma mark -
#pragma mark Accessors

- (void) setMovie:(SwiftMovie *)movie
{
    if (m_movie != movie) {
        [m_movie release];
        m_movie = [movie retain];
        
        [m_layer removeFromSuperlayer];
        [m_layer release];


        m_framesPerSecond = [m_movie frameRate];

        m_layer = [[SwiftLayer alloc] initWithMovie:m_movie];
        [m_layer setUsesAcceleratedRendering:m_usesAcceleratedRendering];
        [m_layer setFrameAnimationDuration:(m_interpolatesFrames ? (1.0 / m_framesPerSecond) : 0.0)];
        [m_layer setCurrentFrame:m_currentFrame];

        NSArray *scenes = [m_movie scenes];
        [self setCurrentScene:[scenes count] ? [scenes objectAtIndex:0] : nil];

        [[self layer] addSublayer:m_layer];
        [self setNeedsLayout];
    }
}


- (void) setCurrentScene:(SwiftScene *)scene
{
    if (m_currentScene != scene) {
        [m_currentScene release];
        m_currentScene = [scene retain];

        [self setCurrentFrameNumber:1];
    }
}


- (void) setCurrentSceneName:(NSString *)sceneName
{
    SwiftScene *scene = [m_movie sceneWithName:sceneName];
    if (scene) [self setCurrentScene:scene];
}


- (NSString *) currentSceneName
{
    return [m_currentScene name];
}


- (void) setCurrentFrame:(SwiftFrame *)frame
{
    if (m_currentFrame != frame) {
        [m_currentFrame release];
        m_currentFrame = [frame retain];
        
        [m_layer setCurrentFrame:frame];
    }
}


- (void) setCurrentFrameLabel:(NSString *)frameLabel
{
    SwiftFrame *frame = [m_currentScene frameWithLabel:frameLabel];
    if (frame) [self setCurrentFrame:frame];
}


- (NSString *) currentFrameLabel
{
    return [m_currentFrame label];
}


- (void) setCurrentFrameNumber:(NSInteger)frameNumber
{
    SwiftFrame *frame = [m_currentScene frameAtIndex1:frameNumber];
    if (frame) [self setCurrentFrame:frame];
}


- (NSInteger) currentFrameNumber
{
    return [m_currentScene index1OfFrame:m_currentFrame];
}


- (void) setUsesAcceleratedRendering:(BOOL)yn
{
    m_usesAcceleratedRendering = yn;
    [m_layer setUsesAcceleratedRendering:yn];
}


- (void) setInterpolatesFrames:(BOOL)yn
{
    m_interpolatesFrames = yn;
    [m_layer setFrameAnimationDuration:(yn ? (1.0 / [m_movie frameRate]) : 0.0)];
}


- (void) setDelegate:(id<SwiftMovieViewDelegate>)delegate
{
    if (delegate != m_delegate) {
        m_delegate = delegate;
        m_delegate_movieView_didDisplayScene_frame  = [delegate respondsToSelector:@selector(movieView:didDisplayScene:frame:)];
        m_delegate_movieView_willDisplayScene_frame = [delegate respondsToSelector:@selector(movieView:willDisplayScene:frame:)];
    }
} 


@synthesize movie                    = m_movie,
            delegate                 = m_delegate,
            currentScene             = m_currentScene,
            currentFrame             = m_currentFrame,
            usesAcceleratedRendering = m_usesAcceleratedRendering,
            interpolatesFrames       = m_interpolatesFrames,
            loopsMovie               = m_loopsMovie,
            loopsScene               = m_loopsScene;

@end
