/*
    SwiffRenderer.m
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


#import "SwiffRenderer.h"

#import "SwiffBitmapDefinition.h"
#import "SwiffDynamicTextAttributes.h"
#import "SwiffDynamicTextDefinition.h"
#import "SwiffFontDefinition.h"
#import "SwiffFrame.h"
#import "SwiffMovie.h"
#import "SwiffGradient.h"
#import "SwiffLineStyle.h"
#import "SwiffFillStyle.h"
#import "SwiffPath.h"
#import "SwiffPlacedObject.h"
#import "SwiffPlacedDynamicText.h"
#import "SwiffShapeDefinition.h"
#import "SwiffStaticTextRecord.h"
#import "SwiffStaticTextDefinition.h"

typedef struct _SwiffRendererState {
    SwiffMovie       *movie;
    CGContextRef      context;
    CGAffineTransform affineTransform;
    CFMutableArrayRef colorTransforms;
} SwiffRendererState;

static void sDrawPlacedObject(SwiffRendererState *state, SwiffPlacedObject *placedObject, BOOL applyColorTransform, BOOL applyAffineTransform);

static void sCleanupState(SwiffRendererState *state)
{
    if (state->colorTransforms) {
        CFRelease(state->colorTransforms);
        state->colorTransforms = NULL;
    }
}


static void sPushColorTransform(SwiffRendererState *state, SwiffColorTransform *transform)
{
    if (!state->colorTransforms) {
        state->colorTransforms = CFArrayCreateMutable(NULL, 0, NULL);
    }

    CFMutableArrayRef array = state->colorTransforms;
    CFArraySetValueAtIndex(array, CFArrayGetCount(array), transform);
}


static void sPopColorTransform(SwiffRendererState *state)
{
    CFMutableArrayRef array = state->colorTransforms;
    CFArrayRemoveValueAtIndex(array, CFArrayGetCount(array) - 1);
}


static void sApplyLineStyle(SwiffRendererState *state, SwiffLineStyle *style)
{
    CGContextRef context = state->context;
    
    CGFloat    width    = [style width];
    CGLineJoin lineJoin = [style lineJoin];

    if (width == SwiffLineStyleHairlineWidth) {
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

    SwiffColor color = SwiffColorApplyColorTransformStack([style color], state->colorTransforms);
    CGContextSetStrokeColor(context, (CGFloat *)&color);
    
    CGContextStrokePath(context);
}


static void sApplyFillStyle(SwiffRendererState *state, SwiffFillStyle *style)
{
     CGContextRef context = state->context;
   
    SwiffFillStyleType type = [style type];

    if (type == SwiffFillStyleTypeColor) {
        SwiffColor color = SwiffColorApplyColorTransformStack([style color], state->colorTransforms);
        CGContextSetFillColor(context, (CGFloat *)&color);

    } else if ((type == SwiffFillStyleTypeLinearGradient) || (type == SwiffFillStyleTypeRadialGradient)) {
        CGContextSaveGState(context);
        CGContextEOClip(context);

        CGGradientRef gradient = [[style gradient] copyCGGradientWithColorTransformStack:state->colorTransforms];
        CGGradientDrawingOptions options = (kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);

        if (type == SwiffFillStyleTypeLinearGradient) {
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
    } else if ((type >= SwiffFillStyleTypeRepeatingBitmap) && (type <= SwiffFillStyleTypeNonSmoothedClippedBitmap)) {
        SwiffBitmapDefinition *bitmapDefinition = [state->movie bitmapDefinitionWithLibraryID:[style bitmapID]];
        CGAffineTransform transform = [style bitmapTransform];

        BOOL shouldInterpolate = (type == SwiffFillStyleTypeRepeatingBitmap) || (type == SwiffFillStyleTypeClippedBitmap);
        BOOL shouldTile        = (type == SwiffFillStyleTypeRepeatingBitmap) || (type == SwiffFillStyleTypeNonSmoothedRepeatingBitmap);
        

//        NSLog(@"%lf,%lf,%lf,%lf,%lf,%lf",
//            transform.a,
//            transform.b,
//            transform.c,
//            transform.d,
//            transform.tx,
//            transform.ty);

        CGImageRef image = [bitmapDefinition CGImage];
        if (image) {
            CGContextSaveGState(context);
            
            CGContextConcatCTM(context, state->affineTransform);
            CGContextConcatCTM(context, transform);
            
            CGContextClip(context);

            CGRect rect = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));
            
            CGContextTranslateCTM(context, 0, rect.size.height);
            CGContextScaleCTM(context, 1, -1);
            
            CGContextSetInterpolationQuality(context, shouldInterpolate ? kCGInterpolationDefault : kCGInterpolationNone);

            CGContextDrawImage(context, rect, image);
            CGContextRestoreGState(context);
        }   
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


static void sDrawSpriteDefinition(SwiffRendererState *state, SwiffSpriteDefinition *spriteDefinition)
{
    NSArray    *frames = [spriteDefinition frames];
    SwiffFrame *frame  = [frames count] ? [frames objectAtIndex:0] : nil;
    
    for (SwiffPlacedObject *po in [frame placedObjects]) {
        sDrawPlacedObject(state, po, YES, YES);
    }
}


static void sDrawShapeDefinition(SwiffRendererState *state, SwiffShapeDefinition *shapeDefinition)
{
    CGContextRef context = state->context;

    for (SwiffPath *path in [shapeDefinition paths]) {
        SwiffLineStyle *lineStyle = [path lineStyle];
        SwiffFillStyle *fillStyle = [path fillStyle];

        CGFloat lineWidth   = [lineStyle width];
        BOOL    shouldRound = (lineWidth == SwiffLineStyleHairlineWidth);
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

            if (type == SwiffPathOperationMove) {
                if (shouldClose && (lastMove.x == location.x) && (lastMove.y == location.y)) {
                    CGContextClosePath(context);
                }

                CGContextMoveToPoint(context, toPoint.x, toPoint.y);
                lastMove = toPoint;
                
            } else if (type == SwiffPathOperationLine) {
                CGContextAddLineToPoint(context, toPoint.x, toPoint.y);
            
            } else if (type == SwiffPathOperationCurve) {
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
            SwiffFillStyleType fillStyleType = [fillStyle type];
            hasFill = (fillStyleType == SwiffFillStyleTypeColor);
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


static void sDrawStaticTextDefinition(SwiffRendererState *state, SwiffStaticTextDefinition *staticTextDefinition)
{
    SwiffFontDefinition *font = nil;
    CGPathRef *glyphPaths = NULL;

    CGContextRef context = state->context;
    CGPoint offset = CGPointZero;
    CGFloat aWithMultiplier = state->affineTransform.a;
    CGFloat dWithMultiplier = state->affineTransform.d;

    CGContextSaveGState(context);

    for (SwiffStaticTextRecord *record in [staticTextDefinition textRecords]) {
        NSInteger glyphEntriesCount = [record glyphEntriesCount];
        SwiffStaticTextRecordGlyphEntry *glyphEntries = [record glyphEntries];
        
        CGFloat advance = 0; 

        if ([record hasFont]) {
            font = [state->movie fontDefinitionWithLibraryID:[record fontID]];
            glyphPaths = [font glyphPaths];

            CGFloat multiplier = (1.0 / SwiffFontEmSquareHeight) * [record textHeight];
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
                SwiffStaticTextRecordGlyphEntry entry = glyphEntries[i];

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


static void sDrawPlacedDynamicText(SwiffRendererState *state, SwiffPlacedDynamicText *placedDynamicText)
{
    CFAttributedStringRef as = [placedDynamicText attributedText];
    SwiffDynamicTextDefinition *definition = [placedDynamicText definition];
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

                origin.y -= SwiffTextGetMaximumVerticalOffset(as, rangeOfLine);

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


static void sDrawPlacedObject(SwiffRendererState *state, SwiffPlacedObject *placedObject, BOOL applyColorTransform, BOOL applyAffineTransform)
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

    id<SwiffDefinition> definition = [state->movie definitionWithLibraryID:libraryID];
    
    if ([definition isKindOfClass:[SwiffDynamicTextDefinition class]]) {
        if ([placedObject isKindOfClass:[SwiffPlacedDynamicText class]]) {
            sDrawPlacedDynamicText(state, (SwiffPlacedDynamicText *)placedObject);
        }

    } else if ([definition isKindOfClass:[SwiffShapeDefinition class]]) {
        sDrawShapeDefinition(state, (SwiffShapeDefinition *)definition);

    } else if ([definition isKindOfClass:[SwiffSpriteDefinition class]]) {
        sDrawSpriteDefinition(state, (SwiffSpriteDefinition *)definition);

    } else if ([definition isKindOfClass:[SwiffStaticTextDefinition class]]) {
        sDrawStaticTextDefinition(state, (SwiffStaticTextDefinition *)definition);
    }

    if (needsColorTransformPop) {
        sPopColorTransform(state);
    }

    if (applyAffineTransform) {
        state->affineTransform = savedTransform;
    }
    
    CGContextRestoreGState(state->context);
}


@implementation SwiffRenderer

+ (id) sharedInstance
{
    static SwiffRenderer *sSharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sSharedInstance = [[SwiffRenderer alloc] init]; 
    });
    
    return sSharedInstance;
}


- (void)   renderFrame: (SwiffFrame *) frame
                 movie: (SwiffMovie *) movie
               context: (CGContextRef) context
   baseAffineTransform: (CGAffineTransform) baseAffineTransform
    baseColorTransform: (SwiffColorTransform) baseColorTransform
{
    SwiffRendererState state = { movie, context, baseAffineTransform, NULL };
    BOOL hasColorTransform = !SwiffColorTransformIsIdentity(baseColorTransform);

    sSetupContext(context);

    if (hasColorTransform) {
        sPushColorTransform(&state, &baseColorTransform);
    }

    for (SwiffPlacedObject *object in [frame placedObjects]) {
        sDrawPlacedObject(&state, object, YES, YES);
    }
    
    if (hasColorTransform) {
        sPopColorTransform(&state);
    }
    
    sCleanupState(&state);
}


- (void) renderPlacedObject: (SwiffPlacedObject *) placedObject
                      movie: (SwiffMovie *) movie
                    context: (CGContextRef) context
        baseAffineTransform: (CGAffineTransform) baseAffineTransform
         baseColorTransform: (SwiffColorTransform) baseColorTransform
{
    SwiffRendererState state = { movie, context, baseAffineTransform, NULL };

    BOOL hasColorTransform = !SwiffColorTransformIsIdentity(baseColorTransform);

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
