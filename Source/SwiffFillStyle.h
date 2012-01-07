/*
    SwiffFillStyle.h
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
#import <SwiffParser.h>

@class SwiffGradient;


enum {
    SwiffFillStyleTypeColor = 0,

    SwiffFillStyleTypeLinearGradient             = 0x10,
    SwiffFillStyleTypeRadialGradient             = 0x12,
    SwiffFillStyleTypeFocalRadialGradient        = 0x13,

    SwiffFillStyleTypeRepeatingBitmap            = 0x40,
    SwiffFillStyleTypeClippedBitmap              = 0x41,
    SwiffFillStyleTypeNonSmoothedRepeatingBitmap = 0x42,
    SwiffFillStyleTypeNonSmoothedClippedBitmap   = 0x43
};
typedef NSInteger SwiffFillStyleType;


@interface SwiffFillStyle : NSObject {
@private
    SwiffFillStyleType m_type;
    
    union {
        struct {
            SwiffColor color;
        };
        struct {
            SwiffGradient *gradient;
            CGAffineTransform  gradientTransform;
        };
        struct {
            NSUInteger bitmapID;
            CGAffineTransform bitmapTransform;
        };
    } m_content;
}

// Reads a FILLSTYLEARRAY from the parser
+ (NSArray *) fillStyleArrayWithParser:(SwiffParser *)parser;

// Reads a FILLSTYLE from the parser
- (id) initWithParser:(SwiffParser *)parser;

@property (nonatomic, readonly, assign) SwiffFillStyleType type;

// These properties are valid when type is SwiffFillStyleTypeColor
@property (nonatomic, readonly, assign) SwiffColor color;
@property (nonatomic, assign, readonly) SwiffColor *colorPointer;  // Inside pointer, valid for lifetime of the SwiffFillStyle

// These properties are valid when type is SwiffFillStyleType...Gradient
@property (nonatomic, readonly, retain) SwiffGradient *gradient;
@property (nonatomic, readonly, assign) CGAffineTransform gradientTransform;

// These properties are valid when type is SwiffFillStyleType...Bitmap
@property (nonatomic, readonly, assign) UInt16 bitmapID;
@property (nonatomic, readonly, assign) CGAffineTransform bitmapTransform;

@end
