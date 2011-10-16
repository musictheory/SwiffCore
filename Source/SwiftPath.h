/*
    SwiftPath.h
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


extern const CGFloat SwiftPathOperationMove;  // Followed by { CGFloat toX, CGFloat toY }
extern const CGFloat SwiftPathOperationLine;  // Followed by { CGFloat toX, CGFloat toY }
extern const CGFloat SwiftPathOperationCurve; // Followed by { CGFloat toX, CGFloat toY, CGFloat controlX, CGFloat controlY }
extern const CGFloat SwiftPathOperationEnd;   // Followed by { NAN, NAN }.  Designates end of CGFloat array

@class SwiftLineStyle;
@class SwiftFillStyle;


@interface SwiftPath : NSObject {
@private
    CGFloat        *m_operations;
    NSUInteger      m_operationsCount;
    NSUInteger      m_operationsCapacity;
    SwiftLineStyle *m_lineStyle;
    SwiftFillStyle *m_fillStyle;
}

- (id) initWithLineStyle:(SwiftLineStyle *)lineStyle fillStyle:(SwiftFillStyle *)fillStyle;

/*
    Example operations array for "Move to (2,3) and then draw a line to (6, 5)":
    {
        SwiftPathOperationMove, 2.0, 3.0,
        SwiftPathOperationLine, 6.0, 5.0,
        SwiftPathOperationEnd,  NAN, NAN
    }
*/
@property (nonatomic, assign, readonly) CGFloat *operations; // Inside pointer, valid for lifetime of the SwiftPath

@property (nonatomic, retain, readonly) SwiftLineStyle *lineStyle;
@property (nonatomic, retain, readonly) SwiftFillStyle *fillStyle;

@end
