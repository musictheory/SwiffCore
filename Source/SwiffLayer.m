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

#define DEBUG_SUBLAYERS 0

static NSString * const SwiffLibraryIDKey    = @"SwiffLibraryID";
static NSString * const SwiffPlacedObjectKey = @"SwiffPlacedObject";
static NSString * const SwiffScaleFactorXKey = @"SwiffScaleFactorX";
static NSString * const SwiffScaleFactorYKey = @"SwiffScaleFactorY";


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
        [self setCurrentFrame:[m_playhead frame]];
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

    if (m_depthToSublayerMap) {
        CFRelease(m_depthToSublayerMap);
        m_depthToSublayerMap = NULL;
    }

    [super dealloc];
}


- (void) clearWeakReferences
{
    [m_contentLayer setDelegate:nil];
}


#pragma mark -
#pragma mark Sublayer Logic

static CGFloat sGetDistance(CGPoint p1, CGPoint p2)
{
#if defined(CGFLOAT_IS_DOUBLE) && CGFLOAT_IS_DOUBLE
    return sqrt(pow(p2.x - p1.x, 2.0) + pow(p2.y - p1.y, 2.0));
#else
    return sqrtf(powf(p2.x - p1.x, 2.0f) + powf(p2.y - p1.y, 2.0f));
#endif
}


