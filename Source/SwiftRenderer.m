/*
    File: BitmapRenderer.m

    Contains: SWF to Bitmap renderer
    
    License: The MIT License

    Copyright (c) 2009-2010 Ricci Adams
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/


#import "SwiftRenderer.h"

#import "SwiftFrame.h"
#import "SwiftMovie.h"
#import "SwiftGradient.h"
#import "SwiftLineStyle.h"
#import "SwiftFillStyle.h"
#import "SwiftPlacedObject.h"
#import "SwiftShape.h"
#import "SwiftPath.h"
#import "SwiftPathOperation.h"


typedef struct _SwiftRendererState {
    SwiftMovie       *movie;
    CGContextRef      context;
    CGAffineTransform affineTransform;
    CFMutableArrayRef colorTransforms;
} SwiftRendererState;

static void sDrawPlacedObject(SwiftPlacedObject *placedObject, SwiftRendererState *state, BOOL applyColorTransform, BOOL applyAffineTransform);

static void sCleanupState(SwiftRendererState *state)
{
    if (state->colorTransforms) {
        CFRelease(state->colorTransforms);
        state->colorTransforms = NULL;
    }
}


static void sApplyLineStyle(SwiftLineStyle *style, SwiftRendererState *state)
{
    CGContextRef context = state->context;
    
    CGFloat    width    = [style width];
    CGLineJoin lineJoin = [style lineJoin];

    if (width == SwiftLineStyleHairlineWidth) {
        CGContextSetLineWidth(context, 1);
    } else {
        CGFloat transformedWidth = (width * MAX(state->affineTransform.a, state->affineTransform.d));
        if (transformedWidth < 0.0) transformedWidth *= -1.0;
        CGContextSetLineWidth(context, transformedWidth);
    }
    
    CGContextSetLineCap(context, [style startLineCap]);
    CGContextSetLineJoin(context, lineJoin);
    
    if (lineJoin == kCGLineJoinMiter) {
        CGContextSetMiterLimit(context, [style miterLimit]);
    }

    SwiftColor color = [style color];
    for (id o in (NSArray *)state->colorTransforms) {
        SwiftColorTransform transform = *((SwiftColorTransform *)o);
        color = SwiftColorApplyColorTransform(color, transform);
    }
    CGContextSetStrokeColor(context, (CGFloat *)&color);
    
    CGContextStrokePath(context);
}


static void sApplyFillStyle(SwiftFillStyle *style, SwiftRendererState *state)
{
     CGContextRef context = state->context;
   
    SwiftFillStyleType type = [style type];

    if (type == SwiftFillStyleTypeColor) {
        SwiftColor color = [style color];
        for (id o in (NSArray *)state->colorTransforms) {
            SwiftColorTransform transform = *((SwiftColorTransform *)o);
            color = SwiftColorApplyColorTransform(color, transform);
        }
        CGContextSetFillColor(context, (CGFloat *)&color);

    } else if ((type == SwiftFillStyleTypeLinearGradient) || (type == SwiftFillStyleTypeRadialGradient)) {
        CGContextSaveGState(context);
        CGContextEOClip(context);

        CGGradientRef gradient = [[style gradient] CGGradient];
        CGGradientDrawingOptions options = (kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);

        if (type == SwiftFillStyleTypeLinearGradient) {
            CGPoint point1 = CGPointMake(-819.2,  819.2);
            CGPoint point2 = CGPointMake( 819.2,  819.2);
            
            CGAffineTransform t = [style gradientTransform];

            t = CGAffineTransformConcat(t, state->affineTransform);

            point1 = CGPointApplyAffineTransform(point1, t);
            point2 = CGPointApplyAffineTransform(point2, t);
        
        
            CGContextDrawLinearGradient(context, gradient, point1, point2, options);

        } else {
            CGAffineTransform t = [style gradientTransform];

            double radius = 819.2 * t.a;
            double x = state->affineTransform.tx + (t.tx * state->affineTransform.a);
            double y = state->affineTransform.ty + (t.ty * state->affineTransform.d);

            CGPoint centerPoint = CGPointMake(x, y);

            CGContextDrawRadialGradient(context, gradient, centerPoint, 0, centerPoint, radius, options);
        }
        
        CGContextRestoreGState(context);
    }
}


static void sSetupContext(CGContextRef context)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetFillColorSpace(context, colorSpace);
    CGContextSetStrokeColorSpace(context, colorSpace);

    CGColorSpaceRelease(colorSpace);
}


static void sDrawSprite(SwiftSprite *sprite, SwiftRendererState *state)
{
    NSArray    *frames = [sprite frames];
    SwiftFrame *frame  = [frames count] ? [frames objectAtIndex:0] : nil;
    
    for (SwiftPlacedObject *po in [frame placedObjects]) {
        sDrawPlacedObject(po, state, YES, YES);
    }
}


static void sDrawShape(SwiftShape *shape, SwiftRendererState *state)
{
    CGContextRef context = state->context;

    for (SwiftPath *path in [shape paths]) {
        SwiftLineStyle *lineStyle = [path lineStyle];
        SwiftFillStyle *fillStyle = [path fillStyle];

        CGFloat lineWidth   = [lineStyle width];
        BOOL    shouldRound = (lineWidth == SwiftLineStyleHairlineWidth);
        BOOL    shouldClose = !lineStyle || [lineStyle closesStroke];

        // Prevent blurry lines when a/d are 1/-1 
        if ((lround(lineWidth) % 2) == 1 &&
            ((state->affineTransform.a == 1.0) || (state->affineTransform.a == -1.0)) &&
            ((state->affineTransform.d == 1.0) || (state->affineTransform.d == -1.0)))
        {
            shouldRound = YES;
        }

        CGPoint lastMove = { NAN, NAN };
        CGPoint location = { NAN, NAN };

        for (SwiftPathOperation *operation in [path operations]) {
            SwiftPathOperationType type = [operation type];

            CGPoint toPoint      = [operation toPoint];
            CGPoint controlPoint = [operation controlPoint];
        
            toPoint      = CGPointApplyAffineTransform(toPoint,      state->affineTransform);
            controlPoint = CGPointApplyAffineTransform(controlPoint, state->affineTransform);

            if (shouldRound) {
                CGFloat (^roundForHairline)(CGFloat, BOOL) = ^(CGFloat inValue, BOOL flipped) {
                    if (flipped) {
                        return (CGFloat)(ceil(inValue) - 0.5);
                    } else {
                        return (CGFloat)(floor(inValue) + 0.5);
                    }
                };

                toPoint.x   = roundForHairline(toPoint.x, (state->affineTransform.a < 0));
                toPoint.y   = roundForHairline(toPoint.y, (state->affineTransform.d < 0));
            }

            if (type == SwiftPathOperationTypeCurve) {
                CGContextAddQuadCurveToPoint(context, controlPoint.x, controlPoint.y, toPoint.x, toPoint.y);

            } else if (type == SwiftPathOperationTypeLine) {
                CGContextAddLineToPoint(context, toPoint.x, toPoint.y);

            } else {
                if (shouldClose && (lastMove.x == location.x) && (lastMove.y == location.y)) {
                    CGContextClosePath(context);
                }

                CGContextMoveToPoint(context, toPoint.x, toPoint.y);
                lastMove = toPoint;
            }
            
            location = toPoint;
        }
        
        if (shouldClose && (lastMove.x == location.x) && (lastMove.y == location.y)) {
            CGContextClosePath(context);
        }

        BOOL hasStroke = NO;
        BOOL hasFill   = NO;

        if (lineWidth > 0) {
            sApplyLineStyle(lineStyle, state);
            hasStroke = YES;
        }
        
        if (fillStyle) {
            sApplyFillStyle(fillStyle, state);
            hasFill = ([fillStyle type] == SwiftFillStyleTypeColor);
        }
        
        if (hasStroke || hasFill) {
            CGPathDrawingMode mode;
            
            if      (hasStroke && hasFill) mode = kCGPathFillStroke;
            else if (hasStroke)            mode = kCGPathStroke;
            else                           mode = kCGPathFill;
            
            CGContextDrawPath(context, mode);
        }
    }
}


static void sDrawPlacedObject(SwiftPlacedObject *placedObject, SwiftRendererState *state, BOOL applyColorTransform, BOOL applyAffineTransform)
{
    CGAffineTransform savedTransform;

    if (applyAffineTransform) {
        savedTransform = state->affineTransform;
        CGAffineTransform newTransform = [placedObject affineTransform];
        state->affineTransform = CGAffineTransformConcat(newTransform, savedTransform);
    }

    CFIndex colorTransformLastIndex = 0;

    if (applyColorTransform) {
        BOOL hasColorTransform = [placedObject hasColorTransform];

        if (hasColorTransform) {
            if (!state->colorTransforms) {
                state->colorTransforms = CFArrayCreateMutable(NULL, 0, NULL);
            }
            
            colorTransformLastIndex = CFArrayGetCount(state->colorTransforms);
            CFArraySetValueAtIndex(state->colorTransforms, colorTransformLastIndex, [placedObject colorTransformPointer]);
        }
    }

    NSInteger objectID = [placedObject objectID];

    SwiftSprite *sprite = nil;
    SwiftShape  *shape  = nil;

    if ((sprite = [state->movie spriteWithID:objectID])) {
        sDrawSprite(sprite, state);
    } else if ((shape = [state->movie shapeWithID:objectID])) {
        sDrawShape(shape, state);
    }

    if (colorTransformLastIndex > 0) {
        CFArrayRemoveValueAtIndex(state->colorTransforms, colorTransformLastIndex);
    }

    if (applyAffineTransform) {
        state->affineTransform = savedTransform;
    }
}


@implementation SwiftRenderer

+ (id) sharedInstance
{
    static SwiftRenderer *sSharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sSharedInstance = [[SwiftRenderer alloc] init]; 
    });
    
    return sSharedInstance;
}


- (void) renderFrame:(SwiftFrame *)frame movie:(SwiftMovie *)movie context:(CGContextRef)context
{
    SwiftRendererState state = { movie, context, CGAffineTransformIdentity, NULL };

    sSetupContext(context);

    for (SwiftPlacedObject *object in [frame placedObjects]) {
        sDrawPlacedObject(object, &state, YES, YES);
    }
    
    sCleanupState(&state);
}


- (void) renderPlacedObject:(SwiftPlacedObject *)placedObject movie:(SwiftMovie *)movie context:(CGContextRef)context
{
    SwiftRendererState state = { movie, context, CGAffineTransformIdentity, NULL };

    sSetupContext(context);

    sDrawPlacedObject(placedObject, &state, YES, NO);

    sCleanupState(&state);
}


@end
