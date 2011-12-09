/*
    SwiffStaticTextRecord.h
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
#import <SwiffParser.h>


typedef struct _SwiffTextRecordGlyphEntry {
    UInt16  index;
    CGFloat advance;
} SwiffStaticTextRecordGlyphEntry;


@interface SwiffStaticTextRecord : NSObject {
@private
    SwiffStaticTextRecordGlyphEntry *m_glyphEntries;
    NSUInteger  m_glyphEntriesCount;

    CGFloat     m_xOffset;
    CGFloat     m_yOffset;
    CGFloat     m_textHeight;
    SwiffColor  m_color;

    UInt16      m_fontID;
    BOOL        m_hasFont;
    BOOL        m_hasColor;
    BOOL        m_hasXOffset;
    BOOL        m_hasYOffset;
}

+ (NSArray *) textRecordArrayWithParser:(SwiffParser *)parser glyphBits:(UInt8)glyphBits advanceBits:(UInt8)advanceBits;

- (id) initWithParser:(SwiffParser *)parser glyphBits:(UInt8)glyphBits advanceBits:(UInt8)advanceBits;

@property (nonatomic, assign, readonly) BOOL hasFont;
@property (nonatomic, assign, readonly) UInt16 fontID;
@property (nonatomic, assign, readonly) CGFloat textHeight;

@property (nonatomic, assign, readonly) BOOL hasColor;
@property (nonatomic, assign, readonly) SwiffColor color;
@property (nonatomic, assign, readonly) SwiffColor *colorPointer;

@property (nonatomic, assign, readonly) BOOL hasXOffset;
@property (nonatomic, assign, readonly) CGFloat xOffset;

@property (nonatomic, assign, readonly) BOOL hasYOffset;
@property (nonatomic, assign, readonly) CGFloat yOffset;

@property (nonatomic, assign, readonly) NSUInteger glyphEntriesCount;
@property (nonatomic, assign, readonly) SwiffStaticTextRecordGlyphEntry *glyphEntries;

@end
