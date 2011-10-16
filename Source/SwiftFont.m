/*
    SwiftFont.m
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


#import "SwiftFont.h"
#import "SwiftParser.h"


@interface SwiftFont (CalledByMovie)

@end


@implementation SwiftFont

- (id) initWithLibraryID:(NSInteger)libraryID
{
    if ((self = [super init])) {
        m_libraryID = libraryID;
    }
    
    return self;
}


#pragma mark -
#pragma mark Called by Movie




- (void) _readCodeTable
{

}




- (void) readDefineFontTagFromParser:(SwiftParser *)parser version:(NSInteger)version
{


    if (version == 1) {
        // ...the number of entries in each table (the number of glyphs in the font) can be inferred
        // by dividing the first entry in the OffsetTable by two.
        UInt16 offset;
        SwiftParserReadUInt16(parser, &offset);
        m_glyphCount = (offset / 2);

        SwiftParserAdvance(parser, (m_glyphCount - 1) * sizeof(UInt16));

#if 0
        tag->glyph = malloc(tag->glyphCount * sizeof(void *));
        SWFShape *glyphBuffer = malloc(tag->glyphCount * sizeof(SWFShapeRecord));

        UInt32 i;
        for (i = 0; i < tag->glyphCount; i++) {
            SWFShape *shape = &glyphBuffer[i];
            tag->glyph[i] = shape;

            SWFParserReadShapeAndCreateContents(parser, shape, 0);
        }
#endif

    } else {
        UInt32 hasLayout, isShiftJIS, isSmallText, isANSIEncoding,
               usesWideOffsets, usesWideCodes, isItalic, isBold;

        SwiftParserReadUBits(parser, 1, &hasLayout);
        SwiftParserReadUBits(parser, 1, &isShiftJIS);
        SwiftParserReadUBits(parser, 1, &isSmallText);
        SwiftParserReadUBits(parser, 1, &isANSIEncoding);
        SwiftParserReadUBits(parser, 1, &usesWideOffsets);
        SwiftParserReadUBits(parser, 1, &usesWideCodes);
        SwiftParserReadUBits(parser, 1, &isItalic);
        SwiftParserReadUBits(parser, 1, &isBold);

        m_hasLayout     = hasLayout;
        m_smallText     = isSmallText;
        m_italic        = isItalic;
        m_bold          = isBold;

        UInt8 languageCode;
        SwiftParserReadUInt8(parser, &languageCode);
        m_languageCode = languageCode;
    
        NSString *name;
        SwiftParserReadPascalString(parser, &name);
        m_name = [name retain];
        
        UInt16 glyphCount;
        SwiftParserReadUInt16(parser, &glyphCount);

#if 0

        // Burn through OffsetTable
        if (usesWideOffsets) {
            UInt32 unused;
            SwiftParserAdvance(parser, tag->glyphCount * sizeof(UInt32));
            SwiftParserReadUInt32(parser, &unused);
        } else {
            UInt16 unused;
            SwiftParserAdvance(parser, tag->glyphCount * sizeof(UInt16));
            SwiftParserReadUInt16(parser, &unused);
        }

        tag->glyph        = calloc(tag->glyphCount, sizeof(void *));
        tag->codeTable    = calloc(tag->glyphCount, sizeof(UInt16));
        tag->advanceTable = calloc(tag->glyphCount, sizeof(SInt16));
        tag->boundsTable  = calloc(tag->glyphCount, sizeof(SWFRect));

        UInt32 i;
        for (i = 0; i < tag->glyphCount; i++) {
            SWFShape *shape = malloc(sizeof(SWFShape));
            tag->glyph[i] = shape;

            SWFParserReadShapeAndCreateContents(parser, shape, 0);
        }
        
        for (i = 0; i < tag->glyphCount; i++) {
            if (usesWideCodes) {
                SWFParserReadUInt16(parser, &tag->codeTable[i]);
            } else {
                UInt8 codeTableValue;
                SWFParserReadUInt8(parser, &codeTableValue);
                tag->codeTable[i] = codeTableValue;
            }
        }
        
        if (hasLayout) {
            SWFParserReadSInt16(parser, &tag->ascenderHeight);
            SWFParserReadSInt16(parser, &tag->descenderHeight);
            SWFParserReadSInt16(parser, &tag->leadingHeight);
            
            for (i = 0; i < tag->glyphCount; i++) {
                SWFParserReadSInt16(parser, &tag->advanceTable[i]);
            }

            for (i = 0; i < tag->glyphCount; i++) {
                SWFParserReadRect(parser, &tag->boundsTable[i]);
            }

            // Don't read kerning count
        }
#endif

    }



}

- (void) readDefineFontNameTagFromParser:(SwiftParser *)parser version:(NSInteger)version
{
    NSString *name      = nil;
    NSString *copyright = nil;

    // DefineFontName tags were introduced in 9.0, hence, they must be UTF-8
    SwiftParserReadStringWithEncoding(parser, NSUTF8StringEncoding, &name);
    SwiftParserReadStringWithEncoding(parser, NSUTF8StringEncoding, &copyright);
    
    m_fullName  = [name retain];
    m_copyright = [copyright retain];
}


- (void) readDefineFontInfoTagFromParser:(SwiftParser *)parser version:(NSInteger)version
{
    UInt32 reserved, isSmallText, isShiftJIS, isANSIEncoding, isItalic, isBold, usesWideCodes;

    NSString *name;
    SwiftParserReadPascalString(parser, &name);
    m_name = [name retain];

    SwiftParserReadUBits(parser, 2, &reserved);
    SwiftParserReadUBits(parser, 1, &isSmallText);
    SwiftParserReadUBits(parser, 1, &isShiftJIS);
    SwiftParserReadUBits(parser, 1, &isANSIEncoding);
    SwiftParserReadUBits(parser, 1, &isItalic);
    SwiftParserReadUBits(parser, 1, &isBold);
    SwiftParserReadUBits(parser, 1, &usesWideCodes);
    
    m_smallText    = isSmallText;
    m_italic       = isItalic;
    m_bold         = isBold;
    
    if (version == 2) {
        UInt8 languageCode;
        SwiftParserReadUInt8(parser, &languageCode);
        m_languageCode = languageCode;
    }

    
#if 0    
    UInt32 glyphCount = SwiftParserGetBytesRemainingInCurrentTag(parser);
    if (usesWideCodes) glyphCount /= 2;
    
    UInt16 *codeTable = malloc(glyphCount * sizeof(UInt16));
    UInt16 *codeTablePtr = codeTable;

    while (parser->b < parser->endOfCurrentTag) {
        if (usesWideCodes) {
            SWFParserReadUInt16(parser, codeTablePtr);
        } else {
            UInt8 value;
            SWFParserReadUInt8(parser, &value);
            *codeTablePtr = value;
        }

        codeTablePtr++;
    }
#endif
}


#pragma mark -
#pragma mark Accessors

@synthesize libraryID       = m_libraryID,
            languageCode    = m_languageCode,
            name            = m_name,
            fullName        = m_fullName,
            copyright       = m_copyright,
            ascenderHeight  = m_ascenderHeight,
            descenderHeight = m_descendingHeight,
            leadingHeight   = m_leadingHeight,
            bold            = m_bold,
            italic          = m_italic,
            pixelAligned    = m_pixelAligned,
            hasLayoutInformation = m_hasLayoutInformation;

@end
