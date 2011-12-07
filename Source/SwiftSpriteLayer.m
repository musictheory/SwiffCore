/*
    SwiftSpriteLayer.m
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

#import "SwiftSpriteLayer.h"

#import "SwiftFrame.h"
#import "SwiftMovie.h"
#import "SwiftPlacedObject.h"
#import "SwiftRenderer.h"


static NSString * const PlacedObjectKey = @"SwiftPlacedObject";

@interface SwiftSpriteLayer ()
- (void) _clearContentAndRemove:(BOOL)removeLayer;
- (void) _setupContent;
@end


@implementation SwiftSpriteLayer

- (id) init
{
    if ((self = [super init])) {
        [self _setupContent];
    }

    return self;
}


- (id) initWithSpriteDefinition: (SwiftSpriteDefinition *) spriteDefinition
{
    if ((self = [self init])) {
        m_spriteDefinition = [spriteDefinition retain];
    }
    
    return self;
}


- (void) dealloc
{
    [self _clearContentAndRemove:NO];
    
    [m_currentFrame release];
    m_currentFrame = nil;
    
    [super dealloc];
}



#pragma mark -
#pragma mark Private Methods

- (void) _clearContentAndRemove:(BOOL)removeLayer
{
    if (m_usesSublayers) {
        for (CALayer *layer in [m_content.depthToLayerMap allValues]) {
            [layer setDelegate:nil];
            if (removeLayer) [layer removeFromSuperlayer];
        }

        [m_content.depthToLayerMap release];
        m_content.depthToLayerMap = nil;

    } else {
        [m_content.layer setDelegate:nil];
        if (removeLayer) [m_content.layer removeFromSuperlayer];
        [m_content.layer release];
        m_content.layer = nil;
    }
}


- (void) _setupContent
{
    if (m_usesSublayers) {
        [m_content.depthToLayerMap release];
        m_content.depthToLayerMap = [[NSMutableDictionary alloc] init];

    } else {
        [m_content.layer setDelegate:nil];
        [m_content.layer release];
        m_content.layer = [[CALayer alloc] init];

        [m_content.layer setDelegate:self];
        [self addSublayer:m_content.layer];
    }
}


- (void) _setNeedsDisplayOnAll
{
    if (m_usesSublayers) {
        for (CALayer *layer in [m_content.depthToLayerMap allValues]) {
            [layer setNeedsDisplay];
        }
    } else {
        [m_content.layer setNeedsDisplay];
    }
}


- (void) _setNeedsLayoutOnAll
{
    if (m_usesSublayers) {
        for (CALayer *layer in [m_content.depthToLayerMap allValues]) {
            //!i: We need to recalculate the frame for all sublayers
        }

    } else {
        [m_content.layer setFrame:[self bounds]];
        [m_content.layer setNeedsDisplay];
    }
}


- (BOOL) _spriteLayer:(SwiftSpriteLayer *)layer shouldInterpolateFromFrame:(SwiftFrame *)fromFrame toFrame:(SwiftFrame *)toFrame
{
    CALayer *superlayer = [self superlayer];

    // Send up layer hierarchy until we find our SwiftMovieLayer
    if ([superlayer isKindOfClass:[SwiftSpriteLayer class]]) {
        return [(SwiftSpriteLayer *)superlayer _spriteLayer:layer shouldInterpolateFromFrame:fromFrame toFrame:toFrame];
    }
    
    return NO;
}


- (CGAffineTransform) _baseAffineTransform
{
    CGSize movieSize = [m_movie stageRect].size;
    CGRect bounds    = [self bounds];

    return CGAffineTransformMakeScale(bounds.size.width /  movieSize.width, bounds.size.height / movieSize.height);
}


- (SwiftColorTransform) _baseColorTransform
{
    return SwiftColorTransformIdentity;
}


- (void) _transitionToFrame:(SwiftFrame *)toFrame
{
    if (!m_usesSublayers) {
        [m_content.layer setNeedsDisplay];
        return;
    }

    NSEnumerator *oldEnumerator = [[m_currentFrame placedObjects] objectEnumerator];
    NSEnumerator *newEnumerator = [[toFrame        placedObjects] objectEnumerator];
    
    SwiftPlacedObject *oldPlacedObject = [oldEnumerator nextObject];
    SwiftPlacedObject *newPlacedObject = [newEnumerator nextObject];

    NSInteger oldDepth = oldPlacedObject ? [oldPlacedObject depth] : NSIntegerMax;
    NSInteger newDepth = newPlacedObject ? [newPlacedObject depth] : NSIntegerMax;

    CGAffineTransform baseTransform = [self _baseAffineTransform];

    void (^updateLayer)(CALayer *layer, SwiftPlacedObject *) = ^(CALayer *layer, SwiftPlacedObject *placedObject) {
        UInt16 libraryID = [placedObject libraryID];
        id definition = [m_movie definitionWithLibraryID:libraryID];

        CGRect bounds = [definition bounds];
        bounds = CGRectApplyAffineTransform(bounds, baseTransform);
        
        [layer setValue:placedObject forKey:PlacedObjectKey];
        [layer setBounds:bounds];
        [layer setAnchorPoint:CGPointMake(-bounds.origin.x / bounds.size.width, (-bounds.origin.y / bounds.size.height))];

        CGAffineTransform layerTransform = [placedObject affineTransform];
        layerTransform.tx *= baseTransform.a;
        layerTransform.ty *= baseTransform.d;

        [layer setAffineTransform:layerTransform];
    };
    
    while ((oldDepth < NSIntegerMax) || (newDepth < NSIntegerMax)) {
        if (oldDepth == newDepth) {
            UInt16 oldLibraryID = [oldPlacedObject libraryID];
            UInt16 newLibraryID = [newPlacedObject libraryID];
            
            NSNumber *key = [[NSNumber alloc] initWithInteger:newDepth];
            CALayer *layer = [m_content.depthToLayerMap objectForKey:key];
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
            [m_content.depthToLayerMap setObject:layer forKey:key];
            [key release];

            updateLayer(layer, newPlacedObject);
            [layer setNeedsDisplay];

            [self addSublayer:layer];
            [layer release];

            newPlacedObject = [newEnumerator nextObject];
            newDepth = newPlacedObject ? [newPlacedObject depth] : NSIntegerMax;

        } else if (oldDepth < newDepth) {
            NSNumber *key = [[NSNumber alloc] initWithInteger:oldDepth];

            CALayer *layer = [m_content.depthToLayerMap objectForKey:key];
            [layer setDelegate:nil];
            [layer removeFromSuperlayer];

            [m_content.depthToLayerMap removeObjectForKey:key];
            [key release];

            oldPlacedObject = [oldEnumerator nextObject];
            oldDepth = oldPlacedObject ? [oldPlacedObject depth] : NSIntegerMax;
        }
    }
}


#pragma mark -
#pragma mark CALayer Logic

- (void) layoutSublayers
{
    [super layoutSublayers];

    if (!m_usesSublayers) {
        [m_content.layer setFrame:[self bounds]];
        [m_content.layer setNeedsDisplay];
    }
}


- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    CGContextSaveGState(context);

    if (m_usesSublayers) {
        SwiftPlacedObject *placedObject = [layer valueForKey:PlacedObjectKey];
        CGPoint position = [layer position];

        CGContextTranslateCTM(context, -position.x, -position.y);

        CGAffineTransform baseTransform = [self _baseAffineTransform];
        SwiftColorTransform baseColorTransform = [self _baseColorTransform];

        [[SwiftRenderer sharedInstance] renderPlacedObject:placedObject movie:m_movie context:context baseAffineTransform:baseTransform baseColorTransform:baseColorTransform];

    } else if (m_spriteDefinition) {

    } else if (m_currentFrame) {
        CGAffineTransform baseTransform = [self _baseAffineTransform];
        SwiftColorTransform baseColorTransform = [self _baseColorTransform];

        [[SwiftRenderer sharedInstance] renderFrame:m_currentFrame movie:m_movie context:context baseAffineTransform:baseTransform baseColorTransform:baseColorTransform];
    }

    CGContextRestoreGState(context);
}


- (id<CAAction>) actionForKey:(NSString *)event
{
    return nil;
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if (m_interpolateFrame) {
        CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:event];
        
        [basicAnimation setDuration:(1.0 / [m_movie frameRate])];
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
        m_interpolateFrame = [self _spriteLayer:self shouldInterpolateFromFrame:m_currentFrame toFrame:frame];
        
        [self _transitionToFrame:frame];

        [m_currentFrame release];
        m_currentFrame = [frame retain];
    }
}


- (void) setUsesSublayers:(BOOL)usesSublayers
{
    if (m_usesSublayers != usesSublayers) {
        [self _clearContentAndRemove:YES];
        m_usesSublayers = usesSublayers;
        [self _setupContent];
    }
}


@synthesize movie            = m_movie,
            currentFrame     = m_currentFrame,
            spriteDefinition = m_spriteDefinition,
            usesSublayers    = m_usesSublayers;

@end