static CGSize sGetNeededScaleForTransform(CGAffineTransform t)
{
    CGPoint topLeft     = CGPointApplyAffineTransform(CGPointMake(0, 0), t);
    CGPoint topRight    = CGPointApplyAffineTransform(CGPointMake(1, 0), t);
    CGPoint bottomLeft  = CGPointApplyAffineTransform(CGPointMake(0, 1), t);
    CGPoint bottomRight = CGPointApplyAffineTransform(CGPointMake(1, 1), t);

    CGFloat topWidth    = sGetDistance(topLeft,    topRight);
    CGFloat bottomWidth = sGetDistance(bottomLeft, bottomRight);
    CGFloat leftHeight  = sGetDistance(topLeft,    bottomLeft);
    CGFloat rightHeight = sGetDistance(topRight,   bottomRight);

    return CGSizeMake(
        topWidth   > bottomWidth ? topWidth   : bottomWidth,
        leftHeight > rightHeight ? leftHeight : rightHeight
    );
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


static void sUpdateSublayerWithPlacedObject(SwiffLayer *self, CALayer *sublayer, SwiffPlacedObject *placedObject)
{
    if (!placedObject) return;

    [sublayer setValue:placedObject forKey:SwiffPlacedObjectKey];

    id<SwiffDefinition> definition = [self->m_movie definitionWithLibraryID:placedObject->m_libraryID];
    
    // Handle placement
    //
    {
        CGRect oldBounds = [sublayer bounds];

        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformConcat(transform, [placedObject affineTransform]);
        transform = CGAffineTransformConcat(transform, self->m_scaledAffineTransform);

        CGSize scaleFactor = sGetNeededScaleForTransform(transform);
        CGAffineTransform scaleFactorTransform = CGAffineTransformMakeScale(scaleFactor.width, scaleFactor.height);

        CGRect renderBounds = sExpandRect(CGRectApplyAffineTransform([definition renderBounds], scaleFactorTransform));
        transform = CGAffineTransformConcat(CGAffineTransformInvert(scaleFactorTransform), transform);

        CGPoint anchorPoint = CGPointMake(
            -renderBounds.origin.x / renderBounds.size.width,
            -renderBounds.origin.y / renderBounds.size.height
        );

        [sublayer setValue:[NSNumber numberWithDouble:scaleFactor.width]  forKey:SwiffScaleFactorXKey];
        [sublayer setValue:[NSNumber numberWithDouble:scaleFactor.height] forKey:SwiffScaleFactorYKey];

        [sublayer setBounds:renderBounds];
        [sublayer setAnchorPoint:anchorPoint];
        [sublayer setAffineTransform:transform];

        if (!CGSizeEqualToSize(oldBounds.size, renderBounds.size)) {
            [sublayer setNeedsDisplay];
        }
    }


    // Handle color transforms.  For rendering speed, map SwiffColorTransform.alphaMultiple 
    // to CALayer.opacity.  If any other field of the color transform has changed,
    // we need to do a full redraw
    //
    {
        SwiffPlacedObject   *oldPlacedObject   = [sublayer valueForKey:SwiffPlacedObjectKey];
        SwiffColorTransform  oldColorTransform = [oldPlacedObject colorTransform];
        SwiffColorTransform  newColorTransform = [placedObject    colorTransform];
        
        [sublayer setOpacity:newColorTransform.alphaMultiply];

        // Set both to 0 to ignore alphaMultiply in compare
        oldColorTransform.alphaMultiply = 0;
        newColorTransform.alphaMultiply = 0;
        if (!SwiffColorTransformEqualToTransform(&oldColorTransform, &newColorTransform)) {
            [sublayer setNeedsDisplay];
        }
    }
}


static void sAddSublayerAtDepth(SwiffLayer *self, UInt16 depth, SwiffPlacedObject *placedObject)
{

    CFMutableDictionaryRef map = self->m_depthToSublayerMap;
    const void *key = (const void *)((depth << 16) | depth);

    if (!map) {
        map = self->m_depthToSublayerMap = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    }
    
    CALayer *sublayer = [[CALayer alloc] init];

    [sublayer setContentsScale:[self contentsScale]];
    [sublayer setDelegate:self];
    [sublayer setZPosition:depth];
    [sublayer setValue:[NSNumber numberWithInteger:placedObject->m_libraryID] forKey:SwiffLibraryIDKey];
    [sublayer setNeedsDisplay];

    sUpdateSublayerWithPlacedObject(self, sublayer, placedObject);

    [self addSublayer:sublayer];
    
    CFDictionarySetValue(map, key, sublayer);
    
    [sublayer release];
}


static void sUpdateSublayerAtDepth(SwiffLayer *self, UInt16 depth, SwiffPlacedObject *placedObject)
{
    CFMutableDictionaryRef map = self->m_depthToSublayerMap;
    const void *key = (const void *)((depth << 16) | depth);
    if (!map) return;

    CALayer *sublayer = (CALayer *)CFDictionaryGetValue(map, key);
    if (sublayer) {
        sUpdateSublayerWithPlacedObject(self, sublayer, placedObject);
    }
}


static void sRemoveSublayerAtDepth(SwiffLayer *self, UInt16 depth)
{
    CFMutableDictionaryRef map = self->m_depthToSublayerMap;
    const void *key = (const void *)((depth << 16) | depth);
    if (!map) return;
    
    CALayer *sublayer = (CALayer *)CFDictionaryGetValue(map, key);
    if (!sublayer) return;

    [sublayer removeFromSuperlayer];
    
    CFDictionaryRemoveValue(map, key);
    if (CFDictionaryGetCount(map) == 0) {
        CFRelease(self->m_depthToSublayerMap);
        self->m_depthToSublayerMap = NULL;
    }
}


static void sInvalidatePlacedObject(SwiffMovie *movie, SwiffPlacedObject *placedObject, CGRect *inOutRect)
{
    UInt16 libraryID = [placedObject libraryID];
    id<SwiffDefinition> definition = [movie definitionWithLibraryID:libraryID];
    
    CGRect bounds = [definition renderBounds];

    bounds = CGRectApplyAffineTransform(bounds, [placedObject affineTransform]);

    if (CGRectIsEmpty(*inOutRect)) {
        *inOutRect = bounds;
    } else {
        *inOutRect = CGRectUnion(*inOutRect, bounds);
    }
}


#pragma mark -
#pragma mark Private Methods

- (void) _transitionToFrame:(SwiffFrame *)newFrame fromFrame:(SwiffFrame *)oldFrame
{
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

    CGRect invalidRect = CGRectZero;

    SwiffMovie *movie = [self movie];
    BOOL didAddOrRemoveLayers = NO;

    while ((oldDepth < NSIntegerMax) || (newDepth < NSIntegerMax)) {
        if (oldDepth == newDepth) {
            if (oldPlacedObject != newPlacedObject) {
                if (oldWantsLayer && newWantsLayer && (oldPlacedObject->m_libraryID == newPlacedObject->m_libraryID)) {
                    sUpdateSublayerAtDepth(self, oldDepth, newPlacedObject);

                } else {
                    if (!oldWantsLayer) {
                        sInvalidatePlacedObject(movie, oldPlacedObject, &invalidRect);
                    } else {
                        sRemoveSublayerAtDepth(self, oldDepth);
                        didAddOrRemoveLayers = YES;
                    }
                    
                    if (!newWantsLayer) {
                        sInvalidatePlacedObject(movie, newPlacedObject, &invalidRect);
                    } else {
                        sAddSublayerAtDepth(self, newDepth, newPlacedObject);
                        didAddOrRemoveLayers = YES;
                    }
                }
            }

            NEXT(old);
            NEXT(new);
            
        } else if (newDepth < oldDepth) {
            if (newWantsLayer) {
                sAddSublayerAtDepth(self, newDepth, newPlacedObject);
                didAddOrRemoveLayers = YES;

            } else {
                sInvalidatePlacedObject(movie, newPlacedObject, &invalidRect);
            }

            NEXT(new);

        } else if (oldDepth < newDepth) {
            if (oldWantsLayer) {
                sRemoveSublayerAtDepth(self, oldDepth);
                didAddOrRemoveLayers = YES;

            } else {
                sInvalidatePlacedObject(movie, oldPlacedObject, &invalidRect);
            }

            NEXT(old);
        }
    }
    
    if (didAddOrRemoveLayers) {
        m_interpolateCurrentFrame = NO;
    }
    
    invalidRect = CGRectApplyAffineTransform(invalidRect, self->m_scaledAffineTransform);
    if (!CGRectIsEmpty(invalidRect)) {
        [self->m_contentLayer setNeedsDisplayInRect:invalidRect];
    }
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
        
        if (m_depthToSublayerMap) {
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
            SwiffWarn(@"Rendering took %lf.02 ms", msElapsed);
        }
#endif

        [frame release];

    } else {
        NSInteger libraryID = [[layer valueForKey:SwiffLibraryIDKey] integerValue];

        SwiffPlacedObject *originalPlacedObject = [layer valueForKey:SwiffPlacedObjectKey];
        
        SwiffPlacedObject *placedObject = [[SwiffPlacedObject alloc] initWithDepth:0];
        NSArray *placedObjects = [[NSArray alloc] initWithObjects:placedObject, nil];

        [placedObject setLibraryID:libraryID];

        SwiffColorTransform colorTransform = [originalPlacedObject colorTransform];
        colorTransform.alphaMultiply = 1.0;
        [placedObject setColorTransform:colorTransform];

        CGContextSaveGState(context);

#if DEBUG_SUBLAYERS
        CGContextSetRGBFillColor(context, 1, 0, 0, 0.25);
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
        CGAffineTransform ctm = CGContextGetCTM(context);

//      CGContextSetCTM() is private, so immitate it with concatenation
        CGContextConcatCTM(context, CGAffineTransformInvert(ctm)); // CGContextSetCTM(context, CGAffineTransformIdentity)

        CGAffineTransform t = CGAffineTransformMakeScale(
            [[layer valueForKey:SwiffScaleFactorXKey] doubleValue],
            [[layer valueForKey:SwiffScaleFactorYKey] doubleValue]
        );
        
        ctm = CGAffineTransformConcat(t, ctm);

        SwiffRendererSetBaseAffineTransform(m_renderer, &ctm);
        SwiffRendererSetPlacedObjects(m_renderer, placedObjects);
        SwiffRendererRender(m_renderer, context);

        CGContextRestoreGState(context);

        [placedObjects release];
        [placedObject release];
    }
}


