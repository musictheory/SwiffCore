/*
    SwiffLineStyle.h
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
#import <SwiffParser.h>

@class SwiffFillStyle;


extern const CGFloat SwiffLineStyleHairlineWidth;

@interface SwiffLineStyle : NSObject {
    CGFloat         m_width;
    SwiffColor      m_color;
    SwiffFillStyle *m_fillStyle;

    CGLineCap       m_startLineCap;
    CGLineCap       m_endLineCap;
    CGLineJoin      m_lineJoin;
    CGFloat         m_miterLimit;

    BOOL            m_scalesHorizontally;
    BOOL            m_scalesVertically;
    BOOL            m_pixelAligned;
    BOOL            m_closesStroke;
}

// Reads a LINESTYLEARRAY from the parser
+ (NSArray *) lineStyleArrayWithParser:(SwiffParser *)parser;

// Reads a LINESTYLE from the parser
- (id) initWithParser:(SwiffParser *)parser;

@property (nonatomic, readonly, assign) CGFloat width;
@property (nonatomic, readonly, assign) SwiffColor color;
@property (nonatomic, readonly, strong) SwiffFillStyle *fillStyle;

// Inside pointer, valid for lifetime of the SwiffLineStyle
@property (nonatomic, assign, readonly) SwiffColor *colorPointer;

@property (nonatomic, readonly, assign) CGLineCap startLineCap;
@property (nonatomic, readonly, assign) CGLineCap endLineCap;
@property (nonatomic, readonly, assign) CGLineJoin lineJoin;
@property (nonatomic, readonly, assign) CGFloat miterLimit;

@property (nonatomic, readonly, assign, getter=isPixelAligned) BOOL pixelAligned;
@property (nonatomic, readonly, assign) BOOL scalesHorizontally;
@property (nonatomic, readonly, assign) BOOL scalesVertically;
@property (nonatomic, readonly, assign) BOOL closesStroke;

@end
