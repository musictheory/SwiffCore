/*
    SwiftFillStyle.h
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

#import <SwiftImport.h>
#import <SwiftBase.h>
#import <SwiftParser.h>

@class SwiftGradient;


enum {
    SwiftFillStyleTypeColor = 0,

    SwiftFillStyleTypeLinearGradient             = 0x10,
    SwiftFillStyleTypeRadialGradient             = 0x12,
    SwiftFillStyleTypeFocalRadialGradient        = 0x13,

    SwiftFillStyleTypeRepeatingBitmap            = 0x40,
    SwiftFillStyleTypeClippedBitmap              = 0x41,
    SwiftFillStyleTypeNonSmoothedRepeatingBitmap = 0x42,
    SwiftFillStyleTypeNonSmoothedClippedBitmap   = 0x43
};
typedef NSInteger SwiftFillStyleType;


@interface SwiftFillStyle : NSObject {
@private
    SwiftFillStyleType m_type;
    
    union {
        struct {
            SwiftColor color;
        };
        struct {
            SwiftGradient *gradient;
            CGAffineTransform  gradientTransform;
        };
        struct {
            NSUInteger bitmapID;
            CGAffineTransform bitmapTransform;
        };
    } m_content;
}

// Reads a FILLSTYLEARRAY from the parser
+ (NSArray *) fillStyleArrayWithParser:(SwiftParser *)parser;

// Reads a FILLSTYLE from the parser
- (id) initWithParser:(SwiftParser *)parser;

@property (nonatomic, readonly, assign) SwiftFillStyleType type;

// These properties are valid when type is SwiftFillStyleTypeColor
@property (nonatomic, readonly, assign) SwiftColor color;
@property (nonatomic, assign, readonly) SwiftColor *colorPointer;  // Inside pointer, valid for lifetime of the SwiftFillStyle

// These properties are valid when type is SwiftFillStyleType...Gradient
@property (nonatomic, readonly, retain) SwiftGradient *gradient;
@property (nonatomic, readonly, assign) CGAffineTransform gradientTransform;

// These properties are valid when type is SwiftFillStyleType...Bitmap
@property (nonatomic, readonly, assign) UInt16 bitmapID;
@property (nonatomic, readonly, assign) CGAffineTransform bitmapTransform;

@end
