/*
    SwiffSpriteLayer.m
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

#import "SwiffLayer.h"

#import "SwiffFrame.h"
#import "SwiffMovie.h"
#import "SwiffPlacedObject.h"
#import "SwiffPlayhead.h"
#import "SwiffRenderer.h"
#import "SwiffSoundPlayer.h"
#import "SwiffView.h"

#define DEBUG_SUBLAYERS 1


static NSString * const SwiffPlacedObjectKey       = @"SwiffPlacedObject";        // SwiffPlacedObject
static NSString * const SwiffRenderScaleFactorKey  = @"SwiffRenderScaleFactor";   // NSNumber<CGFloat>
static NSString * const SwiffRenderTranslationXKey = @"SwiffRenderTranslationX";  // NSNumber<CGFloat>
static NSString * const SwiffRenderTranslationYKey = @"SwiffRenderTranslationY";  // NSNumber<CGFloat>


@implementation SwiffLayer

- (id) initWithMovie:(SwiffMovie *)movie
{
    if ((self = [self init])) {
        m_movie = [movie retain];

        m_renderer = SwiffRendererCreate(movie);

        m_contentLayer = [[CALayer alloc] init];
        [m_contentLayer setDelegate:self];
        [self addSublayer:m_contentLayer];

        m_playhead = [[SwiffPlayhead alloc] initWithMovie:movie delegate:self];
        [m_playhead gotoFrameWithIndex:0 play:NO];
        
        [m_contentLayer setNeedsDisplay];
    }
    
    return self;
}


- (void) dealloc
{
    [m_playhead setDelegate:nil];

    SwiffRendererFree(m_renderer);
    m_renderer = NULL;

    [m_movie        release];  m_movie        = nil;
    [m_currentFrame release];  m_currentFrame = nil;
    [m_playhead     release];  m_playhead     = nil;
    [m_contentLayer release];  m_contentLayer = nil;

    SwiffSparseArrayEnumerateValues(&m_sublayers, ^(void *v) { [(id)v release]; });
    SwiffSparseArrayFree(&m_sublayers);

    [super dealloc];
}


- (void) clearWeakReferences
{
    [m_contentLayer setDelegate:nil];
}


#pragma mark -
#pragma mark Sublayers & Transitions

static NSValue *sGetValueForCGRect(CGRect rect)
{
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return [NSValue valueWithCGRect:rect];
#else
    return [NSValue valueWithRect:NSRectFromCGRect(rect)];
#endif
}


static NSValue *sGetValueForCGPoint(CGPoint point)
{
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return [NSValue valueWithCGPoint:point];
#else
    return [NSValue valueWithPoint:NSPointFromCGPoint(point)];
#endif
}


static CGRect sExpandRect(CGRect rect)
{
    CGFloat minX = CGRectGetMinX(rect);
    CGFloat minY = CGRectGetMinY(rect);
    CGFloat maxX = CGRectGetMaxX(rect);
    CGFloat maxY = CGRectGetMaxY(rect);

#if defined(CGFLOAT_IS_DOUBLE) && CGFLOAT_IS_DOUBLE
    minX = floor(minX);
    minY = floor(minY);
    maxX = ceil (maxX);
    maxY = ceil (maxY);
#else
    minX = floorf(minX);
    minY = floorf(minY);
    maxX = ceilf (maxX);
    maxY = ceilf (maxY);
#endif

    return CGRectMake(minX, minY, (maxX - minX), (maxY - minY));
}


- (void) _calculateGeometryForPlacedObject: (SwiffPlacedObject *) placedObject 
                               scaleFactor: (CGFloat) scaleFactor
                                 outBounds: (CGRect *) outBounds
                              outTransform: (CGAffineTransform *) outTransform
                              outTranslate: (CGPoint *) outTranslate
{
    id<SwiffDefinition> definition = [m_movie definitionWithLibraryID:[placedObject libraryID]];

    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformConcat(transform, [placedObject affineTransform]);
    transform = CGAffineTransformConcat(transform, m_scaledAffineTransform);
    
    CGAffineTransform scaleFactorTransform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
    
    CGRect bounds = [definition renderBounds];
    bounds = sExpandRect(CGRectApplyAffineTransform(bounds, scaleFactorTransform));
    transform = CGAffineTransformConcat(CGAffineTransformInvert(scaleFactorTransform), transform);

    CGPoint translate = CGPointZero;

    // If we aren't skewing/rotating, use additional tweak to draw crisp lines
    //
    if (outTranslate && (transform.b == 0) && (transform.c == 0)) {
//        CGFloat tx = transform.tx * transform.a;
//        CGFloat ty = transform.ty * transform.d;
//
//        transform.tx = floor(tx);
//        transform.ty = floor(ty);
//
//        translate = CGPointMake((tx - transform.tx), (ty - transform.ty));
//        
//        transform.tx /= transform.a;
//        transform.ty /= transform.d;
    }
    
    if (SwiffShouldLog(@"View")) {
        NSString *msg = [NSString stringWithFormat:
            @"Calculated geometry for %ld, scaleFactor=%lf:\n"
            @"       bounds: %lf,%lf %lf,%lf\n"
            @"    transform: %lf,%lf,%lf,%lf %lf,%lf\n"
            @"    translate: %lf,%lf\n",
            (long)[placedObject depth], (double)scaleFactor,
            (double)bounds.origin.x, (double)bounds.origin.y, (double)bounds.size.width, (double)bounds.size.height, 
            (double)transform.a, (double)transform.b, (double)transform.c, (double)transform.d, (double)transform.tx, (double)transform.ty,     
            (double)translate.x, (double)translate.y];

        SwiffLog(@"View", @"%@", msg);
    }

    if (outBounds)      *outBounds    = bounds;
    if (outTransform)   *outTransform = transform;
    if (outTranslate)   *outTranslate = translate;
}


- (CGFloat) _scaleFactorForPlacedObject:(SwiffPlacedObject *)placedObject
{
    CGAffineTransform t = CGAffineTransformIdentity;
    t = CGAffineTransformConcat(t, [placedObject affineTransform]);
    t = CGAffineTransformConcat(t, m_scaledAffineTransform);

    // Take a 1x1 square at (0,0) and apply the transform to it.
    //
    CGPoint topLeftPoint     = CGPointApplyAffineTransform(CGPointMake(0, 0), t);
    CGPoint topRightPoint    = CGPointApplyAffineTransform(CGPointMake(1, 0), t);
    CGPoint bottomLeftPoint  = CGPointApplyAffineTransform(CGPointMake(0, 1), t);
    CGPoint bottomRightPoint = CGPointApplyAffineTransform(CGPointMake(1, 1), t);

    // Next, use the distance formula to find the length of each side
    //
    CGFloat (^getDistance)(CGPoint, CGPoint) = ^(CGPoint p1, CGPoint p2) {
        return sqrt(pow(p2.x - p1.x, 2.0) + pow(p2.y - p1.y, 2.0));
    };

    CGFloat topLineLength    = getDistance(topLeftPoint,    topRightPoint);
    CGFloat bottomLineLength = getDistance(bottomLeftPoint, bottomRightPoint);
    CGFloat leftLineLength   = getDistance(topLeftPoint,    bottomLeftPoint);
    CGFloat rightLineLength  = getDistance(topRightPoint,   bottomRightPoint);

    // Finally, return the ceil of the maximum length
    //
    CGFloat max1 = MAX(topLineLength,  bottomLineLength);
    CGFloat max2 = MAX(leftLineLength, rightLineLength);
    CGFloat max3 = MAX(max1, max2);

    return ceil(max3);
}


- (void) _updateGeometryForSublayer:(CALayer *)sublayer withPlacedObject:(SwiffPlacedObject *)placedObject
{
    SwiffPlacedObject *oldPlacedObject = [sublayer valueForKey:SwiffPlacedObjectKey];

    CGFloat oldScaleFactor = [[sublayer valueForKey:SwiffRenderScaleFactorKey] doubleValue];
    CGFloat newScaleFactor = [self _scaleFactorForPlacedObject:placedObject];

    CGAffineTransform fromTransform = [sublayer affineTransform];
    CGRect            fromBounds    = [sublayer bounds];
    CGPoint           fromAnchor    = [sublayer anchorPoint];
    CGFloat           fromOpacity   = [sublayer opacity];
    CGAffineTransform toTransform;
    CGRect            toBounds;
    CGPoint           toAnchor;
    CGFloat           toOpacity     = 1.0;

    // When Core Animation interpolate 'bounds' at the same time as 'transform',
    // the result looks bad.  To fix this, we calculate the 'from' values with
    // the new placed object's scale factor.  This causes only 'transform' to
    // be interpolated.
    //
    if (oldScaleFactor != newScaleFactor) {
        [self _calculateGeometryForPlacedObject:  oldPlacedObject
                                    scaleFactor:  newScaleFactor 
                                      outBounds: &fromBounds 
                                   outTransform: &fromTransform 
                                   outTranslate:  NULL];

        fromAnchor = CGPointMake(
            -fromBounds.origin.x / fromBounds.size.width,
            -fromBounds.origin.y / fromBounds.size.height
        );

        [sublayer setNeedsDisplay];
    }

    // Handle color transforms.  For rendering speed, map SwiffColorTransform.alphaMultiple 
    // to CALayer.opacity.  If any other field of the color transform has changed,
    // we need to do a full redraw
    //
    {
        SwiffColorTransform  oldColorTransform = [oldPlacedObject colorTransform];
        SwiffColorTransform  newColorTransform = [placedObject    colorTransform];
        
        toOpacity = newColorTransform.alphaMultiply;

        // Set both to 0 to ignore alphaMultiply in compare
        oldColorTransform.alphaMultiply = 0;
        newColorTransform.alphaMultiply = 0;

        if (!SwiffColorTransformEqualToTransform(&oldColorTransform, &newColorTransform)) {
            [sublayer setNeedsDisplay];
        }
    }

    CGPoint toTranslate; 
    [self _calculateGeometryForPlacedObject:  placedObject 
                                scaleFactor:  newScaleFactor
                                  outBounds: &toBounds 
                               outTransform: &toTransform
                               outTranslate: &toTranslate];

    toAnchor = CGPointMake(
        -toBounds.origin.x / toBounds.size.width,
        -toBounds.origin.y / toBounds.size.height
    );
    
    [sublayer removeAllAnimations];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    [sublayer setBounds:toBounds];
    [sublayer setAnchorPoint:toAnchor];
    [sublayer setAffineTransform:toTransform];
    [sublayer setOpacity:toOpacity];
 
    [sublayer setValue:placedObject forKey:SwiffPlacedObjectKey];
    [sublayer setValue:[NSNumber numberWithDouble:toTranslate.x]  forKey:SwiffRenderTranslationXKey];
    [sublayer setValue:[NSNumber numberWithDouble:toTranslate.y]  forKey:SwiffRenderTranslationYKey];
    [sublayer setValue:[NSNumber numberWithDouble:newScaleFactor] forKey:SwiffRenderScaleFactorKey];
    
    [CATransaction commit];

    if (m_interpolateCurrentFrame) {
        CAMediaTimingFunction *linear = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        CGFloat duration = 1.0 / [m_movie frameRate];

        void (^animate)(NSString *, NSValue *, NSValue *) = ^(NSString *key, NSValue *from, NSValue *to) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:key];
            [animation setFromValue:from];
            [animation setToValue:to];
            [animation setTimingFunction:linear];
            [animation setDuration:duration];
            [sublayer addAnimation:animation forKey:key];
        };

        if (!CGRectEqualToRect(fromBounds, toBounds)) {
            animate(@"bounds", sGetValueForCGRect(fromBounds), sGetValueForCGRect(toBounds));
        }

        if (fromOpacity != toOpacity) {
            animate(@"opacity", [NSNumber numberWithDouble:fromOpacity], [NSNumber numberWithDouble:toOpacity]);
        }

        if (!CGAffineTransformEqualToTransform(fromTransform, toTransform)) {
            NSValue *from = [NSValue valueWithCATransform3D:CATransform3DMakeAffineTransform(fromTransform)];
            NSValue *to   = [NSValue valueWithCATransform3D:CATransform3DMakeAffineTransform(toTransform)];
            animate(@"transform", from, to);
        }

        if (!CGPointEqualToPoint(fromAnchor, toAnchor)) {
            animate(@"anchorPoint", sGetValueForCGPoint(fromAnchor), sGetValueForCGPoint(toAnchor));
        }
    }
}


- (void) _addSublayersForPlacedObjects:(NSArray *)placedObjects
{
    for (SwiffPlacedObject *placedObject in placedObjects) {
        UInt16 depth = [placedObject depth];
        UInt16 libraryID = [placedObject libraryID];
        
        id<SwiffDefinition> definition = [m_movie definitionWithLibraryID:libraryID];
        CALayer *sublayer = [[CALayer alloc] init];

        CGRect bounds = [definition renderBounds];

        [sublayer setBounds:bounds];
        [sublayer setAnchorPoint:CGPointMake((-bounds.origin.x / bounds.size.width), (-bounds.origin.y / bounds.size.height))];
        [sublayer setContentsScale:[self contentsScale]];
        [sublayer setDelegate:self];
        [sublayer setZPosition:depth];
        [sublayer setNeedsDisplay];
        
        [self _updateGeometryForSublayer:sublayer withPlacedObject:placedObject];

        SwiffLog(@"View", @"adding sublayer at depth %d", (int)depth);
        [self addSublayer:sublayer];

        SwiffSparseArraySetConsumedObjectAtIndex(&m_sublayers, depth, sublayer);
        m_sublayerCount++;
    }
}


- (void) _removeSublayersForPlacedObjects:(NSArray *)placedObjects
{
    for (SwiffPlacedObject *placedObject in placedObjects) {
        UInt16 depth = [placedObject depth];

        CALayer *sublayer = SwiffSparseArrayGetValueAtIndex(&m_sublayers, depth);
        if (!sublayer) return;

        SwiffLog(@"View", @"removing sublayer at depth %d", (int)depth);
        [sublayer removeFromSuperlayer];
        [sublayer release];

        SwiffSparseArraySetValueAtIndex(&self->m_sublayers, depth, nil);
        m_sublayerCount--;
    }
}


- (void) _updateSublayersForPlacedObjects:(NSArray *)placedObjects
{
    for (SwiffPlacedObject *placedObject in placedObjects) {
        UInt16 depth = [placedObject depth];
        CALayer *sublayer = SwiffSparseArrayGetValueAtIndex(&m_sublayers, depth);
        if (!sublayer) continue;

        [self _updateGeometryForSublayer:sublayer withPlacedObject:placedObject];
    }
}


- (void) _invalidatePlacedObjects:(NSArray *)placedObjects
{
    CGRect invalidRect = CGRectZero;

    for (SwiffPlacedObject *placedObject in placedObjects) {
        UInt16 libraryID = [placedObject libraryID];
        id<SwiffDefinition> definition = [m_movie definitionWithLibraryID:libraryID];
        
        CGRect bounds = [definition renderBounds];

        bounds = CGRectApplyAffineTransform(bounds, [placedObject affineTransform]);

        if (CGRectIsEmpty(invalidRect)) {
            invalidRect = bounds;
        } else {
            invalidRect = CGRectUnion(invalidRect, bounds);
        }
    }

    invalidRect = CGRectApplyAffineTransform(invalidRect, m_scaledAffineTransform);
    if (!CGRectIsEmpty(invalidRect)) {
        [m_contentLayer setNeedsDisplayInRect:invalidRect];
    }
}


- (void) _transitionToFrame:(SwiffFrame *)newFrame fromFrame:(SwiffFrame *)oldFrame
{
    SwiffLog(@"View", @"%@ -> %@", oldFrame, newFrame);

    NSEnumerator *oldEnumerator = [[oldFrame placedObjects] objectEnumerator];
    NSEnumerator *newEnumerator = [[newFrame placedObjects] objectEnumerator];
    
    SwiffPlacedObject *oldPlacedObject, *newPlacedObject;
    NSInteger oldDepth, newDepth;
    BOOL oldWantsLayer, newWantsLayer;

    #define NEXT(prefix) { \
        SwiffPlacedObject *o = prefix ## PlacedObject = [prefix ## Enumerator nextObject]; \
        prefix ## Depth        = o ?  o->m_depth : NSIntegerMax; \
        prefix ## WantsLayer   = o ? (o->m_additional && [o wantsLayer]) : NO; \
    }

    NEXT(old);
    NEXT(new);

    BOOL shouldFlatten = m_shouldFlattenSublayersWhenStopped && ![m_playhead isPlaying];

    NSMutableArray *sublayerAdds    = [[NSMutableArray alloc] init];
    NSMutableArray *sublayerRemoves = [[NSMutableArray alloc] init];
    NSMutableArray *sublayerUpdates = [[NSMutableArray alloc] init];
    NSMutableArray *rectInvalidates = [[NSMutableArray alloc] init];

    while ((oldDepth < NSIntegerMax) || (newDepth < NSIntegerMax)) {
        if (oldDepth == newDepth) {
            if (oldPlacedObject != newPlacedObject) {
                if (shouldFlatten) {
                    oldWantsLayer = NO;
                    newWantsLayer = NO;
                }

                if (oldWantsLayer && !SwiffSparseArrayGetValueAtIndex(&m_sublayers, oldDepth)) {
                    oldWantsLayer = NO;
                }
            
                if (oldWantsLayer && newWantsLayer && (oldPlacedObject->m_libraryID == newPlacedObject->m_libraryID)) {
                    [sublayerUpdates addObject:newPlacedObject];

                } else {
                    [(oldWantsLayer ? sublayerRemoves : rectInvalidates) addObject:oldPlacedObject];
                    [(newWantsLayer ? sublayerAdds    : rectInvalidates) addObject:newPlacedObject];
                }
            }

            NEXT(old);
            NEXT(new);
            
        } else if (newDepth < oldDepth) {
            if (shouldFlatten) {
                newWantsLayer = NO;
            }

            [(newWantsLayer ? sublayerAdds : rectInvalidates) addObject:newPlacedObject];

            NEXT(new);

        } else if (oldDepth < newDepth) {
            if (shouldFlatten) {
                oldWantsLayer = NO;
            }

            if (oldWantsLayer && !SwiffSparseArrayGetValueAtIndex(&m_sublayers, oldDepth)) {
                oldWantsLayer = NO;
            }

            [(oldWantsLayer ? sublayerRemoves : rectInvalidates) addObject:oldPlacedObject];

            NEXT(old);
        }
    }
    
    if ([sublayerAdds count] || [sublayerRemoves count]) {
        m_interpolateCurrentFrame = NO;
    }
    
    [self _removeSublayersForPlacedObjects:sublayerRemoves];
    [self _addSublayersForPlacedObjects:sublayerAdds];
    [self _updateSublayersForPlacedObjects:sublayerUpdates];
    [self _invalidatePlacedObjects:rectInvalidates];

    [sublayerRemoves release];
    [sublayerAdds    release];
    [sublayerUpdates release];
    [rectInvalidates release];
}


#pragma mark -
#pragma mark CALayer Overrides / Delegates

- (void) setContentsScale:(CGFloat)contentsScale
{
    [super setContentsScale:contentsScale];
    [m_contentLayer setContentsScale:contentsScale];
}


- (void) setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    CGSize movieSize = [m_movie stageRect].size;

    m_scaledAffineTransform = CGAffineTransformMakeScale(bounds.size.width /  movieSize.width, bounds.size.height / movieSize.height);

    [m_contentLayer setContentsScale:[self contentsScale]];
    [m_contentLayer setFrame:bounds];
    [m_contentLayer setNeedsDisplay];
}


- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    if (layer == m_contentLayer) {
        if (!m_currentFrame) return;

        SwiffFrame *frame = [m_currentFrame retain];

#if WARN_ON_DROPPED_FRAMES        
        clock_t c = clock();
#endif

        NSArray *placedObjects = [frame placedObjects];
        NSMutableArray *filteredObjects = nil;
        
        if (m_sublayerCount) {
            filteredObjects = [[NSMutableArray alloc] initWithCapacity:[placedObjects count]];
            
            for (SwiffPlacedObject *object in placedObjects) {
                if (!object->m_additional || ![object wantsLayer]) {
                    [filteredObjects addObject:object];
                }
            }
        }

        CGContextSaveGState(context);

        SwiffRendererSetBaseAffineTransform(m_renderer, &m_scaledAffineTransform);
        SwiffRendererSetPlacedObjects(m_renderer, filteredObjects ? filteredObjects : placedObjects);
        SwiffRendererRender(m_renderer, context);

        CGContextRestoreGState(context);
        
        [filteredObjects release];

#if WARN_ON_DROPPED_FRAMES        
        double msElapsed = (clock() - c) / (double)(CLOCKS_PER_SEC / 1000);
        if (msElapsed > (1000.0 / 60.0)) {
            SwiffWarn(@"View", @"Rendering took %lf.02 ms", msElapsed);
        }
#endif

        [frame release];

    } else {
        SwiffPlacedObject *layerPlacedObject = [layer valueForKey:SwiffPlacedObjectKey];

        SwiffPlacedObject *rendererPlacedObject = SwiffPlacedObjectCreate(m_movie, [layerPlacedObject libraryID], layerPlacedObject);

        [rendererPlacedObject setAffineTransform:CGAffineTransformIdentity];
        
        SwiffColorTransform colorTransform = [layerPlacedObject colorTransform];
        colorTransform.alphaMultiply = 1.0;
        [rendererPlacedObject setColorTransform:colorTransform];

        NSArray *placedObjects = [[NSArray alloc] initWithObjects:rendererPlacedObject, nil];

        CGContextSaveGState(context);

#if DEBUG_SUBLAYERS
        static int sCounter = 0;
        if      (sCounter == 0) CGContextSetRGBFillColor(context, 1, 0, 0, 0.25);
        else if (sCounter == 1) CGContextSetRGBFillColor(context, 0, 1, 0, 0.25);
        else if (sCounter == 2) CGContextSetRGBFillColor(context, 0, 0, 1, 0.25);
        sCounter = (sCounter + 1) % 3;

        CGContextFillRect(context, [layer bounds]);
#endif

        // At this point, our graphics state has an affine transform based on the layer's 
        // bounds and contentsScale
        //
        // For proper hairline support, we handle all transformations in SwiffRender()
        //
        // Save the CTM, reset the CTM to Identity, then pass the old CTM as the base
        // transform of SwiffRender()
        //
        CGAffineTransform base = CGContextGetCTM(context);
        CGAffineTransform orig = base;

//      CGContextSetCTM() is private, so immitate it with concatenation
        CGContextConcatCTM(context, CGAffineTransformInvert(base)); // CGContextSetCTM(context, CGAffineTransformIdentity)

        CGFloat renderTranslationX = [[layer valueForKey:SwiffRenderTranslationXKey] doubleValue];
        CGFloat renderTranslationY = [[layer valueForKey:SwiffRenderTranslationYKey] doubleValue];
        CGFloat renderScaleFactor  = [[layer valueForKey:SwiffRenderScaleFactorKey]  doubleValue];
        
        base = CGAffineTransformConcat(CGAffineTransformMakeTranslation(renderTranslationX, renderTranslationY), base);
        base = CGAffineTransformConcat(CGAffineTransformMakeScale(renderScaleFactor, renderScaleFactor), base);
                
        if (SwiffShouldLog(@"View")) {
            SwiffLog(@"View", @"Rendering sublayer %d\n"
                @" orig: %lf,%lf,%lf,%lf %lf,%lf\n"
                @" base: %lf,%lf,%lf,%lf %lf,%lf\n",
                (int)[layerPlacedObject depth],
                (double)orig.a, (double)orig.b, (double)orig.c, (double)orig.d, (double)orig.tx, (double)orig.ty,
                (double)base.a, (double)base.b, (double)base.c, (double)base.d, (double)base.tx, (double)base.ty
            );
        }

        SwiffRendererSetBaseAffineTransform(m_renderer, &base);
        SwiffRendererSetPlacedObjects(m_renderer, placedObjects);
        SwiffRendererRender(m_renderer, context);

        CGContextRestoreGState(context);

        [placedObjects release];
        [rendererPlacedObject release];
    }
}


- (id<CAAction>) actionForKey:(NSString *)event
{
    return nil;
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    CAAnimation *existingAnimation = nil;

    if (layer != m_contentLayer) return nil;

    if ([m_delegate isKindOfClass:[SwiffView class]]) {
        CALayer *master = [(SwiffView *)m_delegate layer];
        
         if (!existingAnimation) existingAnimation = [master animationForKey:@"bounds"];
         if (!existingAnimation) existingAnimation = [master animationForKey:@"position"];
    }

    if (existingAnimation || m_interpolateCurrentFrame) {
        CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:event];

        if (existingAnimation) {
            [basicAnimation setDuration:[existingAnimation duration]];
            [basicAnimation setTimingFunction:[existingAnimation timingFunction]];

        } else {
            [basicAnimation setDuration:(1.0 / [m_movie frameRate])];
        }

        return basicAnimation;

    } else {
        return (id)[NSNull null];
    }
}


#pragma mark -
#pragma mark Playhead Delegate

- (void) playheadDidUpdate:(SwiffPlayhead *)playhead
{
    SwiffFrame *frame = [playhead frame];

    if ([playhead isPlaying]) {
        [[SwiffSoundPlayer sharedInstance] processMovie:m_movie frame:frame];
    }

    if (frame != m_currentFrame) {
        [m_delegate layer:self willUpdateCurrentFrame:frame];

        m_interpolateCurrentFrame = [m_delegate layer:self shouldInterpolateFromFrame:m_currentFrame toFrame:frame];

        SwiffFrame *oldFrame = m_currentFrame;
        m_currentFrame = [frame retain];

        [self _transitionToFrame:frame fromFrame:oldFrame];
        [oldFrame release];

        [m_delegate layer:self didUpdateCurrentFrame:m_currentFrame];

    } else {
        m_interpolateCurrentFrame = NO;
        [self redisplay];
    }
}


#pragma mark -
#pragma mark Public Methods

- (void) redisplay
{
    [m_contentLayer setNeedsDisplay];

    SwiffSparseArrayEnumerateValues(&m_sublayers, ^(void *value) {
        CALayer *layer = value;
        [layer removeFromSuperlayer];
        [layer release];
    });
    
    SwiffSparseArrayFree(&m_sublayers);
    m_sublayerCount = 0;

    [self _transitionToFrame:m_currentFrame fromFrame:nil];
}


#pragma mark -
#pragma mark Accessors

- (void) setSwiffLayerDelegate:(id<SwiffLayerDelegate>)delegate
{
    if (m_delegate != delegate) {
        m_delegate = delegate;
    }
}


- (void) setDrawsBackground:(BOOL)drawsBackground
{
    if (m_drawsBackground != drawsBackground) {
        if (drawsBackground) {
            SwiffColor *backgroundColorPointer = [[self movie] backgroundColorPointer];

            CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
            CGColorRef color = CGColorCreate(rgb, (CGFloat *)backgroundColorPointer); 
        
            [self setBackgroundColor:color];

            if (color) CFRelease(color);
            if (rgb)   CFRelease(rgb);

        } else {
            [self setBackgroundColor:NULL];
        }

        m_drawsBackground = drawsBackground;
    }
}


- (void) setMultiplyColor:(SwiffColor *)color
{
    SwiffRendererSetMultiplyColor(m_renderer, color);
}



- (void) setHairlineWidth:(CGFloat)width
{
    if (width != SwiffRendererGetHairlineWidth(m_renderer)) {
        SwiffRendererSetHairlineWidth(m_renderer, width);
        [self redisplay];
    }
}


- (void) setFillHairlineWidth:(CGFloat)width
{
    if (width != SwiffRendererGetFillHairlineWidth(m_renderer)) {
        SwiffRendererSetFillHairlineWidth(m_renderer, width);
        [self redisplay];
    }
}


- (void) setShouldAntialias:(BOOL)yn
{
    if (yn != SwiffRendererGetShouldAntialias(m_renderer)) {
        SwiffRendererSetShouldAntialias(m_renderer, yn);
        [self redisplay];
    }
}


- (void) setShouldSmoothFonts:(BOOL)yn
{
    if (yn != SwiffRendererGetShouldSmoothFonts(m_renderer)) {
        SwiffRendererSetShouldSmoothFonts(m_renderer, yn);
        [self redisplay];
    }
}


- (void) setShouldSubpixelPositionFonts:(BOOL)yn
{
    if (yn != SwiffRendererGetShouldSubpixelPositionFonts(m_renderer)) {
        SwiffRendererSetShouldSubpixelPositionFonts(m_renderer, yn);
        [self redisplay];
    }
}


- (void) setShouldSubpixelQuantizeFonts:(BOOL)yn
{
    if (yn != SwiffRendererGetShouldSubpixelQuantizeFonts(m_renderer)) {
        SwiffRendererSetShouldSubpixelQuantizeFonts(m_renderer, yn);
        [self redisplay];
    }
}


- (SwiffColor *) multiplyColor          { return SwiffRendererGetMultiplyColor(m_renderer);               }
- (CGFloat) hairlineWidth               { return SwiffRendererGetHairlineWidth(m_renderer);               }
- (CGFloat) fillHairlineWidth           { return SwiffRendererGetFillHairlineWidth(m_renderer);           }
- (BOOL)    shouldAntialias             { return SwiffRendererGetShouldAntialias(m_renderer);             }
- (BOOL)    shouldSmoothFonts           { return SwiffRendererGetShouldSmoothFonts(m_renderer);           }
- (BOOL)    shouldSubpixelPositionFonts { return SwiffRendererGetShouldSubpixelPositionFonts(m_renderer); }
- (BOOL)    shouldSubpixelQuantizeFonts { return SwiffRendererGetShouldSubpixelQuantizeFonts(m_renderer); }

@synthesize swiffLayerDelegate  = m_delegate,
            movie               = m_movie,
            playhead            = m_playhead,
            currentFrame        = m_currentFrame,
            drawsBackground     = m_drawsBackground,
            shouldFlattenSublayersWhenStopped = m_shouldFlattenSublayersWhenStopped;

@end
