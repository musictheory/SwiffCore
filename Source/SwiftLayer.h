//
//  SwiftRenderLayer.h
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class SwiftMovie, SwiftSprite, SwiftFrame;

@interface SwiftLayer : CALayer {
    SwiftMovie          *m_movie;
    SwiftSprite         *m_sprite;
    SwiftFrame          *m_currentFrame;
    NSMutableDictionary *m_depthToLayerMap;
    CGAffineTransform    m_baseTransform;
    
    BOOL    m_usesAcceleratedRendering;
    CGFloat m_frameAnimationDuration;
}

- (id) initWithMovie:(SwiftMovie *)movie;

@property (nonatomic, assign, readonly) SwiftMovie  *movie;
@property (nonatomic, retain, readonly) SwiftSprite *sprite;

@property (nonatomic, retain) SwiftFrame *currentFrame;

@property (nonatomic, assign) BOOL usesAcceleratedRendering;
@property (nonatomic, assign) CGFloat frameAnimationDuration;

@end