- (id<CAAction>) actionForKey:(NSString *)event
{
    return nil;
}


- (id<CAAction>) actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    CAAnimation *existingAnimation = nil;

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
            [basicAnimation setCumulative:YES];
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

    [self setCurrentFrame:frame];
}


#pragma mark -
#pragma mark Public Methods

- (void) redisplay
{
    [m_contentLayer setNeedsDisplay];

    if (m_depthToSublayerMap) {
        CFIndex count = CFDictionaryGetCount(m_depthToSublayerMap);
        CALayer **sublayers = alloca(count * sizeof(CALayer *));

        CFDictionaryGetKeysAndValues(m_depthToSublayerMap, NULL, (const void **)sublayers);
        for (CFIndex i = 0; i < count; i++) {
            [sublayers[i] removeFromSuperlayer];
        }

        CFRelease(m_depthToSublayerMap);
        m_depthToSublayerMap = NULL;
    }

    SwiffFrame *savedFrame = [[self currentFrame] retain];
    id<SwiffLayerDelegate> savedDelegate = m_delegate;

    m_delegate = nil;
    [self setCurrentFrame:nil];
    [self setCurrentFrame:savedFrame];
    m_delegate = savedDelegate;
    
    [savedFrame release];
}


#pragma mark -
#pragma mark Accessors

