/*
    SwiffRenderer.h
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

#import <SwiffImport.h>
#import <SwiffTypes.h>

@class SwiffMovie;


@interface SwiffRenderer : NSObject {
@private
    SwiffMovie       *m_movie;

    CGFloat           m_scaleFactorHint;
    CGFloat           m_hairlineWidth;
    CGFloat           m_fillHairlineWidth;

    CGAffineTransform m_baseAffineTransform;
    SwiffColor        m_multiplyColor;
    BOOL              m_hasBaseAffineTransform;
    BOOL              m_hasMultiplyColor;

    BOOL              m_shouldAntialias;
    BOOL              m_shouldSmoothFonts;
    BOOL              m_shouldSubpixelPositionFonts;
    BOOL              m_shouldSubpixelQuantizeFonts;
}

- (id) initWithMovie:(SwiffMovie *)movie;

- (void) renderPlacedObjects:(NSArray *)placedObjects inContext:(CGContextRef)context;

@property (nonatomic, strong, readonly) SwiffMovie *movie;

@property (nonatomic, assign) CGAffineTransform *baseAffineTransform;

// Hint to renderer about the original contentsScale of the context.  Used only for pixel-snapping, not scaling
@property (nonatomic, assign) CGFloat scaleFactorHint;

// When non-NULL, all rendered colors are multiplied by the specified color
@property (nonatomic, assign) SwiffColor *multiplyColor;

@property (nonatomic, assign) CGFloat hairlineWidth;
@property (nonatomic, assign) CGFloat fillHairlineWidth;

@property (nonatomic, assign) BOOL shouldAntialias;
@property (nonatomic, assign) BOOL shouldSmoothFonts;
@property (nonatomic, assign) BOOL shouldSubpixelPositionFonts;
@property (nonatomic, assign) BOOL shouldSubpixelQuantizeFonts;

@end

