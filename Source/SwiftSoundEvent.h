/*
    SwiftPlayedSound.h
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

typedef struct {
    UInt32 position;
    float  leftLevel;
    float  rightLevel;
} SwiftSoundEnvelope;

@class SwiftSoundDefinition;

@interface SwiftSoundEvent : NSObject {
@private
    UInt16     m_libraryID;
    NSString  *m_className;
    SwiftSoundDefinition *m_definition;

    NSUInteger m_inPoint;
    NSUInteger m_outPoint;
    NSInteger  m_loopCount;

    NSInteger  m_envelopeCount;
    SwiftSoundEnvelope *m_envelopes;

    BOOL m_shouldStop;
    BOOL m_allowsMultiple;
}

- (id) initWithParser:(SwiftParser *)parser;

- (void) getLeftLevel:(float *)outLeftLevel rightLevel:(float *)outRightLevel atPosition:(UInt32)position;

@property (nonatomic, assign, readonly) UInt16 libraryID;
@property (nonatomic, assign, readonly) NSString *className;
@property (nonatomic, assign, readonly) SwiftSoundDefinition *definition;

@property (nonatomic, assign, readonly) NSInteger envelopeCount; 
- (SwiftSoundEnvelope) envelopeAtIndex:(NSInteger)index;

@property (nonatomic, assign, readonly) NSUInteger inPoint;
@property (nonatomic, assign, readonly) NSUInteger outPoint;
@property (nonatomic, assign, readonly) NSInteger  loopCount;

@property (nonatomic, assign, readonly) BOOL shouldStop;
@property (nonatomic, assign, readonly) BOOL allowsMultiple;

@end
