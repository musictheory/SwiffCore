/*
    SwiftTextRecord.m
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

#import "SwiftTextRecord.h"

#import "SwiftParser.h"

@implementation SwiftTextRecord

+ (NSArray *) textRecordArrayWithParser: (SwiftParser *) parser
                                    tag: (SwiftTag) tag
                                version: (NSInteger) version
                              glyphBits: (UInt8) glyphBits
                            advanceBits: (UInt8) advanceBits

{
    NSMutableArray  *result = [NSMutableArray array];
    SwiftTextRecord *record = nil;

    do {
        record = [[SwiftTextRecord alloc] initWithParser:parser tag:tag version:version glyphBits:glyphBits advanceBits:advanceBits];
        if (record) [result addObject:record];
        [record release];
    } while (record);

    return result;
}


- (id) initWithParser: (SwiftParser *) parser
                  tag: (SwiftTag) tag
              version: (NSInteger) version
            glyphBits: (UInt8) glyphBits
          advanceBits: (UInt8) advanceBits
{
    if ((self = [super init])) {
        SwiftParserByteAlign(parser);
    
        UInt32 textRecordType, reserved, hasFont, hasColor, hasYOffset, hasXOffset;
        SwiftParserReadUBits(parser, 1, &textRecordType);
        SwiftParserReadUBits(parser, 3, &reserved);
        SwiftParserReadUBits(parser, 1, &hasFont);
        SwiftParserReadUBits(parser, 1, &hasColor);
        SwiftParserReadUBits(parser, 1, &hasYOffset);
        SwiftParserReadUBits(parser, 1, &hasXOffset);
        
        if (textRecordType == 1) {
            m_hasFont  = hasFont;
            m_hasColor = hasColor;
            
            if (hasFont) {
                UInt16 fontID;
                SwiftParserReadUInt16(parser, &fontID);
                m_fontID = fontID;
            }

            if (hasColor) {
                if (version >= 2) {
                    SwiftParserReadColorRGBA(parser, &m_color);
                } else {
                    SwiftParserReadColorRGB(parser, &m_color);
                }
            }
            
            if (hasXOffset) {
                SInt16 x = 0;
                SwiftParserReadSInt16(parser, &x);
                m_offset.x = (x / 20.0);
            }

            if (hasYOffset) {
                SInt16 y = 0;
                SwiftParserReadSInt16(parser, &y);
                m_offset.y = (y / 20.0);
            }
            
            if (hasFont) {
                UInt16 height;
                SwiftParserReadUInt16(parser, &height);
                m_height = (height / 20.0);
            }
            
            UInt8 glyphCount;
            SwiftParserReadUInt8(parser, &glyphCount);
            m_glyphCount = glyphCount;

            m_glyphIndex   = calloc(glyphCount, sizeof(UInt16));
            m_glyphAdvance = calloc(glyphCount, sizeof(CGFloat));

            UInt8 i;
            for (i = 0; i < m_glyphCount; i++) {
                UInt32 glyphIndex   = 0;
                SInt32 glyphAdvance = 0;

                SwiftParserReadUBits(parser, glyphBits,   &glyphIndex);
                SwiftParserReadSBits(parser, advanceBits, &glyphAdvance);
                
                m_glyphIndex[i]   = (UInt16)glyphIndex;
                m_glyphAdvance[i] = glyphAdvance;
            }
            
        } else {
            [self release];
            return nil;
        }
        
        if (!SwiftParserIsValid(parser)) {
            [self release];
            return nil;
        }
    }
    
    return self;
}


- (void) dealloc
{
    if (m_glyphIndex) {
        free(m_glyphIndex);
        m_glyphIndex = NULL;
    }

    if (m_glyphAdvance) {
        free(m_glyphAdvance);
        m_glyphAdvance = NULL;
    }
    
    [super dealloc];
}

@end
