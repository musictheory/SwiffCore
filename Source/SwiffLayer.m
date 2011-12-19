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

#define DEBUG_SUBLAYERS 0

static NSString * const SwiffLibraryIDKey = @"SwiffLibraryID";
static NSString * const SwiffPlacedObjectKey = @"SwiffPlacedObject";


@implementation SwiffLayer

- (id) initWithMovie:(SwiffMovie *)movie
{
    if ((self = [self init])) {
        m_baseAffineTransform = CGAffineTransformIdentity;
        m_baseColorTransform  = SwiffColorTransformIdentity;
        m_postColorTransform  = SwiffColorTransformIdentity;

        m_movie = [movie retain];

        m_playhead = [[SwiffPlayhead alloc] initWithMovie:movie delegate:self];
        [m_playhead gotoFrameWithIndex:0 play:NO];

        m_contentLayer = [[CALayer alloc] init];
        [m_contentLayer setDelegate:self];
        [self addSublayer:m_contentLayer];
    }
    
    return self;
}


- (void) dealloc
{
    [m_contentLayer setDelegate:nil];
    [m_playhead setDelegate:nil];

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


#pragma mark -
#pragma mark Private Methods

static CGFloat sGetDistance(CGPoint p1, CGPoint p2)
{
#if defined(CGFLOAT_IS_DOUBLE) && CGFLOAT_IS_DOUBLE
    return sqrt(pow(p2.x - p1.x, 2.0) + pow(p2.y - p1.y, 2.0));
#else
    return sqrtf(powf(p2.x - p1.x, 2.0f) + powf(p2.y - p1.y, 2.0f));
#endif
}


static CGFloat sGetScaleFactorForTransform(CGAffineTransform t)
{
    CGPoint topLeft     = CGPointApplyAffineTransform(CGPointMake(0, 0), t);
    CGPoint topRight    = CGPointApplyAffineTransform(CGPointMake(1, 0), t);
    CGPoint bottomLeft  = CGPointApplyAffineTransform(CGPointMake(0, 1), t);
    CGPoint bottomRight = CGPointApplyAffineTransform(CGPointMake(1, 1), t);

    CGFloat topWidth    = sGetDistance(topLeft,    topRight);
    CGFloat bottomWidth = sGetDistance(bottomLeft, bottomRight);
    CGFloat leftHeight  = sGetDistance(topLeft,    bottomLeft);
    CGFloat rightHeight = sGetDistance(topRight,   bottomRight);

    CGSize larger = CGSizeMake(
        topWidth   > bottomWidth ? topWidth   : bottomWidth,
        leftHeight > rightHeight ? leftHeight : rightHeight
    );
    
    return larger.width > larger.height ? larger.width : larger.height;
}

extern NSString *NSStringFromCGRect(CGRect);


static void sUpdateSublayerWithPlacedObject(SwiffLayer *self, CALayer *sublayer, SwiffPlacedObject *placedObject)
{
    if (!placedObject) return;

    id<SwiffDefinition> definition = [self->m_movie definitionWithLibraryID:placedObject->m_libraryID];
    
    CGRect renderBounds = [definition renderBounds];

    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformConcat(transform, [placedObject affineTransform]);
    transform = CGAffineTransformConcat(transform, self->m_scaledAffineTransform);

    CGPoint anchorPoint = CGPointMake(
        -renderBounds.origin.x / renderBounds.size.width,
        -renderBounds.origin.y / renderBounds.size.height
    );

    SwiffPlacedObject   *oldPlacedObject   = [sublayer valueForKey:SwiffPlacedObjectKey];
    SwiffColorTransform  oldColorTransform = [oldPlacedObject colorTransform];
    SwiffColorTransform  newColorTransform = [placedObject    colorTransform];
    
    [sublayer setOpacity:newColorTransform.alphaMultiply];

    // Set both to 0 to ignore alphaMultiply in compare, as we map alphaMultiply to CALayer.opacity
    oldColorTransform.alphaMultiply = 0;
    newColorTransform.alphaMultiply = 0;
    if (!SwiffColorTransformEqualToTransform(&oldColorTransform, &newColorTransform)) {
        [sublayer setNeedsDisplay];
    }

    [sublayer setBounds:[definition renderBounds]];
    [sublayer setAnchorPoint:anchorPoint];
    [sublayer setAffineTransform:transform];
    [sublayer setValue:placedObject forKey:SwiffPlacedObjectKey];

    CGFloat oldScaleFactor = [sublayer contentsScale];
    CGFloat scaleFactor = sGetScaleFactorForTransform(transform);

    if (scaleFactor != oldScaleFactor) {
        [sublayer setContentsScale:scaleFactor];
        [sublayer setNeedsDisplay];
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


- (void) _transitionToFrame:(SwiffFrame *)newFrame
{
    NSEnumerator *oldEnumerator = [[m_currentFrame placedObjects] objectEnumerator];
    NSEnumerator *newEnumerator = [[newFrame       placedObjects] objectEnumerator];
    
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


- (void) _updateScaledTransform
{
    CGSize movieSize = [m_movie stageRect].size;
    CGRect bounds    = [self bounds];

    m_scaledAffineTransform = CGAffineTransformScale(self->m_baseAffineTransform, bounds.size.width /  movieSize.width, bounds.size.height / movieSize.height);
}


#pragma mark -
#pragma mark CALayer Logic

- (void) setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    [self _updateScaledTransform];
    
    [m_contentLayer setFrame:bounds];
    [m_contentLayer setNeedsDisplay];
}


- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    if (layer == m_contentLayer) {
        if (!m_currentFrame) return;

#if WARN_ON_DROPPED_FRAMES        
        clock_t c = clock();
#endif

        NSArray *placedObjects   = [m_currentFrame placedObjects];
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
        SwiffRender(context, m_movie, (filteredObjects ? filteredObjects : placedObjects), m_scaledAffineTransform, &m_baseColorTransform, &m_postColorTransform);
        CGContextRestoreGState(context);
        
        [filteredObjects release];

#if WARN_ON_DROPPED_FRAMES        
        double msElapsed = (clock() - c) / (double)(CLOCKS_PER_SEC / 1000);
        if (msElapsed > (1000.0 / 60.0)) {
            SwiffWarn(@"Rendering took %lf.02 ms", msElapsed);
        }
#endif

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

        SwiffRender(context, m_movie, placedObjects, ctm, &m_baseColorTransform, &m_postColorTransform);
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
    if (m_interpolateCurrentFrame) {
        CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:event];

        [basicAnimation setDuration:(1.0 / [m_movie frameRate])];
        [basicAnimation setCumulative:YES];

        return basicAnimation;
    } else {
        return (id)[NSNull null];
    }
}


- (void) redisplay
{
    [m_contentLayer setNeedsDisplay];

    if (m_depthToSublayerMap) {
        CFIndex count = CFDictionaryGetCount(m_depthToSublayerMap);
        CALayer **sublayers = malloc(count * sizeof(CALayer *));

        CFDictionaryGetKeysAndValues(m_depthToSublayerMap, NULL, (const void **)sublayers);
        for (CFIndex i = 0; i < count; i++) {
            [sublayers[i] removeFromSuperlayer];
        }

        free(sublayers);

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
#pragma mark Playhead Delegate

- (void) playheadDidUpdate:(SwiffPlayhead *)playhead
{
    SwiffFrame *frame = [playhead frame];

    if (m_delegate_layer_willDisplayFrame) {
        [m_delegate layer:self willDisplayFrame:frame];
    }

    [[SwiffSoundPlayer sharedInstance] processMovie:m_movie frame:frame];

    [self setCurrentFrame:frame];
}


#pragma mark -
#pragma mark Accessors

- (void) setSwiffLayerDelegate:(id<SwiffLayerDelegate>)delegate
{
    if (m_delegate != delegate) {
        m_delegate = delegate;

        m_delegate_layer_willDisplayFrame = [m_delegate respondsToSelector:@selector(layer:willDisplayFrame:)];
        m_delegate_layer_didDisplayFrame  = [m_delegate respondsToSelector:@selector(layer:didDisplayFrame:)];
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

        [self _transitionToFrame:frame];

        [m_currentFrame release];
        m_currentFrame = [frame retain];
    }
}


- (void) setBaseAffineTransform:(CGAffineTransform)baseAffineTransform
{
    if (!CGAffineTransformEqualToTransform(baseAffineTransform, m_baseAffineTransform)) {
        m_baseAffineTransform = baseAffineTransform;
        [self _updateScaledTransform];
        [m_contentLayer setFrame:[self bounds]];
        [m_contentLayer setNeedsDisplay];
    }
}


- (void) setBaseColorTransform:(SwiffColorTransform)baseColorTransform
{
    if (!SwiffColorTransformEqualToTransform(&baseColorTransform, &m_baseColorTransform)) {
        m_baseColorTransform = baseColorTransform;
        [m_contentLayer setNeedsDisplay];
    }
}


- (void) setPostColorTransform:(SwiffColorTransform)postColorTransform
{
    if (!SwiffColorTransformEqualToTransform(&postColorTransform, &m_postColorTransform)) {
        m_postColorTransform = postColorTransform;
        [m_contentLayer setNeedsDisplay];
    }
}


@synthesize swiffLayerDelegate  = m_delegate,
            movie               = m_movie,
            playhead            = m_playhead,
            currentFrame        = m_currentFrame,
            baseAffineTransform = m_baseAffineTransform,
            baseColorTransform  = m_baseColorTransform,
            postColorTransform  = m_postColorTransform,
            drawsBackground     = m_drawsBackground;

@end
