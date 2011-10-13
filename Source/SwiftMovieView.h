//
//  SwiftMovieView.h
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class SwiftLayer, SwiftMovie, SwiftScene, SwiftFrame;

@protocol SwiftMovieViewDelegate;

@interface SwiftMovieView : UIView {
@private
    id<SwiftMovieViewDelegate> m_delegate;

    SwiftLayer    *m_layer;
    SwiftMovie    *m_movie;
    SwiftScene    *m_currentScene;
    SwiftFrame    *m_currentFrame;
    CADisplayLink *m_displayLink;
    CFTimeInterval m_playStart;
    long           m_playIndex;
    CFTimeInterval m_framesPerSecond;
    
    BOOL m_playing;
    BOOL m_usesAcceleratedRendering;
    BOOL m_interpolatesFrames;
    BOOL m_loopsMovie;
    BOOL m_loopsScene;

    BOOL m_delegate_movieView_willDisplayScene_frame;
    BOOL m_delegate_movieView_didDisplayScene_frame;
}

- (void) play;
- (void) stop;

@property (nonatomic, retain) SwiftMovie *movie;
@property (nonatomic, assign) id<SwiftMovieViewDelegate> delegate;

// Setting these properties modifies the playhead
@property (nonatomic, retain) SwiftScene *currentScene;
@property (nonatomic, retain) NSString   *currentSceneName;
@property (nonatomic, retain) SwiftFrame *currentFrame;
@property (nonatomic, retain) NSString   *currentFrameLabel;
@property (nonatomic, assign) NSInteger   currentFrameNumber;

@property (nonatomic, assign) BOOL usesAcceleratedRendering;
@property (nonatomic, assign) BOOL interpolatesFrames;
@property (nonatomic, assign) BOOL loopsMovie;
@property (nonatomic, assign) BOOL loopsScene;

@end


@protocol SwiftMovieViewDelegate <NSObject>
@optional
- (void) movieView:(SwiftMovieView *)movieView willDisplayScene:(SwiftScene *)scene frame:(SwiftFrame *)frame;
- (void) movieView:(SwiftMovieView *)movieView didDisplayScene:(SwiftScene *)scene  frame:(SwiftFrame *)frame;
@end

