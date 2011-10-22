/*
    SwiftRenderer.m
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


#import "SwiftRenderer.h"

#import "SwiftFrame.h"
#import "SwiftMovie.h"
#import "SwiftGradient.h"
#import "SwiftLineStyle.h"
#import "SwiftFillStyle.h"
#import "SwiftPlacedObject.h"
#import "SwiftPlacedStaticText.h"
#import "SwiftPlacedText.h"
#import "SwiftShapeDefinition.h"
#import "SwiftPath.h"


typedef struct _SwiftRendererState {
    SwiftMovie       *movie;
    CGContextRef      context;
    CGAffineTransform affineTransform;
    CFMutableArrayRef colorTransforms;
} SwiftRendererState;

static void sDrawPlacedObject(SwiftRendererState *state, SwiftPlacedObject *placedObject, BOOL applyColorTransform, BOOL applyAffineTransform);

static void sCleanupState(SwiftRendererState *state)
{
    if (state->colorTransforms) {
        CFRelease(state->colorTransforms);
        state->colorTransforms = NULL;
    }
}


static void sApplyLineStyle(SwiftRendererState *state, SwiftLineStyle *style)
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

    SwiftColor color = SwiftColorApplyColorTransformStack([style color], state->colorTransforms);
    CGContextSetStrokeColor(context, (CGFloat *)&color);
    
    CGContextStrokePath(context);
}


static void sApplyFillStyle(SwiftRendererState *state, SwiftFillStyle *style)
{
     CGContextRef context = state->context;
   
    SwiftFillStyleType type = [style type];

    if (type == SwiftFillStyleTypeColor) {
        SwiftColor color = SwiftColorApplyColorTransformStack([style color], state->colorTransforms);
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


static void sDrawSprite(SwiftRendererState *state, SwiftSpriteDefinition *sprite)
{
    NSArray    *frames = [sprite frames];
    SwiftFrame *frame  = [frames count] ? [frames objectAtIndex:0] : nil;
    
    for (SwiftPlacedObject *po in [frame placedObjects]) {
        sDrawPlacedObject(state, po, YES, YES);
    }
}


static void sDrawShape(SwiftRendererState *state, SwiftShapeDefinition *shape)
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

        CGFloat *operations = [path operations];
        BOOL     isDone     = (operations == nil);

        while (!isDone) {
            CGFloat  type    = *operations++;
            CGFloat  toX     = *operations++;
            CGFloat  toY     = *operations++;
            CGPoint  toPoint = { toX, toY };

            toPoint = CGPointApplyAffineTransform(toPoint, state->affineTransform);

            if (shouldRound) {
                CGFloat (^roundForHairline)(CGFloat, BOOL) = ^(CGFloat inValue, BOOL flipped) {
                    if (flipped) {
                        return (CGFloat)(ceil(inValue) - 0.5);
                    } else {
                        return (CGFloat)(floor(inValue) + 0.5);
                    }
                };

                toPoint.x = roundForHairline(toPoint.x, (state->affineTransform.a < 0));
                toPoint.y = roundForHairline(toPoint.y, (state->affineTransform.d < 0));
            }

            if (type == SwiftPathOperationMove) {
                if (shouldClose && (lastMove.x == location.x) && (lastMove.y == location.y)) {
                    CGContextClosePath(context);
                }

                CGContextMoveToPoint(context, toPoint.x, toPoint.y);
                lastMove = toPoint;
                
            } else if (type == SwiftPathOperationLine) {
                CGContextAddLineToPoint(context, toPoint.x, toPoint.y);
            
            } else if (type == SwiftPathOperationCurve) {
                CGFloat controlX = *operations++;
                CGFloat controlY = *operations++;
                CGPoint controlPoint = CGPointMake(controlX, controlY);

                controlPoint = CGPointApplyAffineTransform(controlPoint, state->affineTransform);

                CGContextAddQuadCurveToPoint(context, controlPoint.x, controlPoint.y, toPoint.x, toPoint.y);
            
            } else {
                isDone = YES;
            }

            location = toPoint;
        }

        if (shouldClose && (lastMove.x == location.x) && (lastMove.y == location.y)) {
            CGContextClosePath(context);
        }

        BOOL hasStroke = NO;
        BOOL hasFill   = NO;

        if (lineWidth > 0) {
            sApplyLineStyle(state, lineStyle);
            hasStroke = YES;
        }
        
        if (fillStyle) {
            sApplyFillStyle(state, fillStyle);
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


static void sDrawAttributedString(SwiftRendererState *state, CFAttributedStringRef as, CGPoint offset)
{ 
    CGContextRef context = state->context;

    CTLineRef line = CTLineCreateWithAttributedString(as);
    if (line) {
        CGPoint p = CGPointMake(offset.x, offset.y);
        p = CGPointApplyAffineTransform(p, state->affineTransform);

        CGAffineTransform transform = CGAffineTransformConcat(CGAffineTransformMakeScale(1.0, -1.0), state->affineTransform);

        CGContextSaveGState(context);

        CGContextSetTextMatrix(context, transform);
        CGContextSetTextPosition(context, p.x, p.y);

        CTLineDraw(line, context);
        CGContextFlush(context);

        CGContextRestoreGState(context);

        CFRelease(line);
    }
}


static void sDrawPlacedStaticText(SwiftRendererState *state, SwiftPlacedStaticText *placedStaticText)
{
    CFAttributedStringRef as = [placedStaticText attributedText];
    CGPoint offset = [placedStaticText attributedTextOffset];
    if (as) sDrawAttributedString(state, as, offset);
}


static void sDrawPlacedText(SwiftRendererState *state, SwiftPlacedText *placedText)
{
    CFAttributedStringRef as = [placedText attributedText];
    CGPoint offset = [placedText attributedTextOffset];
    if (as) sDrawAttributedString(state, as, offset);
}


static void sDrawPlacedObject(SwiftRendererState *state, SwiftPlacedObject *placedObject, BOOL applyColorTransform, BOOL applyAffineTransform)
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

    UInt16 libraryID = [placedObject libraryID];

    SwiftSpriteDefinition     *sprite     = nil;
    SwiftShapeDefinition      *shape      = nil;
    SwiftStaticTextDefinition *staticText = nil;
    SwiftTextDefinition       *text       = nil;
    
    if ((sprite = [state->movie spriteDefinitionWithLibraryID:libraryID])) {
        sDrawSprite(state, sprite);

    } else if ((shape = [state->movie shapeDefinitionWithLibraryID:libraryID])) {
        sDrawShape(state, shape);

    } else if ((staticText = [state->movie staticTextDefinitionWithLibraryID:libraryID])) {
        if ([placedObject isKindOfClass:[SwiftPlacedStaticText class]]) {
            sDrawPlacedStaticText(state, (SwiftPlacedStaticText *)placedObject);
        }

    } else if ((text = [state->movie textDefinitionWithLibraryID:libraryID])) {
        if ([placedObject isKindOfClass:[SwiftPlacedText class]]) {
            sDrawPlacedText(state, (SwiftPlacedText *)placedObject);
        }
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
        sDrawPlacedObject(&state, object, YES, YES);
    }
    
    sCleanupState(&state);
}


- (void) renderPlacedObject:(SwiftPlacedObject *)placedObject movie:(SwiftMovie *)movie context:(CGContextRef)context
{
    SwiftRendererState state = { movie, context, CGAffineTransformIdentity, NULL };

    sSetupContext(context);

    sDrawPlacedObject(&state, placedObject, YES, NO);

    sCleanupState(&state);
}


@end
