/*
    SwiffSpriteLayer.m
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

#import "SwiffLayer.h"

#import "SwiffFrame.h"
#import "SwiffMovie.h"
#import "SwiffPlacedObject.h"
#import "SwiffPlayhead.h"
#import "SwiffRenderer.h"
#import "SwiffSoundPlayer.h"
#import "SwiffSparseArray.h"
#import "SwiffUtils.h"
#import "SwiffView.h"

#define DEBUG_SUBLAYERS 1
#define WARN_ON_DROPPED_FRAMES 0

static NSString * const SwiffPlacedObjectKey       = @"SwiffPlacedObject";        // SwiffPlacedObject
static NSString * const SwiffRenderScaleFactorKey  = @"SwiffRenderScaleFactor";   // NSNumber<CGFloat>
static NSString * const SwiffRenderTranslationXKey = @"SwiffRenderTranslationX";  // NSNumber<CGFloat>
static NSString * const SwiffRenderTranslationYKey = @"SwiffRenderTranslationY";  // NSNumber<CGFloat>

@interface SwiffLayer ()  <SwiffPlayheadDelegate>
@end


@implementation SwiffLayer {
    SwiffRenderer     *_renderer;
    SwiffSparseArray  *_sublayers;
    CALayer           *_contentLayer;
    NSUInteger         _sublayerCount;
    CGFloat            _scaleFactor;
    CGAffineTransform  _baseAffineTransform;
    CGAffineTransform  _scaledAffineTransform;
    BOOL               _interpolateCurrentFrame;
}

@dynamic colorModificationBlock;
@synthesize swiffLayerDelegate = _delegate;


- (id) init
{
    return [self initWithMovie:nil];
}


- (id) initWithMovie:(SwiffMovie *)movie
{
    if ((self = [super init])) {
        if (!movie) {
            SwiffWarn(@"View", @"-[SwiffLayer initWithMovie:] called with nil movie)");
        }

        _movie = movie;

        _renderer = movie ? [[SwiffRenderer alloc] initWithMovie:movie] : nil;
        
        _contentLayer = [[CALayer alloc] init];
        [_contentLayer setDelegate:self];
        [self addSublayer:_contentLayer];

        _playhead = movie ? [[SwiffPlayhead alloc] initWithMovie:movie delegate:self] : nil;
        [_playhead gotoFrameWithIndex:0 play:NO];
        
        [_contentLayer setNeedsDisplay];
    }
    
    return self;
}


- (void) dealloc
{
    [[SwiffSoundPlayer sharedInstance] stopAllSoundsForMovie:_movie];

    [_playhead invalidateTimers];
    [_playhead setDelegate:nil];
}


- (void) clearWeakReferences
{
    [_contentLayer setDelegate:nil];
}


#pragma mark -
#pragma mark Sublayers & Transitions

static CGRect sExpandRect(CGRect rect)
{
    CGFloat minX = CGRectGetMinX(rect);
    CGFloat minY = CGRectGetMinY(rect);
    CGFloat maxX = CGRectGetMaxX(rect);
    CGFloat maxY = CGRectGetMaxY(rect);

    minX = SwiffFloor(minX);
    minY = SwiffFloor(minY);
    maxX = SwiffCeil( maxX);
    maxY = SwiffCeil( maxY);

    return CGRectMake(minX, minY, (maxX - minX), (maxY - minY));
}


static BOOL sShouldUseSameLayer(SwiffPlacedObject *a, SwiffPlacedObject *b)
{
    // Return NO if the library IDs are not equal
    if (a->_libraryID != b->_libraryID) {
        return NO;
    }
    
    NSString *aIdentifier = [a layerIdentifier];
    NSString *bIdentifier = [b layerIdentifier];

    // Return NO if only one identifier is nil
    if (!aIdentifier ^ !bIdentifier) {
        return NO;
    }

    return (!aIdentifier && !bIdentifier) || ([aIdentifier isEqualToString:bIdentifier]);
}


- (void) _calculateGeometryForPlacedObject: (SwiffPlacedObject *) placedObject 
                               scaleFactor: (CGFloat) scaleFactor
                                 outBounds: (CGRect *) outBounds
                              outTransform: (CGAffineTransform *) outTransform
                              outTranslate: (CGPoint *) outTranslate
{
    id<SwiffDefinition> definition = [_movie definitionWithLibraryID:[placedObject libraryID]];

    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformConcat(transform, [placedObject affineTransform]);
    transform = CGAffineTransformConcat(transform, _scaledAffineTransform);
    
    CGAffineTransform scaleFactorTransform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);

    CGRect bounds = [definition renderBounds];
    bounds = sExpandRect(CGRectApplyAffineTransform(bounds, scaleFactorTransform));
    transform = CGAffineTransformConcat(CGAffineTransformInvert(scaleFactorTransform), transform);

    CGPoint translate = CGPointZero;

    // If we aren't skewing/rotating, use additional tweak to draw crisp lines
    //
    if (outTranslate && (transform.b == 0) && (transform.c == 0)) {
        CGFloat tx = transform.tx / transform.a;
        CGFloat ty = transform.ty / transform.d;
        
        transform.tx = SwiffFloor(tx);
        transform.ty = SwiffFloor(ty);

        translate = CGPointMake((tx - transform.tx), (ty - transform.ty));
        
        transform.tx *= transform.a;
        transform.ty *= transform.d;
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


- (CGFloat) _scaleFactorForPlacedObject:(SwiffPlacedObject *)placedObject hairlineWidth:(CGFloat)hairlineWidth
{
    CGAffineTransform t = CGAffineTransformIdentity;
    t = CGAffineTransformConcat(t, [placedObject affineTransform]);

    // Take a 1x1 square at (0,0) and apply the transform to it.
    //
    CGPoint topLeftPoint     = CGPointApplyAffineTransform(CGPointMake(0, 0), t);
    CGPoint topRightPoint    = CGPointApplyAffineTransform(CGPointMake(1, 0), t);
    CGPoint bottomLeftPoint  = CGPointApplyAffineTransform(CGPointMake(0, 1), t);
    CGPoint bottomRightPoint = CGPointApplyAffineTransform(CGPointMake(1, 1), t);

    // Next, use the distance formula to find the length of each side
    //
    CGFloat topLineLength    = SwiffGetDistance(topLeftPoint,    topRightPoint);
    CGFloat bottomLineLength = SwiffGetDistance(bottomLeftPoint, bottomRightPoint);
    CGFloat leftLineLength   = SwiffGetDistance(topLeftPoint,    bottomLeftPoint);
    CGFloat rightLineLength  = SwiffGetDistance(topRightPoint,   bottomRightPoint);

    // Finally, return the ceil of the maximum length
    //
    CGFloat max1 = MAX(topLineLength,  bottomLineLength);
    CGFloat max2 = MAX(leftLineLength, rightLineLength);
    CGFloat max3 = MAX(max1, max2);

    CGFloat contentsScale = [self contentsScale];
    return SwiffScaleCeil(max3, 1) * (contentsScale * _scaleFactor);
}


- (void) _updateGeometryForSublayer:(CALayer *)sublayer withPlacedObject:(SwiffPlacedObject *)placedObject
{
    SwiffPlacedObject *oldPlacedObject = [sublayer valueForKey:SwiffPlacedObjectKey];
    if (!oldPlacedObject) oldPlacedObject = placedObject;
    
    CGFloat oldScaleFactor = [[sublayer valueForKey:SwiffRenderScaleFactorKey] doubleValue];
    CGFloat newScaleFactor = [self _scaleFactorForPlacedObject:placedObject hairlineWidth:[self hairlineWidth]];

    CGAffineTransform fromTransform = [sublayer affineTransform];
    CGRect            fromBounds    = [sublayer bounds];
    CGPoint           fromAnchor    = [sublayer anchorPoint];
    CGFloat           fromOpacity   = [sublayer opacity];
    CGAffineTransform toTransform;
    CGRect            toBounds;
    CGPoint           toAnchor;
    CGFloat           toOpacity     = 1.0;
    
    BOOL needsDisplayForScaleFactor    = NO;
    BOOL needsDisplayForColorTransform = NO;
    

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
        
        needsDisplayForScaleFactor = YES;
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
            needsDisplayForColorTransform = YES;
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

    CALayer *masterLayer = nil;
    if ([_delegate isKindOfClass:[SwiffView class]]) {
        masterLayer = [(SwiffView *)_delegate layer];
    }

    CAAnimation *existingAnimation = nil;
    if (!existingAnimation) existingAnimation = [masterLayer animationForKey:@"bounds"];
    if (!existingAnimation) existingAnimation = [masterLayer animationForKey:@"position"];

    if (!existingAnimation && needsDisplayForScaleFactor) {
        [CATransaction flush];

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [CATransaction setAnimationDuration:0];

        // Old placed object but new scale factor
        [sublayer setValue:oldPlacedObject forKey:SwiffPlacedObjectKey];
        [sublayer setValue:@(newScaleFactor) forKey:SwiffRenderScaleFactorKey];
        [sublayer setValue:@(toTranslate.x)  forKey:SwiffRenderTranslationXKey];
        [sublayer setValue:@(toTranslate.y)  forKey:SwiffRenderTranslationYKey];

        [sublayer setBounds:fromBounds];
        [sublayer setAffineTransform:fromTransform];
        [sublayer setAnchorPoint:fromAnchor];
        [sublayer setOpacity:fromOpacity];

        [sublayer setNeedsDisplay];
        [sublayer displayIfNeeded];

        [CATransaction commit];
    }

    [sublayer setGeometryFlipped:NO];
    [self addSublayer:sublayer];

    [CATransaction begin];
    if (_interpolateCurrentFrame || existingAnimation) {
        [CATransaction setAnimationDuration:existingAnimation ? [existingAnimation duration] : (1.0 / [_movie frameRate])];
        [CATransaction setAnimationTimingFunction:existingAnimation ? [existingAnimation timingFunction] : [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    } else {
        [CATransaction setDisableActions:YES];
        [CATransaction setAnimationDuration:0];
    }
    {
        [sublayer setValue:placedObject forKey:SwiffPlacedObjectKey];
        [sublayer setValue:@(newScaleFactor) forKey:SwiffRenderScaleFactorKey];
        [sublayer setValue:@(toTranslate.x)  forKey:SwiffRenderTranslationXKey];
        [sublayer setValue:@(toTranslate.y)  forKey:SwiffRenderTranslationYKey];

        [sublayer setBounds:toBounds];
        [sublayer setAnchorPoint:toAnchor];
        [sublayer setAffineTransform:toTransform];
        [sublayer setOpacity:toOpacity];

        if (existingAnimation || needsDisplayForColorTransform) {
            [sublayer setNeedsDisplay];
            [sublayer displayIfNeeded];
        }
    }
    [CATransaction commit];
}


- (void) _addSublayersForPlacedObjects:(NSArray *)placedObjects
{
    for (SwiffPlacedObject *placedObject in placedObjects) {
        UInt16 depth = [placedObject depth];
        UInt16 libraryID = [placedObject libraryID];
        
        id<SwiffDefinition> definition = [_movie definitionWithLibraryID:libraryID];
        CALayer *sublayer = [CALayer layer];

        CGRect bounds = [definition renderBounds];

        [sublayer setBounds:bounds];
        [sublayer setAnchorPoint:CGPointMake((-bounds.origin.x / bounds.size.width), (-bounds.origin.y / bounds.size.height))];
        [sublayer setContentsScale:1];
        [sublayer setDelegate:self];
        [sublayer setZPosition:depth];
        [sublayer setNeedsDisplay];

        // Toggle geometry flipped flag until [self addSublayer:sublayer] in _updateGeometryForSublayer:withPlacedObject:
        if ([sublayer contentsAreFlipped] != [self contentsAreFlipped]) {
            [sublayer setGeometryFlipped:YES];
        }

        SwiffLog(@"View", @"adding sublayer at depth %d", (int)depth);

        if (!_sublayers) {
            _sublayers = [[SwiffSparseArray alloc] init];
        }

        CALayer *existing = SwiffSparseArrayGetObjectAtIndex(_sublayers, depth);
        if (existing) {
            [existing removeFromSuperlayer];
        } else {
            _sublayerCount++;
        }

        SwiffSparseArraySetObjectAtIndex(_sublayers, depth, sublayer);
    }
}


- (void) _removeSublayersForPlacedObjects:(NSArray *)placedObjects
{
    for (SwiffPlacedObject *placedObject in placedObjects) {
        UInt16 depth = [placedObject depth];

        CALayer *sublayer = SwiffSparseArrayGetObjectAtIndex(_sublayers, depth);
        if (!sublayer) continue;

        SwiffLog(@"View", @"removing sublayer at depth %d", (int)depth);
        [sublayer removeFromSuperlayer];

        SwiffSparseArraySetObjectAtIndex(_sublayers, depth, nil);
        _sublayerCount--;
    }
}


- (void) _updateSublayersForPlacedObjects:(NSArray *)placedObjects
{
    for (SwiffPlacedObject *placedObject in placedObjects) {
        UInt16 depth = [placedObject depth];

        CALayer *sublayer = SwiffSparseArrayGetObjectAtIndex(_sublayers, depth);
        if (!sublayer) continue;

        [self _updateGeometryForSublayer:sublayer withPlacedObject:placedObject];
    }
}


- (void) _invalidatePlacedObjects:(NSArray *)placedObjects
{
    CGRect invalidRect = CGRectZero;

    for (SwiffPlacedObject *placedObject in placedObjects) {
        UInt16 libraryID = [placedObject libraryID];
        id<SwiffDefinition> definition = [_movie definitionWithLibraryID:libraryID];
        
        CGRect bounds = [definition renderBounds];
        bounds = CGRectApplyAffineTransform(bounds, [placedObject affineTransform]);

        if (CGRectIsEmpty(invalidRect)) {
            invalidRect = bounds;
        } else {
            invalidRect = CGRectUnion(invalidRect, bounds);
        }
    }

    invalidRect = CGRectApplyAffineTransform(invalidRect, _scaledAffineTransform);
    if (!CGRectIsEmpty(invalidRect)) {
        [_contentLayer setNeedsDisplayInRect:invalidRect];
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
        prefix ## Depth        = o ?  o->_depth : NSIntegerMax; \
        prefix ## WantsLayer   = o ? (o->_additional && [o wantsLayer]) : NO; \
    }

    NEXT(old);
    NEXT(new);

    NSMutableArray *sublayerAdds    = [[NSMutableArray alloc] init];
    NSMutableArray *sublayerRemoves = [[NSMutableArray alloc] init];
    NSMutableArray *sublayerUpdates = [[NSMutableArray alloc] init];
    NSMutableArray *rectInvalidates = [[NSMutableArray alloc] init];

    while ((oldDepth < NSIntegerMax) || (newDepth < NSIntegerMax)) {
        if (oldDepth == newDepth) {
            if (oldPlacedObject != newPlacedObject) {
                if (_shouldFlattenSublayers) {
                    oldWantsLayer = NO;
                    newWantsLayer = NO;
                }

                if (oldWantsLayer && !SwiffSparseArrayGetObjectAtIndex(_sublayers, oldDepth)) {
                    oldWantsLayer = NO;
                }
            
                if (oldWantsLayer && newWantsLayer && sShouldUseSameLayer(oldPlacedObject, newPlacedObject)) { 
                    [sublayerUpdates addObject:newPlacedObject];

                } else {
                    [(oldWantsLayer ? sublayerRemoves : rectInvalidates) addObject:oldPlacedObject];
                    [(newWantsLayer ? sublayerAdds    : rectInvalidates) addObject:newPlacedObject];
                }
            }

            NEXT(old);
            NEXT(new);
            
        } else if (newDepth < oldDepth) {
            if (_shouldFlattenSublayers) {
                newWantsLayer = NO;
            }

            [(newWantsLayer ? sublayerAdds : rectInvalidates) addObject:newPlacedObject];

            NEXT(new);

        } else if (oldDepth < newDepth) {
            if (_shouldFlattenSublayers) {
                oldWantsLayer = NO;
            }

            if (oldWantsLayer && !SwiffSparseArrayGetObjectAtIndex(_sublayers, oldDepth)) {
                oldWantsLayer = NO;
            }

            [(oldWantsLayer ? sublayerRemoves : rectInvalidates) addObject:oldPlacedObject];

            NEXT(old);
        }
    }
    
    if ([sublayerAdds count] || [sublayerRemoves count]) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [CATransaction setAnimationDuration:0];

        [self _removeSublayersForPlacedObjects:sublayerRemoves];
        [self _addSublayersForPlacedObjects:sublayerAdds];
        [self _updateSublayersForPlacedObjects:sublayerAdds];

        [self _invalidatePlacedObjects:rectInvalidates];
        
        [_contentLayer displayIfNeeded];

        [CATransaction commit];

    } else {
        [self _invalidatePlacedObjects:rectInvalidates];
    }
    
    [self _updateSublayersForPlacedObjects:sublayerUpdates];
}


#pragma mark -
#pragma mark CALayer Overrides / Delegates

- (void) setContentsScale:(CGFloat)contentsScale
{
    [super setContentsScale:contentsScale];
    [_contentLayer setContentsScale:contentsScale];
}


- (void) setBounds:(CGRect)bounds
{
    CGRect oldBounds = [self bounds];

    [super setBounds:bounds];

    CGSize movieSize = [_movie stageRect].size;

    CGFloat sx = bounds.size.width /  movieSize.width;
    CGFloat sy = bounds.size.height / movieSize.height;

    _scaleFactor = sx > sy ? sx : sy;
    _scaledAffineTransform = CGAffineTransformMakeScale(sx, sy);

    [_contentLayer setContentsScale:[self contentsScale]];
    [_contentLayer setFrame:bounds];

    if (!CGSizeEqualToSize(oldBounds.size, bounds.size)) {
        [_contentLayer setNeedsDisplay];
        
        for (CALayer *sublayer in _sublayers) {
            SwiffPlacedObject *placedObject = [sublayer valueForKey:SwiffPlacedObjectKey];
            if (placedObject) {
                [self _updateGeometryForSublayer:sublayer withPlacedObject:placedObject];
            }
        };
    }
}


- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    if (layer == _contentLayer) {
        if (!_currentFrame) return;

        SwiffFrame *frame = _currentFrame;

#if WARN_ON_DROPPED_FRAMES        
        clock_t c = clock();
#endif

        NSArray *placedObjects = [frame placedObjects];
        NSMutableArray *filteredObjects = nil;
        
        if (_sublayerCount) {
            filteredObjects = [[NSMutableArray alloc] initWithCapacity:[placedObjects count]];
            
            for (SwiffPlacedObject *object in placedObjects) {
                UInt16 depth = object->_depth;
                if (!SwiffSparseArrayGetObjectAtIndex(_sublayers, depth)) {
                    [filteredObjects addObject:object];
                }
            }
        }

        CGContextSaveGState(context);

        if (_shouldDrawDebugColors) {
            static int sCounter = 0;
            if      (sCounter == 0) CGContextSetRGBFillColor(context, 1, 1, 0, 0.15);
            else if (sCounter == 1) CGContextSetRGBFillColor(context, 0, 1, 1, 0.15);
            else if (sCounter == 2) CGContextSetRGBFillColor(context, 1, 0, 1, 0.15);
            sCounter = (sCounter + 1) % 3;

            CGContextFillRect(context, [layer bounds]);
        }

        [_renderer setScaleFactorHint:[self contentsScale]];
        [_renderer setBaseAffineTransform:&_scaledAffineTransform];
        [_renderer renderPlacedObjects:(filteredObjects ? filteredObjects : placedObjects) inContext:context];

        CGContextRestoreGState(context);
        

#if WARN_ON_DROPPED_FRAMES        
        double msElapsed = (clock() - c) / (double)(CLOCKS_PER_SEC / 1000);
        if (msElapsed > (1000.0 / 60.0)) {
            SwiffWarn(@"View", @"Rendering took %lf.02 ms", msElapsed);
        }
#endif


    } else {
        SwiffPlacedObject *layerPlacedObject = [layer valueForKey:SwiffPlacedObjectKey];

        SwiffPlacedObject *rendererPlacedObject = SwiffPlacedObjectCreate(_movie, [layerPlacedObject libraryID], layerPlacedObject);

        [rendererPlacedObject setAffineTransform:CGAffineTransformIdentity];
        
        SwiffColorTransform colorTransform = [layerPlacedObject colorTransform];
        colorTransform.alphaMultiply = 1.0;
        [rendererPlacedObject setColorTransform:colorTransform];

        NSArray *placedObjects = [[NSArray alloc] initWithObjects:rendererPlacedObject, nil];

        CGContextSaveGState(context);

        if (_shouldDrawDebugColors) {
            static int sCounter = 0;
            if      (sCounter == 0) CGContextSetRGBFillColor(context, 1, 0, 0, 0.35);
            else if (sCounter == 1) CGContextSetRGBFillColor(context, 0, 1, 0, 0.35);
            else if (sCounter == 2) CGContextSetRGBFillColor(context, 0, 0, 1, 0.35);
            sCounter = (sCounter + 1) % 3;

            CGContextFillRect(context, [layer bounds]);
        }

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

        CGFloat hairlineWidth     = [_renderer hairlineWidth];
        CGFloat fillHairlineWidth = [_renderer fillHairlineWidth];

        CGFloat contentsScale = [self contentsScale];

        [_renderer setHairlineWidth:(hairlineWidth * contentsScale)];
        [_renderer setFillHairlineWidth:(fillHairlineWidth * contentsScale)];
        [_renderer setScaleFactorHint:1.0];
        [_renderer setBaseAffineTransform:&base];

        [_renderer renderPlacedObjects:placedObjects inContext:context];

        [_renderer setHairlineWidth:hairlineWidth];
        [_renderer setFillHairlineWidth:fillHairlineWidth];
        
        CGContextRestoreGState(context);
    }
}


- (id<CAAction>) actionForKey:(NSString *)event
{
    return nil;
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    CAAnimation *existingAnimation = nil;

    if (layer != _contentLayer) {
        if ([event hasPrefix:@"Swiff"]) {
            return (id)[NSNull null];
        }
    }
    
    if ([_delegate isKindOfClass:[SwiffView class]]) {
        CALayer *master = [(SwiffView *)_delegate layer];
        
         if (!existingAnimation) existingAnimation = [master animationForKey:@"bounds"];
         if (!existingAnimation) existingAnimation = [master animationForKey:@"position"];
    }

    if (existingAnimation || _interpolateCurrentFrame) {
        CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:event];

        if (existingAnimation) {
            [basicAnimation setDuration:[existingAnimation duration]];
            [basicAnimation setTimingFunction:[existingAnimation timingFunction]];

        } else {
            [basicAnimation setDuration:(1.0 / [_movie frameRate])];
        }

        return basicAnimation;

    } else {
        return (id)[NSNull null];
    }
}


#pragma mark -
#pragma mark Playhead Delegate

- (void) playheadDidUpdate:(SwiffPlayhead *)playhead step:(BOOL)step
{
    SwiffFrame *frame = [playhead frame];

    if (!([playhead isPlaying] && step)) {
        [[SwiffSoundPlayer sharedInstance] stopStream];
    }

    if ([playhead isPlaying]) {
        [[SwiffSoundPlayer sharedInstance] processMovie:_movie frame:frame];
    }

    if (frame != _currentFrame) {
        [_delegate layer:self willUpdateCurrentFrame:frame];

        _interpolateCurrentFrame = [_delegate layer:self shouldInterpolateFromFrame:_currentFrame toFrame:frame];

        SwiffFrame *oldFrame = _currentFrame;
        _currentFrame = frame;

        [self _transitionToFrame:frame fromFrame:oldFrame];

        [_delegate layer:self didUpdateCurrentFrame:_currentFrame];
    }
}


#pragma mark -
#pragma mark Public Methods

- (void) redisplay
{
    for (CALayer *layer in _sublayers) {
        [layer removeFromSuperlayer];
    };
    
    _sublayers = nil;
    _sublayerCount = 0;

    [self _transitionToFrame:_currentFrame fromFrame:nil];
    [_contentLayer setNeedsDisplay];
}


- (void) _setNeedsRedisplay
{
    [_contentLayer setNeedsDisplay];

    for (CALayer *layer in _sublayers) {
        [layer setNeedsDisplay];
    };
}


#pragma mark -
#pragma mark Accessors

- (void) setSwiffLayerDelegate:(id<SwiffLayerDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;
    }
}


- (void) setDrawsBackground:(BOOL)drawsBackground
{
    if (_drawsBackground != drawsBackground) {
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

        _drawsBackground = drawsBackground;
    }
}


- (void) setColorModificationBlock:(SwiffColorModificationBlock)block
{
    [_renderer setColorModificationBlock:block];
    [self _setNeedsRedisplay];
}


- (void) setHairlineWidth:(CGFloat)width
{
    if (width != [_renderer hairlineWidth]) {
        [_renderer setHairlineWidth:width];
        [self _setNeedsRedisplay];
    }
}


- (void) setFillHairlineWidth:(CGFloat)width
{
    if (width != [_renderer fillHairlineWidth]) {
        [_renderer setFillHairlineWidth:width];
        [self _setNeedsRedisplay];
    }
}


- (void) setShouldAntialias:(BOOL)yn
{
    if (yn != [_renderer shouldAntialias]) {
        [_renderer setShouldAntialias:yn];
        [self _setNeedsRedisplay];
    }
}


- (void) setShouldSmoothFonts:(BOOL)yn
{
    if (yn != [_renderer shouldSmoothFonts]) {
        [_renderer setShouldSmoothFonts:yn];
        [self _setNeedsRedisplay];
    }
}


- (void) setShouldSubpixelPositionFonts:(BOOL)yn
{
    if (yn != [_renderer shouldSubpixelPositionFonts]) {
        [_renderer setShouldSubpixelPositionFonts:yn];
        [self _setNeedsRedisplay];
    }
}


- (void) setShouldSubpixelQuantizeFonts:(BOOL)yn
{
    if (yn != [_renderer shouldSubpixelQuantizeFonts]) {
        [_renderer setShouldSubpixelQuantizeFonts:yn];
        [self _setNeedsRedisplay];
    }
}


- (void) setShouldFlattenSublayers:(BOOL)shouldFlattenSublayers
{
    if (shouldFlattenSublayers != _shouldFlattenSublayers) {
        _shouldFlattenSublayers  = shouldFlattenSublayers;
        [self _setNeedsRedisplay];
    }
}


- (SwiffColorModificationBlock) colorModificationBlock
{
    return [_renderer colorModificationBlock];
}


- (CGFloat) hairlineWidth               { return [_renderer hairlineWidth];               }
- (CGFloat) fillHairlineWidth           { return [_renderer fillHairlineWidth];           }
- (BOOL)    shouldAntialias             { return [_renderer shouldAntialias];             }
- (BOOL)    shouldSmoothFonts           { return [_renderer shouldSmoothFonts];           }
- (BOOL)    shouldSubpixelPositionFonts { return [_renderer shouldSubpixelPositionFonts]; }
- (BOOL)    shouldSubpixelQuantizeFonts { return [_renderer shouldSubpixelQuantizeFonts]; }

@end
