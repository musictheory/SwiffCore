/*
    SwiffRenderer.h
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

#import <SwiffImport.h>
#import <SwiffTypes.h>

@class SwiffMovie;

typedef struct SwiffRenderer SwiffRenderer;

extern SwiffRenderer *SwiffRendererCreate(SwiffMovie *movie);
extern void SwiffRendererFree(SwiffRenderer *renderer);

extern void SwiffRendererRender(SwiffRenderer *renderer, CGContextRef context);

extern void SwiffRendererSetPlacedObjects(SwiffRenderer *renderer, NSArray *placedObjects);
extern NSArray *SwiffRendererGetPlacedObjects(SwiffRenderer *renderer);

extern void SwiffRendererSetBaseAffineTransform(SwiffRenderer *renderer, CGAffineTransform *transform);
extern CGAffineTransform *SwiffRendererGetBaseAffineTransform(SwiffRenderer *renderer);

// Hint to renderer about the original contentsScale of the context.  Used only for pixel-snapping, not scaling
extern void SwiffRendererSetScaleFactorHint(SwiffRenderer *renderer, CGFloat hint);
extern CGFloat SwiffRendererGetScaleFactorHint(SwiffRenderer *renderer);

// When set, all rendered colors are multiplied by the specified color
extern void SwiffRendererSetMultiplyColor(SwiffRenderer *renderer, SwiffColor *color);
extern SwiffColor *SwiffRendererGetMultiplyColor(SwiffRenderer *renderer);

extern void SwiffRendererSetHairlineWidth(SwiffRenderer *renderer, CGFloat hairlineWidth);
extern CGFloat SwiffRendererGetHairlineWidth(SwiffRenderer *renderer);

extern void SwiffRendererSetFillHairlineWidth(SwiffRenderer *renderer, CGFloat hairlineWidth);
extern CGFloat SwiffRendererGetFillHairlineWidth(SwiffRenderer *renderer);

// Maps to CGContextSetShouldAntialias()
extern void SwiffRendererSetShouldAntialias(SwiffRenderer *renderer, BOOL yn);
extern BOOL SwiffRendererGetShouldAntialias(SwiffRenderer *renderer);

// Maps to CGContextSetShouldSmoothFonts()
extern void SwiffRendererSetShouldSmoothFonts(SwiffRenderer *renderer, BOOL yn);
extern BOOL SwiffRendererGetShouldSmoothFonts(SwiffRenderer *renderer);

// Maps to CGContextSetShouldSubpixelPositionFonts()
extern void SwiffRendererSetShouldSubpixelPositionFonts(SwiffRenderer *renderer, BOOL yn);
extern BOOL SwiffRendererGetShouldSubpixelPositionFonts(SwiffRenderer *renderer);

// Maps to CGContextSetShouldSubpixelQuantizeFonts()
extern void SwiffRendererSetShouldSubpixelQuantizeFonts(SwiffRenderer *renderer, BOOL yn);
extern BOOL SwiffRendererGetShouldSubpixelQuantizeFonts(SwiffRenderer *renderer);
