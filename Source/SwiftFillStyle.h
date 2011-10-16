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

#import <Foundation/Foundation.h>

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

@class SwiftGradient;

@interface SwiftFillStyle : NSObject {
@private
    SwiftFillStyleType m_type;
    SwiftColor         m_color;
    SwiftGradient     *m_gradient;
    CGAffineTransform  m_gradientTransform;
}

// Reads a FILLSTYLEARRAY from the parser
+ (NSArray *) fillStyleArrayWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)tagVersion;

// Reads a FILLSTYLE from the parser
- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)tagVersion;

@property (nonatomic, readonly, assign) SwiftFillStyleType type;

@property (nonatomic, readonly, assign) SwiftColor color;

// Inside pointer, valid for lifetime of the SwiftFillStyle
@property (nonatomic, assign, readonly) SwiftColor *colorPointer;

@property (nonatomic, readonly, retain) SwiftGradient *gradient;
@property (nonatomic, readonly, assign) CGAffineTransform gradientTransform;

@end