- (void) setSwiffLayerDelegate:(id<SwiffLayerDelegate>)delegate
{
    if (m_delegate != delegate) {
        m_delegate = delegate;

        m_delegate_layer_didUpdateCurrentFrame = [m_delegate respondsToSelector:@selector(layer:didUpdateCurrentFrame:)];
        m_delegate_layer_shouldInterpolateFromFrame_toFrame = [m_delegate respondsToSelector:@selector(layer:shouldInterpolateFromFrame:toFrame:)];
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


- (void) setCurrentFrame:(SwiffFrame *)frame
{
    if (frame != m_currentFrame) {
        BOOL shouldInterpolate = NO;

        if (m_delegate_layer_shouldInterpolateFromFrame_toFrame) {
            shouldInterpolate = [m_delegate layer:self shouldInterpolateFromFrame:m_currentFrame toFrame:frame];
        }

        m_interpolateCurrentFrame = shouldInterpolate;

        SwiffFrame *oldFrame = m_currentFrame;
        m_currentFrame = [frame retain];

        if (m_delegate_layer_didUpdateCurrentFrame) {
            [m_delegate layer:self didUpdateCurrentFrame:m_currentFrame];
        }

        [self _transitionToFrame:frame fromFrame:oldFrame];
        [oldFrame release];
    }
}


- (void) setTintColor:(SwiffColor *)tintColor
{
    SwiffRendererSetTintColor(m_renderer, tintColor);
}


- (SwiffColor *) tintColor
{
    return SwiffRendererGetTintColor(m_renderer);
}


- (void) setHairlineWidth:(CGFloat)hairlineWidth
{
    SwiffRendererSetHairlineWidth(m_renderer, hairlineWidth);
}


- (CGFloat) hairlineWidth
{
    return SwiffRendererGetHairlineWidth(m_renderer);
}


- (void) setHairlineWithFillWidth:(CGFloat)hairlineWidth
{
    SwiffRendererSetHairlineWithFillWidth(m_renderer, hairlineWidth);
}


- (CGFloat) hairlineWithFillWidth
{
    return SwiffRendererGetHairlineWithFillWidth(m_renderer);
}


@synthesize swiffLayerDelegate  = m_delegate,
            movie               = m_movie,
            playhead            = m_playhead,
            currentFrame        = m_currentFrame,
            drawsBackground     = m_drawsBackground;

@end
