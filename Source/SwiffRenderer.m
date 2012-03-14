/*
    SwiffRenderer.m
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
#import "SwiffUtils.h"


typedef struct SwiffRenderState {
    __unsafe_unretained SwiffMovie *movie;

    CGContextRef      context;
    CGRect            clipBoundingBox;
    CGAffineTransform affineTransform;
    CFMutableArrayRef colorTransforms;
    CGFloat           scaleFactorHint;
    CGFloat           hairlineWidth;
    CGFloat           fillHairlineWidth;
    CGFloat           multiplyRed;
    CGFloat           multiplyGreen;
    CGFloat           multiplyBlue;
    UInt16            clipDepth;
    BOOL              isBuildingClippingPath;
    BOOL              ceilX;
    BOOL              ceilY;
    BOOL              skipUntilClipDepth;
    BOOL              hasMultiplyColor;
} SwiffRenderState;


static void sDrawPlacedObject(SwiffRenderState *state, SwiffPlacedObject *placedObject);
static void sStopClipping(SwiffRenderState *state);


static void sStartClipping(SwiffRenderState *state, UInt16 clipDepth)
{
    if (state->clipDepth == 0) {
        CGContextRef context = state->context;

        CGContextSaveGState(context);
        CGContextClip(context);

        state->clipDepth = clipDepth;
    }
}


static void sStopClipping(SwiffRenderState *state)
{
    if (state->clipDepth) {
        CGContextRestoreGState(state->context);
        state->clipDepth = 0;
        state->skipUntilClipDepth = NO;
    }
}


static void sApplyMultiplyColor(SwiffRenderState *state, SwiffColor *color)
{
    color->red   *= state->multiplyRed;
    color->green *= state->multiplyGreen;
    color->blue  *= state->multiplyBlue;
}


static void sPushColorTransform(SwiffRenderState *state, const SwiffColorTransform *transform)
{
    if (!state->colorTransforms) {
        state->colorTransforms = CFArrayCreateMutable(NULL, 0, NULL);
    }

    CFMutableArrayRef array = state->colorTransforms;
    CFArraySetValueAtIndex(array, CFArrayGetCount(array), transform);
}


static void sPopColorTransform(SwiffRenderState *state)
{
    CFMutableArrayRef array = state->colorTransforms;
    CFArrayRemoveValueAtIndex(array, CFArrayGetCount(array) - 1);
}


static void sTracePathStrokeAdvanced(
    SwiffRenderState *state,
    SwiffPathOperation *operations,
    CGFloat *floats,
    CGFloat width,
    CGAffineTransform pointTransform,
    BOOL isHairline,
    BOOL shouldRound,
    BOOL shouldClose
) {
    CGContextRef context = state->context;

    CGFloat scale  = state->scaleFactorHint;
    CGFloat offset = (lround(width * state->scaleFactorHint) % 2) ? ((1.0 / state->scaleFactorHint) / 2) : 0;

    CGFloat x = NAN, y = NAN, controlX = NAN, controlY = NAN, moveX = NAN, moveY = NAN;

    SwiffPathOperation prevOp = SwiffPathOperationMove;
    SwiffPathOperation op     = SwiffPathOperationMove;
    SwiffPathOperation nextOp = *operations++;

nextOperation:
    prevOp = op;
    op     = nextOp;
    nextOp = *operations++;

    switch (op) {
    case SwiffPathOperationMove:
        if (shouldClose && (x == moveX) && (y == moveY)) {
            CGContextClosePath(context);
        }

        moveX = x = *floats++;
        moveY = y = *floats++;
        
        {
            CGPoint to = CGPointApplyAffineTransform(CGPointMake(x, y), pointTransform);

            if (isHairline || shouldRound) {
                to.x = (state->ceilX) ? (SwiffScaleCeil(to.x, scale) - offset) : (SwiffScaleFloor(to.x, scale) + offset);
                to.y = (state->ceilY) ? (SwiffScaleCeil(to.y, scale) - offset) : (SwiffScaleFloor(to.y, scale) + offset);
            }

            CGContextMoveToPoint(context, to.x, to.y);
        }

        if (!shouldClose) moveX = NAN;

        goto nextOperation;

    case SwiffPathOperationCurve:
        x        = *floats++;  y        = *floats++;
        controlX = *floats++;  controlY = *floats++;
        
        {
            CGPoint to      = CGPointApplyAffineTransform(CGPointMake(x,        y),        pointTransform);
            CGPoint control = CGPointApplyAffineTransform(CGPointMake(controlX, controlY), pointTransform);
            CGContextAddQuadCurveToPoint(context, control.x, control.y, to.x, to.y);
        }

        goto nextOperation;

    case SwiffPathOperationLine:
        x = *floats++;  y = *floats++;
        
        {
            CGPoint to = CGPointApplyAffineTransform(CGPointMake(x, y), pointTransform);
            CGContextAddLineToPoint(context, to.x, to.y);
        }

        goto nextOperation;

    case SwiffPathOperationHorizontalLine:
    case SwiffPathOperationVerticalLine:
        {
            CGFloat oldX = x, oldY = y;
            if (op == SwiffPathOperationHorizontalLine) {
                x = *floats++;;
            } else {
                y = *floats++;;
            }
            CGPoint to = CGPointApplyAffineTransform(CGPointMake(x, y), pointTransform);

            // Special hairline case, each horizontal or vertical line is a move followed by a lineTo
            // This corrects fuzzy line caps
            BOOL previousWasMove = (prevOp == SwiffPathOperationMove);
            BOOL nextIsMove      = (nextOp == SwiffPathOperationMove) || (nextOp == SwiffPathOperationEnd);

            if (isHairline && previousWasMove && nextIsMove) {
                moveX = oldX;
                moveY = oldY;
                CGPoint from = CGPointApplyAffineTransform(CGPointMake(oldX, oldY), pointTransform);

                if (op == SwiffPathOperationVerticalLine) {
                    CGFloat roundedX;
                    if (state->ceilX) {
                        roundedX = SwiffScaleCeil (to.x, scale) - offset;
                    } else {
                        roundedX = SwiffScaleFloor(to.x, scale) + offset;
                    }

                    CGContextMoveToPoint(context, roundedX, from.y);
                    CGContextAddLineToPoint(context, roundedX, to.y);

                } else {
                    CGFloat roundedY;
                    if (state->ceilY) {
                        roundedY = SwiffScaleCeil (to.y, scale) - offset;
                    } else {
                        roundedY = SwiffScaleFloor(to.y, scale) + offset;
                    }

                    CGContextMoveToPoint(context, from.x, roundedY);
                    CGContextAddLineToPoint(context, to.x, roundedY);
                }
                    
            } else {
                if (isHairline || shouldRound) {
                    to.x = (state->ceilX) ? (SwiffScaleCeil(to.x, scale) - offset) : (SwiffScaleFloor(to.x, scale) + offset);
                    to.y = (state->ceilY) ? (SwiffScaleCeil(to.y, scale) - offset) : (SwiffScaleFloor(to.y, scale) + offset);
                }

                CGContextAddLineToPoint(context, to.x, to.y);
            }

            goto nextOperation;
        }
    }

    if (shouldClose && (x == moveX) && (y == moveY)) {
        CGContextClosePath(context);
    }
}


static void sTracePathStrokeSimple(SwiffRenderState *state, SwiffPathOperation *operations, CGFloat *floats, BOOL shouldClose)
{
    CGContextRef context = state->context;
    CGFloat toX = NAN, toY = NAN, controlX = NAN, controlY = NAN, moveX = NAN, moveY = NAN;

nextOperation:
    switch (*operations++) {
    case SwiffPathOperationMove:
        if ((toX == moveX) && (toY == moveY)) {
            CGContextClosePath(context);
        }

        moveX = toX = *floats++;
        moveY = toY = *floats++;
        CGContextMoveToPoint(context, toX, toY);

        if (!shouldClose) moveX = NAN;

        goto nextOperation;

    case SwiffPathOperationCurve:
        toX      = *floats++;  toY      = *floats++;
        controlX = *floats++;  controlY = *floats++;
        CGContextAddQuadCurveToPoint(context, controlX, controlY, toX, toY);

        goto nextOperation;

    case SwiffPathOperationLine:
        toX = *floats++;  toY = *floats++;
        CGContextAddLineToPoint(context, toX, toY);

        goto nextOperation;

    case SwiffPathOperationHorizontalLine:
        toX = *floats++;
        CGContextAddLineToPoint(context, toX, toY);

        goto nextOperation;

    case SwiffPathOperationVerticalLine:
        toY = *floats++;
        CGContextAddLineToPoint(context, toX, toY);

        goto nextOperation;
    }

    if ((toX == moveX) && (toY == moveY)) {
        CGContextClosePath(context);
    }
}


// This works around <rdar://10646847> and also immitates what the Flash engine does
static CGPoint sTracePathFill_ApplyTransform(CGFloat x, CGFloat y, CGAffineTransform *transform)
{
    CGPoint point = CGPointApplyAffineTransform(CGPointMake(x, y), *transform);
    CGFloat iX, iY, fX, fY;

#if CGFLOAT_IS_DOUBLE
    fX= modf(point.x, &iX);
    fY= modf(point.y, &iY);

    if (fX < 0.15 || fX > 0.85) point.x = round(point.x);
    if (fY < 0.15 || fY > 0.85) point.y = round(point.y);
#else
    fX= modff(point.x, &iX);
    fY= modff(point.y, &iY);

    if (fX < 0.15 || fX > 0.85) point.x = roundf(point.x);
    if (fY < 0.15 || fY > 0.85) point.y = roundf(point.y);
#endif

    return point;
}

static void sTracePathFill(SwiffRenderState *state, SwiffPathOperation *operations, CGFloat *floats, CGAffineTransform pointTransform)
{
    CGContextRef context = state->context;
    CGFloat toX = NAN, toY = NAN, moveX = NAN, moveY = NAN;

    CGPoint p, c;

nextOperation:
    switch (*operations++) {
    case SwiffPathOperationMove:
        if ((toX == moveX) && (toY == moveY)) {
            CGContextClosePath(context);
        }

        moveX = toX = *floats++;
        moveY = toY = *floats++;
        
        p = sTracePathFill_ApplyTransform(toX, toY, &pointTransform);
        CGContextMoveToPoint(context, p.x, p.y);

        goto nextOperation;

    case SwiffPathOperationCurve:
        toX = *floats++;  toY = *floats++;
        c.x = *floats++;  c.y = *floats++;

        c = CGPointApplyAffineTransform(c, pointTransform);
        p = sTracePathFill_ApplyTransform(toX, toY, &pointTransform);
        CGContextAddQuadCurveToPoint(context, c.x, c.y, p.x, p.y);

        goto nextOperation;

    case SwiffPathOperationLine:
        toX = *floats++;  toY = *floats++;

        p = sTracePathFill_ApplyTransform(toX, toY, &pointTransform);
        CGContextAddLineToPoint(context, p.x, p.y);

        goto nextOperation;

    case SwiffPathOperationHorizontalLine:
        toX = *floats++;

        p = sTracePathFill_ApplyTransform(toX, toY, &pointTransform);
        CGContextAddLineToPoint(context, p.x, p.y);

        goto nextOperation;

    case SwiffPathOperationVerticalLine:
        toY = *floats++;

        p = sTracePathFill_ApplyTransform(toX, toY, &pointTransform);
        CGContextAddLineToPoint(context, p.x, p.y);

        goto nextOperation;
    }

    if ((toX == moveX) && (toY == moveY)) {
        CGContextClosePath(context);
    }
}


static void sStrokePath(SwiffRenderState *state, SwiffPath *path)
{
    SwiffPathOperation *operations = [path operations];
    CGFloat *floats = [path floats];
    if (!operations || !floats) return;

    SwiffLineStyle *lineStyle = [path lineStyle];
    CGFloat lineWidth = [lineStyle width];

    // Prevent blurry lines when a/d are 1/-1 
    BOOL isHairline  = (lineWidth == SwiffLineStyleHairlineWidth);
    BOOL shouldRound = NO;
    BOOL noScale     = NO;

    if ((lround(lineWidth) % 2) == 1 &&
        ((state->affineTransform.a == 1.0) || (state->affineTransform.a == -1.0)) &&
        ((state->affineTransform.d == 1.0) || (state->affineTransform.d == -1.0)))
    {
        shouldRound = YES;
    }

    if (![lineStyle scalesHorizontally] && ![lineStyle scalesVertically]) {
        noScale = YES;
    }

    CGContextRef context = state->context;
    CGContextSaveGState(context);

    if (isHairline || shouldRound || noScale) {
        if (isHairline) {
            lineWidth = state->hairlineWidth;

            if ((state->fillHairlineWidth != 0) && [path usesFillHairlineWidth]) {
                lineWidth = state->fillHairlineWidth;
            }
        }
        
        sTracePathStrokeAdvanced(state, operations, floats, lineWidth, state->affineTransform, isHairline, shouldRound, [lineStyle closesStroke]);

    } else {
        CGContextConcatCTM(context, state->affineTransform);
        sTracePathStrokeSimple(state, operations, floats, [lineStyle closesStroke]);
    }

    CGContextSetLineWidth(context, lineWidth);

    if (isHairline) {
        CGContextSetLineCap(context,  kCGLineCapButt);
        CGContextSetLineJoin(context, kCGLineJoinMiter);

    } else {
        CGLineJoin lineJoin = [lineStyle lineJoin];
        
        //!issue10: Use endLineCap at some point
        CGLineCap lineCap = [lineStyle startLineCap];

        CGContextSetLineCap(context, lineCap);
        CGContextSetLineJoin(context, lineJoin);

        if (lineJoin == kCGLineJoinMiter) {
            //!issue9: Better miter limits
            //    When the miter limit is hit, Quartz and Flash render it differently -
            //    Quartz converts it to a bezel that extends to 1/2 the line width
            //    Flash converts it to a bezel that extends to: MiterLimitFactor * LineWidth
            //  
            CGContextSetMiterLimit(context, [lineStyle miterLimit]);
        }
    }

    SwiffColor color = SwiffColorApplyColorTransformStack([lineStyle color], state->colorTransforms);
    if (state->hasMultiplyColor) sApplyMultiplyColor(state, &color);

    CGContextSetStrokeColor(context, (CGFloat *)&color);
    CGContextDrawPath(context, kCGPathStroke);

    CGContextRestoreGState(context);
}


static void sFillPath(SwiffRenderState *state, SwiffPath *path)
{
    SwiffPathOperation *operations = [path operations];
    CGFloat *floats = [path floats];

    if (!operations || !floats) return;

    SwiffFillStyle    *style = [path fillStyle];
    SwiffFillStyleType type  = [style type];

    CGContextRef context = state->context;

    CGContextSaveGState(context);
    sTracePathFill(state, operations, floats, state->affineTransform);

    CGContextConcatCTM(context, state->affineTransform);

    if (state->isBuildingClippingPath) {
        // Do nothing if we are building the clip path

    } else if (type == SwiffFillStyleTypeColor) {
        SwiffColor color = SwiffColorApplyColorTransformStack([style color], state->colorTransforms);
        if (state->hasMultiplyColor) sApplyMultiplyColor(state, &color);
        CGContextSetFillColor(context, (CGFloat *)&color);
        CGContextDrawPath(context, kCGPathFill);

    } else if ((type == SwiffFillStyleTypeLinearGradient) || (type == SwiffFillStyleTypeRadialGradient)) {
        CGContextEOClip(context);

        if (state->hasMultiplyColor) {
            SwiffColorTransform tintAsTransform = {
                state->multiplyRed,
                state->multiplyGreen,
                state->multiplyBlue,
                1.0,
                0.0, 0.0, 0.0, 0.0
            };

            sPushColorTransform(state, &tintAsTransform);
        }

        CGGradientRef gradient = [[style gradient] copyCGGradientWithColorTransformStack:state->colorTransforms];

        if (state->hasMultiplyColor) {
            sPopColorTransform(state);
        }

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

            point1 = CGPointApplyAffineTransform(point1, t);
            point2 = CGPointApplyAffineTransform(point2, t);
        
            CGContextDrawLinearGradient(context, gradient, point1, point2, options);

        } else {
            CGAffineTransform t = [style gradientTransform];

            CGFloat radius = 819.2 * t.a;
            CGPoint centerPoint = CGPointMake(t.tx, t.ty);

            CGContextDrawRadialGradient(context, gradient, centerPoint, 0, centerPoint, radius, options);
        }
        
        CGGradientRelease(gradient);

    } else if ((type >= SwiffFillStyleTypeRepeatingBitmap) && (type <= SwiffFillStyleTypeNonSmoothedClippedBitmap)) {
        SwiffBitmapDefinition *bitmapDefinition = [state->movie bitmapDefinitionWithLibraryID:[style bitmapID]];
        CGAffineTransform transform = [style bitmapTransform];

        BOOL shouldInterpolate = (type == SwiffFillStyleTypeRepeatingBitmap) || (type == SwiffFillStyleTypeClippedBitmap);
        BOOL shouldTile        = (type == SwiffFillStyleTypeRepeatingBitmap) || (type == SwiffFillStyleTypeNonSmoothedRepeatingBitmap);
        
        //!issue14: Repeating bitmaps
        (void)shouldTile;

        //!issue11: Affine clamp bitmaps
        //    Clipped bitmaps are currently cropped when drawn.  According to
        //    the spec, they should be affine clamped - See issue #11
        
        CGImageRef image = [bitmapDefinition CGImage];
        if (image) {
            CGContextConcatCTM(context, transform);
            
            CGContextClip(context);

            CGRect rect = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));
            
            CGContextTranslateCTM(context, 0, rect.size.height);
            CGContextScaleCTM(context, 1, -1);
            
            CGContextSetInterpolationQuality(context, shouldInterpolate ? kCGInterpolationDefault : kCGInterpolationNone);

            SwiffColor color = { 1.0, 1.0, 1.0, 1.0 };
            color = SwiffColorApplyColorTransformStack(color, state->colorTransforms);

            CGContextSetAlpha(context, color.alpha);
    
            CGContextDrawImage(context, rect, image);
        }   
    }

    CGContextRestoreGState(context);
}


static void sDrawSpriteDefinition(SwiffRenderState *state, SwiffSpriteDefinition *spriteDefinition)
{
    NSArray    *frames = [spriteDefinition frames];
    SwiffFrame *frame  = [frames count] ? [frames objectAtIndex:0] : nil;
    
    for (SwiffPlacedObject *po in [frame placedObjects]) {
        sDrawPlacedObject(state, po);
    }
}


static void sDrawShapeDefinition(SwiffRenderState *state, SwiffShapeDefinition *shapeDefinition)
{
    CGContextRef context = state->context;

    for (SwiffPath *path in [shapeDefinition paths]) {
        SwiffLineStyle *lineStyle = [path lineStyle];

        if (state->isBuildingClippingPath) {
            if (lineStyle) continue;
        } else {
            CGContextBeginPath(context);
        }

        if (lineStyle) {
            sStrokePath(state, path);
        } else {
            sFillPath(state, path);
        }
    }
}


static void sDrawStaticTextDefinition(SwiffRenderState *state, SwiffStaticTextDefinition *staticTextDefinition)
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


static void sDrawPlacedDynamicText(SwiffRenderState *state, SwiffPlacedDynamicText *placedDynamicText)
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

            CGContextConcatCTM(context, state->affineTransform);
            CGContextTranslateCTM(context, rect.origin.x, CGRectGetMaxY(rect));
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


static void sDrawPlacedObject(SwiffRenderState *state, SwiffPlacedObject *placedObject)
{
    UInt16      placedObjectClipDepth = placedObject->_additional ? [placedObject clipDepth] : 0;
    UInt16      placedObjectDepth     = placedObject->_depth;
    BOOL        placedObjectIsHidden  = placedObject->_additional ? [placedObject isHidden] : NO;
    BOOL        hasColorTransform     = placedObject->_additional ? [placedObject hasColorTransform] : NO;
    CGBlendMode blendMode             = placedObject->_additional ? [placedObject CGBlendMode] : kCGBlendModeNormal;

    // If we are in a clipping mask...
    if (state->clipDepth) {
    
        // Stop clipping if the depth is higher than the clipDepth
        if (placedObjectDepth > state->clipDepth) {
            sStopClipping(state);
        }
        
        // Our clipping mask layer was hidden (or not in the clip bounding box).  We can safely skip drawing this layer
        if (state->skipUntilClipDepth) {
            return;
        }
    }

    // The current depth starts a clipping mask
    if (placedObjectClipDepth) {
        state->isBuildingClippingPath = YES;
        state->skipUntilClipDepth = YES;
    }

    // Bail out if placedObject is hidden
    if (placedObjectIsHidden) {
        return;
    }

    __unsafe_unretained // Workaround for <rdar://11044357> clang 3.1 crashes in ObjCARCOpt::runOnFunction()
    id<SwiffDefinition> definition = SwiffMovieGetDefinition(state->movie, [placedObject libraryID]);

    CGAffineTransform newTransform = CGAffineTransformConcat([placedObject affineTransform], state->affineTransform);

    // Bail out if renderBounds is not in the clipBoundingBox
    CGRect renderBounds = CGRectApplyAffineTransform([definition renderBounds], newTransform);
    if (!CGRectIntersectsRect(renderBounds, state->clipBoundingBox)) {
        return;
    }

    CGAffineTransform savedTransform = state->affineTransform;
    state->affineTransform = newTransform;

    if (hasColorTransform) {
        sPushColorTransform(state, [placedObject colorTransformPointer]);
    }

    //!issue7: non-CG blend modes
    if (blendMode != kCGBlendModeNormal) {
        CGContextSaveGState(state->context);
        CGContextSetBlendMode(state->context, blendMode);
    }

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

    if (hasColorTransform) {
        sPopColorTransform(state);
    }
    
    if (blendMode != kCGBlendModeNormal) {
        CGContextRestoreGState(state->context);
    }

    state->affineTransform = savedTransform;

    if (placedObjectClipDepth) {
        sStartClipping(state, placedObjectClipDepth);
        state->isBuildingClippingPath = NO;
        state->skipUntilClipDepth = NO;
    }
}


#pragma mark -
#pragma mark SwiffRenderer Class

@implementation SwiffRenderer {
    CGAffineTransform _baseAffineTransform;
    SwiffColor        _multiplyColor;
    BOOL              _hasBaseAffineTransform;
    BOOL              _hasMultiplyColor;
}

@synthesize movie                       = _movie,
            scaleFactorHint             = _scaleFactorHint,
            hairlineWidth               = _hairlineWidth,
            fillHairlineWidth           = _fillHairlineWidth,
            shouldAntialias             = _shouldAntialias,
            shouldSmoothFonts           = _shouldSmoothFonts,
            shouldSubpixelPositionFonts = _shouldSubpixelPositionFonts,
            shouldSubpixelQuantizeFonts = _shouldSubpixelQuantizeFonts;


- (id) initWithMovie:(SwiffMovie *)movie
{
    if ((self = [super init])) {
        _movie = movie;
        _shouldAntialias = YES;
        _scaleFactorHint = 1.0;
    }

    return self;
}


- (void) renderPlacedObjects:(NSArray *)placedObjects inContext:(CGContextRef)context
{
    SwiffRenderState state;
    memset(&state, 0, sizeof(SwiffRenderState));

    state.movie   = _movie;
    state.context = context;

    if (_hasMultiplyColor && (_multiplyColor.alpha > 0)) {
        state.multiplyRed   = (_multiplyColor.red   * _multiplyColor.alpha);
        state.multiplyGreen = (_multiplyColor.green * _multiplyColor.alpha);
        state.multiplyBlue  = (_multiplyColor.blue  * _multiplyColor.alpha);
        state.hasMultiplyColor = YES;
    }
    
    if (_hasBaseAffineTransform) {
        state.affineTransform = _baseAffineTransform;
    } else {
        state.affineTransform = CGAffineTransformIdentity;
    }

    state.ceilX = CGContextGetCTM(context).a < 0;
    state.ceilY = CGContextGetCTM(context).d > 0;
    state.hairlineWidth     = _hairlineWidth ? _hairlineWidth : 1.0;
    state.fillHairlineWidth = _fillHairlineWidth;
    state.scaleFactorHint   = _scaleFactorHint;
    state.clipBoundingBox   = CGContextGetClipBoundingBox(context);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextSetInterpolationQuality(context, kCGInterpolationDefault);

    CGContextSetShouldAntialias(context, _shouldAntialias);
    CGContextSetShouldSmoothFonts(context, _shouldSmoothFonts);
    CGContextSetShouldSubpixelPositionFonts(context, _shouldSubpixelPositionFonts);
    CGContextSetShouldSubpixelQuantizeFonts(context, _shouldSubpixelQuantizeFonts);

    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetFillColorSpace(context, colorSpace);
    CGContextSetStrokeColorSpace(context, colorSpace);

    CGColorSpaceRelease(colorSpace);

    for (SwiffPlacedObject *object in placedObjects) {
        sDrawPlacedObject(&state, object);
    }

    sStopClipping(&state);

    state.movie   = nil;
    state.context = NULL;
    
    if (state.colorTransforms) {
        CFRelease(state.colorTransforms);
    }
}


- (void) setBaseAffineTransform:(CGAffineTransform *)transform
{
    if (transform && !CGAffineTransformIsIdentity(*transform)) {
        _baseAffineTransform = *transform;
        _hasBaseAffineTransform = YES;
    } else {
        _hasBaseAffineTransform = NO;
    }
}


- (CGAffineTransform *) baseAffineTransform
{
    if (_hasBaseAffineTransform) {
        return &_baseAffineTransform;
    } else {
        return NULL;
    }
}


- (void) setMultiplyColor:(SwiffColor *)color
{
    if (color && (color->alpha > 0)) {
        _multiplyColor = *color;
        _hasMultiplyColor = YES;
    } else {
        _hasMultiplyColor = NO;
    }
}


- (SwiffColor *) multiplyColor
{
    if (_hasMultiplyColor) {
        return &_multiplyColor;
    } else {
        return NULL;
    }
} 

@end

