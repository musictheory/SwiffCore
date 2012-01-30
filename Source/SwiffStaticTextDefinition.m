/*
    SwiffStaticText.m
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

#import "SwiffStaticTextDefinition.h"

#import "SwiffParser.h"
#import "SwiffStaticTextRecord.h"

@implementation SwiffStaticTextDefinition

- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie
{
    if ((self = [super init])) {
        m_movie = movie;
    
        SwiffParserReadUInt16(parser, &m_libraryID);
        SwiffParserReadRect(parser,   &m_bounds);
        SwiffParserReadMatrix(parser, &m_textTransform);

        UInt8 glyphBits, advanceBits;
        SwiffParserReadUInt8(parser, &glyphBits);
        SwiffParserReadUInt8(parser, &advanceBits);
    
        m_textRecords = [SwiffStaticTextRecord textRecordArrayWithParser:parser glyphBits:glyphBits advanceBits:advanceBits];
    }
    
    return self;
}


- (void) clearWeakReferences
{
    m_movie = nil;
}


- (CGRect) renderBounds
{
    return m_bounds;
}


@synthesize movie         = m_movie,
            libraryID     = m_libraryID,
            bounds        = m_bounds,
            textRecords   = m_textRecords,
            textTransform = m_textTransform;

@end
