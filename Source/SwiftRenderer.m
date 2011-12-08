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

#import "SwiftDynamicTextAttributes.h"
#import "SwiftDynamicTextDefinition.h"
#import "SwiftFontDefinition.h"
#import "SwiftFrame.h"
#import "SwiftMovie.h"
#import "SwiftGradient.h"
#import "SwiftLineStyle.h"
#import "SwiftFillStyle.h"
#import "SwiftPath.h"
#import "SwiftPlacedObject.h"
#import "SwiftPlacedDynamicText.h"
#import "SwiftShapeDefinition.h"
#import "SwiftStaticTextRecord.h"
#import "SwiftStaticTextDefinition.h"

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


static void sPushColorTransform(SwiftRendererState *state, SwiftColorTransform *transform)
{
    if (!state->colorTransforms) {
        state->colorTransforms = CFArrayCreateMutable(NULL, 0, NULL);
    }

    CFMutableArrayRef array = state->colorTransforms;
    CFArraySetValueAtIndex(array, CFArrayGetCount(array), transform);
}


static void sPopColorTransform(SwiftRendererState *state)
{
    CFMutableArrayRef array = state->colorTransforms;
    CFArrayRemoveValueAtIndex(array, CFArrayGetCount(array) - 1);
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

        CGGradientRef gradient = [[style gradient] copyCGGradientWithColorTransformStack:state->colorTransforms];
        CGGradientDrawingOptions options = (kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);

        if (type == SwiftFillStyleTypeLinearGradient) {
            // "All gradients are defined in a standard space called the gradient square. The gradient square is
            //  centered at (0,0), and extends from (-16384,-16384) to (16384,16384)." (Page 144)
            // 
            // 16384 twips = 819.2 points
            //
            CGPoint point1 = CGPointMake(-819.2,  819.2);
            CGPoint point2 = CGPointMake( 819.2,  819.2);
            
            CGAffineTransform t = [style gradientTransform];

            t = CGAffineTransformConcat(t, state->affineTransform);

            point1 = CGPointApplyAffineTransform(point1, t);
            point2 = CGPointApplyAffineTransform(point2, t);
        
            CGContextDrawLinearGradient(context, gradient, point1, point2, options);

        } else {
            CGAffineTransform t = [style gradientTransform];

            CGFloat radius = 819.2 * t.a * state->affineTransform.a;
            CGFloat x = state->affineTransform.tx + (t.tx * state->affineTransform.a);
            CGFloat y = state->affineTransform.ty + (t.ty * state->affineTransform.d);

            CGPoint centerPoint = CGPointMake(x, y);

            CGContextDrawRadialGradient(context, gradient, centerPoint, 0, centerPoint, radius, options);
        }
        
        CGGradientRelease(gradient);
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


static void sDrawSpriteDefinition(SwiftRendererState *state, SwiftSpriteDefinition *spriteDefinition)
{
    NSArray    *frames = [spriteDefinition frames];
    SwiftFrame *frame  = [frames count] ? [frames objectAtIndex:0] : nil;
    
    for (SwiftPlacedObject *po in [frame placedObjects]) {
        sDrawPlacedObject(state, po, YES, YES);
    }
}


static void sDrawShapeDefinition(SwiftRendererState *state, SwiftShapeDefinition *shapeDefinition)
{
    CGContextRef context = state->context;

    for (SwiftPath *path in [shapeDefinition paths]) {
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
            SwiftFillStyleType fillStyleType = [fillStyle type];
            hasFill = (fillStyleType == SwiftFillStyleTypeColor) || (fillStyleType == SwiftFillStyleTypeFontShape);
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


static void sDrawStaticTextDefinition(SwiftRendererState *state, SwiftStaticTextDefinition *staticTextDefinition)
{
    SwiftFontDefinition *font = nil;
    CGPathRef *glyphPaths = NULL;

    CGContextRef context = state->context;
    CGPoint offset = CGPointZero;
    CGFloat aWithMultiplier = state->affineTransform.a;
    CGFloat dWithMultiplier = state->affineTransform.d;

    CGContextSaveGState(context);

    for (SwiftStaticTextRecord *record in [staticTextDefinition textRecords]) {
        NSInteger glyphEntriesCount = [record glyphEntriesCount];
        SwiftStaticTextRecordGlyphEntry *glyphEntries = [record glyphEntries];
        
        CGFloat advance = 0; 

        if ([record hasFont]) {
            font = [state->movie fontDefinitionWithLibraryID:[record fontID]];
            glyphPaths = [font glyphPaths];

            CGFloat multiplier = (1.0 / SwiftFontEmSquareHeight) * [record textHeight];
            aWithMultiplier = state->affineTransform.a * multiplier;
            dWithMultiplier = state->affineTransform.d * multiplier;
        }
        
        if ([record hasColor]) {
            CGContextSetFillColor(context, (CGFloat *)[record colorPointer]);
        }
        
        if ([record hasXOffset]) {
            offset.x = [record xOffset];
        }

        if ([record hasYOffset]) {
            offset.y = [record yOffset];
        }

        if (glyphPaths && glyphEntries) {
            for (NSInteger i = 0; i < glyphEntriesCount; i++) {
                SwiftStaticTextRecordGlyphEntry entry = glyphEntries[i];

                CGAffineTransform savedTransform = state->affineTransform;

                state->affineTransform = CGAffineTransformTranslate(state->affineTransform, offset.x + advance, offset.y);
                state->affineTransform.a = aWithMultiplier;
                state->affineTransform.d = dWithMultiplier;

                CGContextSaveGState(context);
                CGContextConcatCTM(context, state->affineTransform);
                CGContextAddPath(context, glyphPaths[entry.index]);
                CGContextRestoreGState(context);

                advance += entry.advance;

                state->affineTransform = savedTransform;
            }
        }
        
        CGContextDrawPath(context, kCGPathFill);

        offset.x += advance;
    }

    CGContextRestoreGState(context);
}


static void sDrawPlacedDynamicText(SwiftRendererState *state, SwiftPlacedDynamicText *placedDynamicText)
{
    CFAttributedStringRef as = [placedDynamicText attributedText];
    SwiftDynamicTextDefinition *definition = [placedDynamicText definition];
    CGRect rect = [definition bounds];

    CGContextRef context = state->context;
    CTFramesetterRef framesetter = as ? CTFramesetterCreateWithAttributedString(as) : NULL;
    
    if (framesetter) {
        CGPathRef  path  = CGPathCreateWithRect(CGRectMake(0, 0, rect.size.width, rect.size.height), NULL);
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);

        if (frame) {
            CGContextSaveGState(context);

            CGContextTranslateCTM(context, rect.origin.x, rect.origin.y);

            CGContextConcatCTM(context, state->affineTransform);
            CGContextTranslateCTM(context, 0, rect.size.height);
            CGContextScaleCTM(context, 1, -1);
            
            NSInteger i;
            CFArrayRef lines = CTFrameGetLines(frame);
            CFIndex linesCount = CFArrayGetCount(lines);
            CGPoint *origins = malloc(sizeof(CGPoint) * linesCount);

            CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);

            for (i = 0; i < linesCount; i++) {
                CTLineRef line = CFArrayGetValueAtIndex(lines, i);
                CGPoint origin = origins[i];

                CFRange rangeOfLine = CTLineGetStringRange(line);

                origin.y -= SwiftTextGetMaximumVerticalOffset(as, rangeOfLine);

                CGContextSetTextPosition(context, origin.x, origin.y);
                
                CTLineDraw(line, context);
            }
            
            free(origins);
            
            CGContextFlush(context);
            CGContextRestoreGState(context);

            CFRelease(frame);
        }
        
        if (path) CFRelease(path);
        CFRelease(framesetter);
    }
}


static void sDrawPlacedObject(SwiftRendererState *state, SwiftPlacedObject *placedObject, BOOL applyColorTransform, BOOL applyAffineTransform)
{
    CGAffineTransform savedTransform;

    if (applyAffineTransform) {
        savedTransform = state->affineTransform;
        CGAffineTransform newTransform = [placedObject affineTransform];
        state->affineTransform = CGAffineTransformConcat(newTransform, savedTransform);
    }

    BOOL needsColorTransformPop = NO;

    if (applyColorTransform) {
        BOOL hasColorTransform = [placedObject hasColorTransform];

        if (hasColorTransform) {
            sPushColorTransform(state, [placedObject colorTransformPointer]);
            needsColorTransformPop = YES;
        }
    }

    CGContextSaveGState(state->context);

    UInt16 libraryID = [placedObject libraryID];

    SwiftSpriteDefinition      *spriteDefinition      = nil;
    SwiftShapeDefinition       *shapeDefinition       = nil;
    SwiftStaticTextDefinition  *staticTextDefinition  = nil;
    SwiftDynamicTextDefinition *dynamicTextDefinition = nil;
    
    if ((spriteDefinition = [state->movie spriteDefinitionWithLibraryID:libraryID])) {
        sDrawSpriteDefinition(state, spriteDefinition);

    } else if ((shapeDefinition = [state->movie shapeDefinitionWithLibraryID:libraryID])) {
        sDrawShapeDefinition(state, shapeDefinition);

    } else if ((staticTextDefinition = [state->movie staticTextDefinitionWithLibraryID:libraryID])) {
        sDrawStaticTextDefinition(state, staticTextDefinition);

    } else if ((dynamicTextDefinition = [state->movie dynamicTextDefinitionWithLibraryID:libraryID])) {
        if ([placedObject isKindOfClass:[SwiftPlacedDynamicText class]]) {
            sDrawPlacedDynamicText(state, (SwiftPlacedDynamicText *)placedObject);
        }
    }

    if (needsColorTransformPop) {
        sPopColorTransform(state);
    }

    if (applyAffineTransform) {
        state->affineTransform = savedTransform;
    }
    
    CGContextRestoreGState(state->context);
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


- (void)   renderFrame: (SwiftFrame *) frame
                 movie: (SwiftMovie *) movie
               context: (CGContextRef) context
   baseAffineTransform: (CGAffineTransform) baseAffineTransform
    baseColorTransform: (SwiftColorTransform) baseColorTransform
{
    SwiftRendererState state = { movie, context, baseAffineTransform, NULL };
    BOOL hasColorTransform = !SwiftColorTransformIsIdentity(baseColorTransform);

    sSetupContext(context);

    if (hasColorTransform) {
        sPushColorTransform(&state, &baseColorTransform);
    }

    for (SwiftPlacedObject *object in [frame placedObjects]) {
        sDrawPlacedObject(&state, object, YES, YES);
    }
    
    if (hasColorTransform) {
        sPopColorTransform(&state);
    }
    
    sCleanupState(&state);
}


- (void) renderPlacedObject: (SwiftPlacedObject *) placedObject
                      movie: (SwiftMovie *) movie
                    context: (CGContextRef) context
        baseAffineTransform: (CGAffineTransform) baseAffineTransform
         baseColorTransform: (SwiftColorTransform) baseColorTransform
{
    SwiftRendererState state = { movie, context, baseAffineTransform, NULL };

    BOOL hasColorTransform = !SwiftColorTransformIsIdentity(baseColorTransform);

    sSetupContext(context);

    if (hasColorTransform) {
        sPushColorTransform(&state, &baseColorTransform);
    }

    sDrawPlacedObject(&state, placedObject, YES, NO);

    if (hasColorTransform) {
        sPopColorTransform(&state);
    }

    sCleanupState(&state);
}


@end
