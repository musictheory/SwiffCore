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


#import "SwiftFontDefinition.h"
#import "SwiftParser.h"


@implementation SwiftFontDefinition

- (id) initWithLibraryID:(UInt16)libraryID movie:(SwiftMovie *)movie
{
    if ((self = [super init])) {
        m_movie = movie;
        m_libraryID = libraryID;
    }
    
    return self;
}


- (void) dealloc
{
    [m_name      release];  m_name      = nil;
    [m_fullName  release];  m_fullName  = nil;
    [m_copyright release];  m_copyright = nil;
    
    if (m_fontDescriptor) {
        CFRelease(m_fontDescriptor);
        m_fontDescriptor = NULL;
    }
    
    free(m_codeTable);
    
    [super dealloc];
}


- (void) clearWeakReferences
{
    m_movie = nil;
}


#pragma mark -
#pragma mark Called by Movie

- (void) _readCodeTableFromParser:(SwiftParser *)parser wide:(BOOL)wide
{
    m_codeTable = malloc(m_glyphCount * sizeof(UInt16));

    for (NSUInteger i = 0; i < m_glyphCount; i++) {
        UInt16 value;

        if (wide) {
            SwiftParserReadUInt16(parser, &value);
        } else {
            UInt8 value8;
            SwiftParserReadUInt8(parser, &value8);
            value = value8;
        }

        m_codeTable[i] = value;
    }
}


- (void) readDefineFontTagFromParser:(SwiftParser *)parser
{
    NSInteger version = SwiftParserGetCurrentTagVersion(parser);

    if (version == 1) {
        // Per documentation:
        // "...the number of entries in each table (the number of glyphs in the font) can be inferred
        // by dividing the first entry in the OffsetTable by two."
        //
        UInt16 offset;
        SwiftParserReadUInt16(parser, &offset);
        m_glyphCount = (offset / 2);

        // Not yet implemented: Glyph Text Support
        // Read offset table here
        // Read shape table here

    } else if (version == 2 || version == 3) {
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

        m_italic    = isItalic;
        m_bold      = isBold;
        // Not yet implemented: Glyph Text Support.
        // Save isANSIEncoding, isShiftJIS, isSmallText for later use

        UInt8 languageCode;
        SwiftParserReadUInt8(parser, &languageCode);
        // Not yet implemented: Glyph Text Support.
        // Save languageCode for later use
    
        NSString *name = nil;
        SwiftParserReadPascalString(parser, &name);
        m_name = [name retain];
        
        UInt16 glyphCount;
        SwiftParserReadUInt16(parser, &glyphCount);
        m_glyphCount = glyphCount;
    
        // Not yet implemented: Glyph Text Support.
        // Read OffsetTable.  For now, just advance through it, since we need CodeTableOffset
        NSInteger bytesInOffsetTable = (usesWideOffsets ? sizeof(UInt32) : sizeof(UInt16)) * glyphCount;
        NSInteger skippedBytes       = bytesInOffsetTable;
        SwiftParserAdvance(parser, bytesInOffsetTable);

        // Read CodeTableOffset, and advance to CodeTable
        if (usesWideOffsets) {
            UInt32 bytesFromOffsetTableToCodeTable;
            SwiftParserReadUInt32(parser, &bytesFromOffsetTableToCodeTable);

            skippedBytes += sizeof(UInt32);
            SwiftParserAdvance(parser, bytesFromOffsetTableToCodeTable - skippedBytes);

        } else {
            UInt16 bytesFromOffsetTableToCodeTable;
            SwiftParserReadUInt16(parser, &bytesFromOffsetTableToCodeTable);

            skippedBytes += sizeof(UInt16);
            SwiftParserAdvance(parser, bytesFromOffsetTableToCodeTable - skippedBytes);
        }

        [self _readCodeTableFromParser:parser wide:usesWideCodes];
        
        if (hasLayout) {
            // Not yet implemented: Glyph Text Support.
            // Read FontAscent,  SI16
            // Read FontDescent, SI16
            // Read FontLeading, SI16
            // Read FontAdvanceTable, SI16[nGlyphs]
            // Read FontBoundsTable,  RECT[nGlyphs]
            // Read KerningCount, UI16
            // Read FontKerningTable KERNINGRECORD[KerningCount]
        }

    } else if (version == 4) {
        // Not yet implemented: DefineFont4 support
    }
}


- (void) readDefineFontNameTagFromParser:(SwiftParser *)parser
{
    NSString *name      = nil;
    NSString *copyright = nil;

    // DefineFontName tags were introduced in 9.0, hence, they must be UTF-8
    SwiftParserReadStringWithEncoding(parser, NSUTF8StringEncoding, &name);
    SwiftParserReadStringWithEncoding(parser, NSUTF8StringEncoding, &copyright);
    
    m_fullName  = [name retain];
    m_copyright = [copyright retain];
}


- (void) readDefineFontInfoTagFromParser:(SwiftParser *)parser
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
    
    m_italic = isItalic;
    m_bold   = isBold;
    // Not yet implemented: Glyph Text Support.
    // Save isANSIEncoding, isShiftJIS, isSmallText for later use

    NSInteger version = SwiftParserGetCurrentTagVersion(parser);
    if (version == 2) {
        UInt8 languageCode;
        SwiftParserReadUInt8(parser, &languageCode);
        // Not yet implemented: Glyph Text Support.
        // Save languageCode for later use
    }

    m_glyphCount = SwiftParserGetBytesRemainingInCurrentTag(parser);
    if (usesWideCodes) m_glyphCount /= 2;
    
    [self _readCodeTableFromParser:parser wide:usesWideCodes];
}


- (void) readDefineFontAlignZonesFromParser:(SwiftParser *)parser
{
    // Not yet implemented: Font Align Zones
}


#pragma mark -
#pragma mark Accessors

- (CTFontDescriptorRef) fontDescriptor
{
    if (!m_fontDescriptor) {
        for (NSString *name in [m_name componentsSeparatedByString:@","]) {
            name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            if      ([name isEqualToString:@"_sans"])       name = @"Helvetica";
            else if ([name isEqualToString:@"_serif"])      name = @"Times";
            else if ([name isEqualToString:@"_typewriter"]) name = @"Courier";

            CTFontRef font = CTFontCreateWithName((CFStringRef)name, 12.0, &CGAffineTransformIdentity);
            if (!font) continue;

            CTFontSymbolicTraits traits = CTFontGetSymbolicTraits(font);
            CTFontSymbolicTraits mask   = (kCTFontItalicTrait | kCTFontBoldTrait);
        
            if (m_bold)   traits |= kCTFontBoldTrait;
            if (m_italic) traits |= kCTFontItalicTrait;

            CTFontRef fontWithTraits = CTFontCreateCopyWithSymbolicTraits(font, CTFontGetSize(font), NULL, traits, mask);
            m_fontDescriptor = CTFontCopyFontDescriptor(fontWithTraits);

            if (fontWithTraits) CFRelease(fontWithTraits);
            if (font) CFRelease(font);
            
            if (m_fontDescriptor) {
                break;
            }
        }
    }

    return m_fontDescriptor;
}


@synthesize movie           = m_movie,
            libraryID       = m_libraryID,
            name            = m_name,
            fullName        = m_fullName,
            copyright       = m_copyright,
            glyphCount      = m_glyphCount,
            codeTable       = m_codeTable,
            fontDescriptor  = m_fontDescriptor,
            bold            = m_bold,
            italic          = m_italic;

@end
