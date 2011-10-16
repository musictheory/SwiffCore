/*
    SwiftPlacedObject.h
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

@interface SwiftPlacedObject : NSObject <NSCopying> {
@private
    UInt16               m_objectID;
    UInt16               m_depth;
    UInt16               m_clipDepth;
    UInt16               m_ratio;
    NSString            *m_instanceName;
    SwiftColorTransform *m_colorTransformPtr;
    CGAffineTransform    m_affineTransform;
}

- (id) initWithDepth:(NSInteger)depth;

@property (nonatomic, copy,   readonly) NSString *instanceName;
@property (nonatomic, assign, readonly) UInt16 objectID;
@property (nonatomic, assign, readonly) UInt16 depth;
@property (nonatomic, assign, readonly) UInt16 clipDepth;
@property (nonatomic, assign, readonly) CGFloat ratio;
@property (nonatomic, assign, readonly) CGAffineTransform affineTransform;
@property (nonatomic, assign, readonly) SwiftColorTransform colorTransform;

// Inside pointers, valid for lifetime of the SwiftPlacedObject
@property (nonatomic, assign, readonly) CGAffineTransform   *affineTransformPointer;
@property (nonatomic, assign, readonly) SwiftColorTransform *colorTransformPointer;

@property (nonatomic, assign, readonly) BOOL hasAffineTransform;
@property (nonatomic, assign, readonly) BOOL hasColorTransform;

@end
