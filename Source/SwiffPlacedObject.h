/*
    SwiffPlacedObject.h
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
#import <SwiffBase.h>
#import <SwiffImport.h>
#import <SwiffDefinition.h>


@interface SwiffPlacedObject : NSObject {
@package
    UInt16               m_libraryID;
    UInt16               m_depth;
    CGAffineTransform    m_affineTransform;
    void                *m_additional;      // Keep less commonly used ivars here
}

- (id) initWithDepth:(NSInteger)depth;
- (id) initWithPlacedObject:(SwiffPlacedObject *)placedObject;

// Called after libraryID has changed, allows subclasses to setup variables based on definition
- (void) setupWithDefinition:(id<SwiffDefinition>)definition;

@property (nonatomic, copy)   NSString *name;
@property (nonatomic, assign) UInt16 libraryID;
@property (nonatomic, assign) UInt16 depth;
@property (nonatomic, assign) UInt16 clipDepth;
@property (nonatomic, assign) CGFloat ratio;
@property (nonatomic, assign) CGAffineTransform affineTransform;
@property (nonatomic, assign) SwiffColorTransform colorTransform;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
@property (nonatomic, assign) BOOL wantsLayer;

// Inside pointers, valid for lifetime of the SwiffPlacedObject
@property (nonatomic, assign, readonly) CGAffineTransform   *affineTransformPointer;
@property (nonatomic, assign, readonly) SwiffColorTransform *colorTransformPointer;

@property (nonatomic, assign, readonly) BOOL hasAffineTransform;
@property (nonatomic, assign, readonly) BOOL hasColorTransform;

@end
