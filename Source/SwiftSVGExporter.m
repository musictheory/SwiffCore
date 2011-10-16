/*
    SwiftSVGExporter.m
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

#import "SwiftSVGExporter.h"

typedef struct _SwiftSVGExporterState {
    __unsafe_unretained SwiftMovie *movie;

    CGAffineTransform  affineTransform;
    CFMutableArrayRef  colorTransforms;
    NSMutableString   *defs;
    NSMutableString   *body;
    NSUInteger         nextDefinedID;
} SwiftSVGExporterState;


static void sDrawPlacedObject(SwiftSVGExporterState *state, SwiftPlacedObject *placedObject);

static BOOL sUseRelative = YES;

static char *sCharBufferPtr = NULL;
static char *sCharBuffer    = NULL;
static char *sCharBufferEnd = NULL;


static void sCharBufferNext()
{
    if (!sCharBuffer) {
        sCharBuffer    = malloc(1024);
        sCharBufferEnd = sCharBuffer + 1024;
        sCharBufferPtr = sCharBuffer;
    }

    sCharBufferPtr += 64;
    if (sCharBufferPtr >= sCharBufferEnd) {
        sCharBufferPtr = sCharBuffer;
    }
}


static char *sTwipStr(CGFloat f)
{
    sCharBufferNext();
    
    long twip = lround(f * 20);
    
    char *negativeStr = "";
    if (twip < 0) {
        negativeStr = "-";
        twip *= -1;
    }
    
    char *map[] ={
        "",   ".05", ".1", ".15", ".2", ".25", ".3", ".35", ".4", ".45",
        ".5", ".55", ".6", ".65", ".7", ".75", ".8", ".85", ".9", ".95"
    };
    
    snprintf(sCharBufferPtr, 64, "%s%ld%s", negativeStr, (long)(twip / 20), map[twip % 20]);
    return sCharBufferPtr;
}


static char *sDoubleStr(CGFloat d)
{
    sCharBufferNext();
    
    if (lround((d * 100) - ((long)d) * 100) == 0) {
        snprintf(sCharBufferPtr, 64, "%ld", (long)d);
    } else {
        snprintf(sCharBufferPtr, 64, "%.02lf", d);
    }

    return sCharBufferPtr;
}


static SwiftColor sGetTransformedColor(SwiftSVGExporterState *state, SwiftColor color)
{
    CFArrayRef transforms = state->colorTransforms;
    for (CFIndex i, count = CFArrayGetCount(transforms); i < count; i++) {
        SwiftColorTransform *transform = (SwiftColorTransform *)CFArrayGetValueAtIndex(transforms, i);
        color = SwiftColorApplyColorTransform(color, *transform);
    }

    return color;
}


static NSString *sGetNextDefinedID(SwiftSVGExporterState *state)
{
    NSString *idString = [NSMutableString string];

    // Make a new ID string
    NSUInteger n = state->nextDefinedID++;
    char *s = alloca(256);
    
    NSInteger i = 0;
    do {
        s[i++] = n % 26 + 'a';
    } while ((n /= 26) > 0);
    
    do {
        [(NSMutableString *)idString appendFormat:@"%c", s[--i]];
    } while (i > 0);
    
    return idString;
}


static CGFloat sGetTransformedAlpha(SwiftSVGExporterState *state, CGFloat alpha)
{
    CFArrayRef transforms = state->colorTransforms;
    for (CFIndex i, count = CFArrayGetCount(transforms); i < count; i++) {
        SwiftColorTransform *transform = (SwiftColorTransform *)CFArrayGetValueAtIndex(transforms, i);
        
        alpha = (alpha * transform->alphaMultiply) + transform->alphaAdd;
        if      (alpha > 1.0) alpha = 1.0;
        else if (alpha < 0.0) alpha = 0.0;
    }
    
    return alpha;
}


static NSString *sGetSVGForColor(SwiftSVGExporterState *state, SwiftColor inColor)
{
    SwiftColor color = sGetTransformedColor(state, inColor);
    
    int r = (NSInteger)(color.red   * 255.0);
    int g = (NSInteger)(color.green * 255.0);
    int b = (NSInteger)(color.blue  * 255.0);
    
    return [NSString stringWithFormat:@"#%02x%02x%02x", r, g, b];
}


static NSString *sGetSVGForFillStyle(SwiftSVGExporterState *state, SwiftFillStyle *fillStyle)
{
    NSMutableString *svg = [NSMutableString string];
    SwiftFillStyleType type = [fillStyle type];

    if (!fillStyle) {
        [svg appendString:@"fill=\"none\""];

    } else if (type == SwiftFillStyleTypeLinearGradient) {
        CGAffineTransform transform = [fillStyle gradientTransform];
        SwiftGradient    *gradient  = [fillStyle gradient];
        NSString         *definedID = sGetNextDefinedID(state);

        char *x1 = sTwipStr((-819.2 * transform.a) + transform.tx);
        char *y1 = sTwipStr((-819.2 * transform.b) + transform.ty); // might be transform.c
        char *x2 = sTwipStr(( 819.2 * transform.b) + transform.tx);
        char *y2 = sTwipStr(( 819.2 * transform.b) + transform.ty); // might be transform.c
    
        [state->defs appendFormat:@"<linearGradient id=\"%@\" x1=\"%s\" y1=\"%s\" x2=\"%s\" y2=\"%s\" gradientUnits=\"userSpaceOnUse\">",
            definedID, x1, y1, x2, y2];
        
        NSUInteger i, count;
        for (i = 0, count = [gradient recordCount]; i < count; i++) {
            SwiftColor color;
            CGFloat    ratio;
            [gradient getColor:&color ratio:&ratio forRecord:i];

            NSString *colorString = sGetSVGForColor(state, color);
            CGFloat   stopOpacity = sGetTransformedAlpha(state, color.alpha);
            
            [state->defs appendFormat:@"<stop offset=\"%ld%%\" stop-color=\"%@\"",
                (long)round(ratio * 100),
                colorString];
            
            if (stopOpacity != 1.0) {
                [state->defs appendFormat:@" stop-opacity=\"%.02lf\"", stopOpacity];
            }

            [state->defs appendString:@"/>"];
        }

        [state->defs appendFormat:@"</linearGradient>\n"];
        [svg appendFormat:@"fill=\"url(#%@)\"", definedID];
        
    } else if (type == SwiftFillStyleTypeRadialGradient) {
        CGAffineTransform transform = [fillStyle gradientTransform];
        SwiftGradient    *gradient  = [fillStyle gradient];
        NSString         *definedID = sGetNextDefinedID(state);

        char *radius = sTwipStr(819.2 * transform.a);
        char *x = sTwipStr(transform.tx);
        char *y = sTwipStr(transform.ty);

        [state->defs appendFormat:@"<radialGradient id=\"%@\"", definedID];
        [state->defs appendFormat:@"fx=\"%s\" fy=\"%s\" ", x, y];
        [state->defs appendFormat:@"cx=\"%s\" cy=\"%s\" ", x, y];
        [state->defs appendFormat:@"r=\"%s\" ", radius];
        [state->defs appendString:@"gradientUnits=\"userSpaceOnUse\">"];

        NSUInteger i, count;
        for (i = 0, count = [gradient recordCount]; i < count; i++) {
            SwiftColor color;
            CGFloat    ratio;
            [gradient getColor:&color ratio:&ratio forRecord:i];

            NSString *colorString = sGetSVGForColor(state, color);
            [state->defs appendFormat:@"<stop offset=\"%ld%%\" stop-color=\"%@\" />",
                (long)round(ratio * 100),
                colorString];
        }

        [state->defs appendFormat:@"</radialGradient>\n"];
        [svg appendFormat:@"fill=\"url(#%@)\"", definedID];
    
    } else if (type == SwiftFillStyleTypeColor) {
        SwiftColor color = [fillStyle color];
        
        [svg appendFormat:@"fill=\"%@\"", sGetSVGForColor(state, color)];
        
        CGFloat fillAlpha = sGetTransformedAlpha(state, color.alpha);
        if (fillAlpha != 1.0) {
            [svg appendFormat:@" fill-opacity=\"%.02lf\"", fillAlpha];
        }
    }
    
    return svg;
}


static NSString *sGetSVGForLineStyle(SwiftSVGExporterState *state, SwiftLineStyle *lineStyle)
{
    if (!lineStyle) return @"";

    NSMutableString *svg = [NSMutableString string];

    UInt8 strokeAlpha = sGetTransformedAlpha(state, [lineStyle color].alpha);
    CGFloat width = [lineStyle width];

    CGLineCap lineCap = [lineStyle startLineCap];
    if (lineCap == kCGLineCapRound) {
        [svg appendString:@" stroke-linecap=\"round\""];
    } else if (lineCap == kCGLineCapSquare) {
        [svg appendString:@" stroke-linecap=\"square\""];
    }
    CGLineJoin lineJoin = [lineStyle lineJoin];
    if (lineJoin == kCGLineJoinRound) {
        [svg appendString:@" stroke-linejoin=\"round\""];
    } else if (lineJoin == kCGLineJoinBevel) {
        [svg appendString:@" stroke-linejoin=\"bevel\""];
    } else if (lineJoin == kCGLineJoinMiter) {
        [svg appendFormat:@" stroke-miterlimit=\"%.02lf\"", [lineStyle miterLimit]];
    }

    [svg appendFormat:@" stroke=\"%@\"", sGetSVGForColor(state, [lineStyle color])];
    [svg appendFormat:@" stroke-width=\"%s\"", (width == SwiftLineStyleHairlineWidth) ? "1" : sTwipStr(width)];
    
    if (strokeAlpha != 1.0) {
        [svg appendFormat:@" stroke-opacity=\"%.02lf\"", strokeAlpha];
    }
    
    return svg;

}


static NSString *sGetSVGForPathOperations(SwiftSVGExporterState *state, NSArray *operations, BOOL shouldClose)
{
#if 0
    NSMutableString *svg = [NSMutableString string];

    CGPoint location = { CGFLOAT_MAX, CGFLOAT_MAX };
    CGPoint to       = { CGFLOAT_MAX, CGFLOAT_MAX };
    CGPoint lastMove = { CGFLOAT_MIN, CGFLOAT_MIN };

    for (SwiftPathOperation *operation in operations) {
        SwiftPathOperationType type = [operation type];

        CGPoint control = [operation controlPoint];
                to      = [operation toPoint];

        if (type == SwiftPathOperationTypeCurve) {
            if (sUseRelative) {
                CGFloat controlDeltaX = control.x - location.x;
                CGFloat controlDeltaY = control.y - location.y;
                CGFloat deltaX        = to.x      - location.x;
                CGFloat deltaY        = to.y      - location.y;

                [svg appendFormat:@"q%s,%s,%s,%s", sTwipStr(controlDeltaX), sTwipStr(controlDeltaY), sTwipStr(deltaX), sTwipStr(deltaY)];

            } else {
                [svg appendFormat:@"Q%s,%s,%s,%s", sTwipStr(control.x), sTwipStr(control.y), sTwipStr(to.x), sTwipStr(to.y)];
            }

        } else if (type == SwiftPathOperationTypeLine) {
            if (sUseRelative) {
                CGFloat deltaX = to.x - location.x;
                CGFloat deltaY = to.y - location.y;

                if (deltaX != 0 && deltaY != 0) {
                    [svg appendFormat:@"l%s,%s", sTwipStr(deltaX), sTwipStr(deltaY)];
                } else if (deltaX == 0) {
                    [svg appendFormat:@"v%s", sTwipStr(deltaY)];
                } else if (deltaY == 0) {
                    [svg appendFormat:@"h%s", sTwipStr(deltaX)];
                }

            } else {
                [svg appendFormat:@"L%s,%s", sTwipStr(to.x), sTwipStr(to.y)];
            }

        } else {
            if (shouldClose && (location.x == lastMove.x) && (location.y == lastMove.y)) {
                [svg appendString:@"Z"];
            }
        
            [svg appendFormat:@"M%s,%s", sTwipStr(to.x), sTwipStr(to.y)];
            lastMove = to;
        }

        location = to;
    }

    if (shouldClose && (location.x == lastMove.x) && (location.y == lastMove.y)) {
        [svg appendString:@"Z"];
    }

    return svg;
#endif
}



static void sDrawPath(SwiftSVGExporterState *state, SwiftPath *path, CGAffineTransform *transform)
{
    SwiftFillStyle *fillStyle = [path fillStyle];
    SwiftLineStyle *lineStyle = [path lineStyle];
    
    BOOL isHairline  = [lineStyle width] == SwiftLineStyleHairlineWidth;
    BOOL shouldClose = !lineStyle || [lineStyle closesStroke];

    NSArray *operations = [path operationsWithAffineTransform:transform isHairline:isHairline];

                   [state->body appendFormat:@"<path %@", sGetSVGForFillStyle(state, fillStyle)];
    if (lineStyle) [state->body appendString:             sGetSVGForLineStyle(state, lineStyle)];
    
    [state->body appendFormat:@" d=\"%@\"/>\n", sGetSVGForPathOperations(state, operations, shouldClose)];
}


static void sDrawSprite(SwiftSVGExporterState *state, SwiftSprite *sprite)
{
    SwiftFrame *frame = [sprite frameAtIndex1:1];

    for (SwiftPlacedObject *placedObject in [frame placedObjects]) {
        sDrawPlacedObject(state, placedObject);
    }
}


static void sDrawShape(SwiftSVGExporterState *state, SwiftShape *shape)
{
    NSMutableString *body = state->body;

    [body appendFormat:@"<g"];

    if (!CGAffineTransformIsIdentity(state->affineTransform)) {
        CGAffineTransform transform = state->affineTransform;

        [body appendFormat:@" transform=\"matrix(%s %s %s %s %s %s)\"", 
            sDoubleStr( transform.a ),
            sDoubleStr( transform.b ),
            sDoubleStr( transform.c ),
            sDoubleStr( transform.d ),
            sTwipStr(   transform.tx * 20),
            sTwipStr(   transform.ty * 20)];
    }

    [body appendString:@">\n"];

    // Apply fills and non-hairline strokes
    for (SwiftPath *path in [shape paths]) {
        SwiftLineStyle *lineStyle = [path lineStyle];
        SwiftFillStyle *fillStyle = [path fillStyle];

        CGFloat strokeAlpha = sGetTransformedAlpha(state, [lineStyle color].alpha);
        if (([lineStyle width] == SwiftLineStyleHairlineWidth) || (strokeAlpha == 0)) continue;

        CGFloat fillAlpha = sGetTransformedAlpha(state, [fillStyle color].alpha);
        if (([fillStyle type] == SwiftFillStyleTypeColor) && (fillAlpha == 0)) continue;

        CGAffineTransform identity = CGAffineTransformIdentity;
        sDrawPath(state, path, &identity);
    }

    [body appendFormat:@"</g>\n"];

    // Apply hairline strokes
    for (SwiftPath *path in [shape paths]) {
        SwiftLineStyle *lineStyle = [path lineStyle];

        CGFloat strokeAlpha = sGetTransformedAlpha(state, [lineStyle color].alpha);
        if (([lineStyle width] == SwiftLineStyleHairlineWidth) && (strokeAlpha != 0)) {
            sDrawPath(state, path, &state->affineTransform);
        }
    }
}



static void sDrawPlacedObject(SwiftSVGExporterState *state, SwiftPlacedObject *placedObject)
{
    CGAffineTransform savedTransform = state->affineTransform;

    CGAffineTransform newTransform = [placedObject affineTransform];
    state->affineTransform = CGAffineTransformConcat(newTransform, savedTransform);

    CFIndex colorTransformLastIndex = 0;

    BOOL hasColorTransform = [placedObject hasColorTransform];

    if (hasColorTransform) {
        if (!state->colorTransforms) {
            state->colorTransforms = CFArrayCreateMutable(NULL, 0, NULL);
        }
        
        colorTransformLastIndex = CFArrayGetCount(state->colorTransforms);
        CFArraySetValueAtIndex(state->colorTransforms, colorTransformLastIndex, [placedObject colorTransformPointer]);
    }

    NSInteger objectID = [placedObject objectID];

    SwiftSprite *sprite = nil;
    SwiftShape  *shape  = nil;

    if ((sprite = [state->movie spriteWithID:objectID])) {
        sDrawSprite(state, sprite);
    } else if ((shape = [state->movie shapeWithID:objectID])) {
        sDrawShape(state, shape);
    }

    if (colorTransformLastIndex > 0) {
        CFArrayRemoveValueAtIndex(state->colorTransforms, colorTransformLastIndex);
    }

    state->affineTransform = savedTransform;
}


@implementation SwiftSVGExporter

+ (id) sharedInstance
{
    static SwiftSVGExporter *sSharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sSharedInstance = [[SwiftSVGExporter alloc] init]; 
    });
    
    return sSharedInstance;
}


- (BOOL) exportFrame:(SwiftFrame *)frame ofMovie:(SwiftMovie *)movie toFile:(NSString *)path
{
    NSURL *fileURL = [NSURL fileURLWithPath:path];

    if (fileURL) {
        return [self exportFrame:frame ofMovie:movie toURL:fileURL];
    }
    
    return NO;
}


- (BOOL) exportFrame:(SwiftFrame *)frame ofMovie:(SwiftMovie *)movie toURL:(NSURL *)fileURL
{
    SwiftSVGExporterState state = { movie, CGAffineTransformIdentity, NULL, nil, nil, 0 };

    CGSize stageSize = [movie stageSize];
    size_t width     = stageSize.width;
    size_t height    = stageSize.height;
    BOOL   success   = NO;

    @autoreleasepool {
        state.defs = [NSMutableString string];
        state.body = [NSMutableString string];

        for (SwiftPlacedObject *placedObject in [frame placedObjects]) {
            sDrawPlacedObject(&state, placedObject);
        }

        NSMutableString *svg = [NSMutableString string];

        [svg appendString:@"<?xml version=\"1.0\"?>\n"]; 
        [svg appendString:@"<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n"];

        [svg appendFormat:@"<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" width=\"%ld\" height=\"%ld\" viewBox=\"0 0 %ld %ld\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">\n",
            (long)width,
            (long)height,
            (long)width,
            (long)height];

        if ([state.defs length]) [svg appendFormat:@"<defs>\n%@</defs>\n", state.defs];
        [svg appendFormat:@"%@", state.body];
        [svg appendString:@"</svg>\n"];
        
        NSError *error = nil;
        success = [svg writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }
    
    return success;
}

@end
