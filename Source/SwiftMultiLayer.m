/*
    SwiftLayer.m
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

#import "SwiftMultiLayer.h"
#import "SwiftRenderer.h"

static NSString * const PlacedObjectKey = @"SwiftPlacedObject";

@implementation SwiftMultiLayer


- (id) initWithMovie:(SwiftMovie *)movie
{
    if ((self = [super initWithMovie:movie])) {
        m_depthToLayerMap = [[NSMutableDictionary alloc] init];
    }

    return self;
}


- (void) dealloc
{
    [m_depthToLayerMap release];
    m_depthToLayerMap = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods

- (void) transitionToFrame:(SwiftFrame *)newFrame fromFrame:(SwiftFrame *)oldFrame
{
    NSEnumerator *oldEnumerator = [[oldFrame placedObjects] objectEnumerator];
    NSEnumerator *newEnumerator = [[newFrame placedObjects] objectEnumerator];
    
    SwiftPlacedObject *oldPlacedObject = [oldEnumerator nextObject];
    SwiftPlacedObject *newPlacedObject = [newEnumerator nextObject];

    NSInteger oldDepth = oldPlacedObject ? [oldPlacedObject depth] : NSIntegerMax;
    NSInteger newDepth = newPlacedObject ? [newPlacedObject depth] : NSIntegerMax;
    
    void (^updateLayer)(CALayer *layer, SwiftPlacedObject *) = ^(CALayer *layer, SwiftPlacedObject *placedObject) {
        UInt16 libraryID = [placedObject libraryID];
        id definition = [m_movie definitionWithLibraryID:libraryID];

        CGRect bounds = [definition bounds];
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
            UInt16 oldLibraryID = [oldPlacedObject libraryID];
            UInt16 newLibraryID = [newPlacedObject libraryID];
            
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

//            [layer setBackgroundColor:[[UIColor colorWithRed:((rand() % 16) / 15.0) green:((rand() % 16) / 15.0) blue:((rand() % 16) / 15.0) alpha:0.5] CGColor]];

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

    CGSize movieSize = [m_movie stageRect].size;
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
        
        [basicAnimation setDuration:[self frameAnimationDuration]];
        [basicAnimation setCumulative:YES];

        return basicAnimation;

    } else {
        return (id)[NSNull null];
    }
}

@end
