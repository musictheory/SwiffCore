//
//  SwiftRenderLayer.m
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftLayer.h"
#import "SwiftRenderer.h"

static NSString * const PlacedObjectKey = @"SwiftPlacedObject";

@implementation SwiftLayer

- (id) _initWithSprite:(SwiftSprite *)sprite
{
    if ((self = [super init])) {
        m_sprite = [sprite retain];
        m_depthToLayerMap = [[NSMutableDictionary alloc] init];

        [self setMasksToBounds:YES];
    }
    return self;
}

- (id) initWithMovie:(SwiftMovie *)movie;
{
    if ((self = [self _initWithSprite:movie])) {
        m_movie = [movie retain];
    }
    
    return self;
}


- (void) dealloc
{
    [m_movie           release];  m_movie           = nil;
    [m_sprite          release];  m_sprite          = nil;
    [m_currentFrame    release];  m_currentFrame    = nil;
    [m_depthToLayerMap release];  m_depthToLayerMap = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods

- (void) _transitionToFrame:(SwiftFrame *)newFrame fromFrame:(SwiftFrame *)oldFrame
{
    NSEnumerator *oldEnumerator = [[oldFrame placedObjects] objectEnumerator];
    NSEnumerator *newEnumerator = [[newFrame placedObjects] objectEnumerator];
    
    SwiftPlacedObject *oldPlacedObject = [oldEnumerator nextObject];
    SwiftPlacedObject *newPlacedObject = [newEnumerator nextObject];

    NSInteger oldDepth = oldPlacedObject ? [oldPlacedObject depth] : NSIntegerMax;
    NSInteger newDepth = newPlacedObject ? [newPlacedObject depth] : NSIntegerMax;
    
    void (^updateLayer)(CALayer *layer, SwiftPlacedObject *) = ^(CALayer *layer, SwiftPlacedObject *placedObject) {
        NSInteger objectID = [placedObject objectID];
        id object = [m_movie objectWithID:objectID];

        CGRect bounds = [object bounds];
        bounds = CGRectApplyAffineTransform(bounds, m_baseTransform);
        
        [layer setValue:placedObject forKey:PlacedObjectKey];
        [layer setBounds:bounds];
        [layer setAnchorPoint:CGPointMake(-bounds.origin.x / bounds.size.width, (-bounds.origin.y / bounds.size.height))];

        CGAffineTransform layerTransform = [placedObject affineTransform];
        layerTransform.tx *= m_baseTransform.a;
        layerTransform.ty *= m_baseTransform.d;

        [layer setAffineTransform:layerTransform];
    };
    
    while ((oldDepth < NSIntegerMax) || (newDepth < NSIntegerMax)) {
        if (oldDepth == newDepth) {
            NSInteger oldLibraryID = [oldPlacedObject objectID];
            NSInteger newLibraryID = [newPlacedObject objectID];
            
            NSNumber *key = [[NSNumber alloc] initWithInteger:newDepth];
            CALayer *layer = [m_depthToLayerMap objectForKey:key];
            if (oldLibraryID != newLibraryID) [layer setNeedsDisplay];
            if (layer) updateLayer(layer, newPlacedObject);

            [key release];
            
            oldPlacedObject = [oldEnumerator nextObject];
            oldDepth = oldPlacedObject ? [oldPlacedObject depth] : NSIntegerMax;
            newPlacedObject = [newEnumerator nextObject];
            newDepth = newPlacedObject ? [newPlacedObject depth] : NSIntegerMax;
            
        } else if (newDepth < oldDepth) {
            CALayer *layer = [[CALayer alloc] init];

            [layer setDelegate:self];
            [layer setZPosition:newDepth];

            NSNumber *key = [[NSNumber alloc] initWithInteger:newDepth];
            [m_depthToLayerMap setObject:layer forKey:key];
            [key release];

            updateLayer(layer, newPlacedObject);
            [layer setNeedsDisplay];

            [self addSublayer:layer];
            [layer release];

            newPlacedObject = [newEnumerator nextObject];
            newDepth = newPlacedObject ? [newPlacedObject depth] : NSIntegerMax;

        } else if (oldDepth < newDepth) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:oldDepth];

            CALayer *layer = [m_depthToLayerMap objectForKey:key];
            [layer setDelegate:nil];
            [layer removeFromSuperlayer];

            [m_depthToLayerMap removeObjectForKey:key];
            [key release];

            oldPlacedObject = [oldEnumerator nextObject];
            oldDepth = oldPlacedObject ? [oldPlacedObject depth] : NSIntegerMax;
        }
    }
}


#pragma mark -
#pragma mark CALayer Logic

- (void) setBounds:(CGRect)bounds
{
    [super setBounds:bounds];

    CGSize movieSize  = [m_movie stageSize];
    m_baseTransform = CGAffineTransformMakeScale(bounds.size.width /  movieSize.width, bounds.size.height / movieSize.height);
}


- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    CGContextSaveGState(context);

    SwiftPlacedObject *placedObject = [layer valueForKey:PlacedObjectKey];
    CGPoint position = [layer position];

    CGContextTranslateCTM(context, -position.x, -position.y);
    CGContextConcatCTM(context, m_baseTransform);

    [[SwiftRenderer sharedInstance] renderPlacedObject:placedObject movie:m_movie context:context];

    CGContextRestoreGState(context);
}


- (id<CAAction>) actionForKey:(NSString *)event
{
    return nil;
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if (m_frameAnimationDuration > 0.0) {
        CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:event];
        
        [basicAnimation setDuration:m_frameAnimationDuration];
        [basicAnimation setCumulative:YES];

        return basicAnimation;

    } else {
        return (id)[NSNull null];
    }
}


#pragma mark -
#pragma mark Accessors

- (void) setCurrentFrame:(SwiftFrame *)frame
{
    if (frame != m_currentFrame) {
        [self _transitionToFrame:frame fromFrame:m_currentFrame];

        [m_currentFrame release];
        m_currentFrame = [frame retain];
    }
}

@synthesize sprite       = m_sprite,
            movie        = m_movie,
            currentFrame = m_currentFrame;

@synthesize usesAcceleratedRendering = m_usesAcceleratedRendering,
            frameAnimationDuration   = m_frameAnimationDuration;

@end
