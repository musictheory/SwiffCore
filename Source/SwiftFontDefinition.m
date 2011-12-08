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
#import "SwiftShapeDefinition.h"

const CGFloat SwiftFontEmSquareHeight = 1024;


static CGPathRef sCreatePathFromShapeRecord(SwiftParser *parser)
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, 0);

    CGAffineTransform transform = CGAffineTransformMakeScale(1 / 20.0, 1 / 20.0);
    const CGAffineTransform *m = NULL;
    
    if ((SwiftParserGetCurrentTag(parser) == SwiftTagDefineFont) && (SwiftParserGetCurrentTagVersion(parser) == 3)) {
        m = &transform;
    }

    SwiftPoint position = { 0, 0 };

    UInt32 fillBits, lineBits;
    SwiftParserReadUBits(parser, 4, &fillBits);
    SwiftParserReadUBits(parser, 4, &lineBits);

    BOOL foundEndRecord = NO;
    while (!foundEndRecord) {
        UInt32 typeFlag;
        SwiftParserReadUBits(parser, 1, &typeFlag);

        if (typeFlag == 0) {
            UInt32 newStyles, changeLineStyle, changeFillStyle0, changeFillStyle1, moveTo, unused;
            SwiftParserReadUBits(parser, 1, &newStyles);
            SwiftParserReadUBits(parser, 1, &changeLineStyle);
            SwiftParserReadUBits(parser, 1, &changeFillStyle1);
            SwiftParserReadUBits(parser, 1, &changeFillStyle0);
            SwiftParserReadUBits(parser, 1, &moveTo);
            
            // ENDSHAPERECORD
            if ((newStyles + changeLineStyle + changeFillStyle1 + changeFillStyle0 + moveTo) == 0) {
                foundEndRecord = YES;

            // STYLECHANGERECORD
            } else {
                if (moveTo) {
                    UInt32 moveBits;
                    SwiftParserReadUBits(parser, 5, &moveBits);
                    
                    SInt32 x, y;
                    SwiftParserReadSBits(parser, moveBits, &x);
                    SwiftParserReadSBits(parser, moveBits, &y);

                    position.x = x;
                    position.y = y;
                    
                    CGPathMoveToPoint(path, m, position.x, position.y);
                }
                
                if (changeFillStyle0) SwiftParserReadUBits(parser, fillBits, &unused);
                if (changeFillStyle1) SwiftParserReadUBits(parser, fillBits, &unused);
                if (changeLineStyle)  SwiftParserReadUBits(parser, lineBits, &unused);

                if (newStyles) {
                    SwiftWarn(@"STYLECHANGERECORD.newStyles = YES for a DefineFont tag");
                }
            }
            
        } else {
            UInt32 straightFlag, numBits;
            SwiftParserReadUBits(parser, 1, &straightFlag);
            SwiftParserReadUBits(parser, 4, &numBits);
            
            // STRAIGHTEDGERECORD
            if (straightFlag) {
                UInt32 generalLineFlag;
                SInt32 vertLineFlag = 0, deltaX = 0, deltaY = 0;

                SwiftParserReadUBits(parser, 1, &generalLineFlag);

                if (generalLineFlag == 0) {
                    SwiftParserReadSBits(parser, 1, &vertLineFlag);
                }

                if (generalLineFlag || !vertLineFlag) {
                    SwiftParserReadSBits(parser, numBits + 2, &deltaX);
                }

                if (generalLineFlag || vertLineFlag) {
                    SwiftParserReadSBits(parser, numBits + 2, &deltaY);
                }

                position.x += deltaX;
                position.y += deltaY;

                CGPathAddLineToPoint(path, m, position.x, position.y);
            
            // CURVEDEDGERECORD
            } else {
                SInt32 controlDeltaX = 0, controlDeltaY = 0, anchorDeltaX = 0, anchorDeltaY = 0;
                       
                SwiftParserReadSBits(parser, numBits + 2, &controlDeltaX);
                SwiftParserReadSBits(parser, numBits + 2, &controlDeltaY);
                SwiftParserReadSBits(parser, numBits + 2, &anchorDeltaX);
                SwiftParserReadSBits(parser, numBits + 2, &anchorDeltaY);

                SwiftPoint control = {
                    position.x + controlDeltaX,
                    position.y + controlDeltaY,
                };

                position.x = control.x + anchorDeltaX;
                position.y = control.y + anchorDeltaY;

                CGPathAddQuadCurveToPoint(path, m, control.x, control.y, position.x, position.y);
            }
        }
        
        //!spec: "Each individual shape record is byte-aligned within
        //        an array of shape records" (page 134)
        //
        // In practice, this is not the case.  Hence, leave the next line commented:
        // SwiftParserByteAlign(parser);
    }

    SwiftParserByteAlign(parser);
    CGPathCloseSubpath(path);

    return path;
}


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
    
    if (m_glyphPaths) {
        for (NSInteger i = 0; i < m_glyphCount; i++) {
            CGPathRelease(m_glyphPaths[i]);
            m_glyphPaths[i] = NULL;
        }
    }

    free(m_glyphPaths);       m_glyphPaths     = NULL;
    free(m_codeTable);        m_codeTable      = NULL;
    free(m_glyphAdvances);    m_glyphAdvances  = NULL;
    free(m_glyphBounds);      m_glyphBounds    = NULL;
    free(m_kerningRecords);   m_kerningRecords = NULL;
    
    [super dealloc];
}


- (void) clearWeakReferences
{
    m_movie = nil;
}


#pragma mark -
#pragma mark Called by Movie


- (void) _readGlyphPathsFromParser:(SwiftParser *)parser
{
    m_glyphPaths = calloc(sizeof(CGPathRef), m_glyphCount);

    for (NSInteger i = 0; i < m_glyphCount; i++) {
        m_glyphPaths[i] = sCreatePathFromShapeRecord(parser);
    }
}


- (void) _readCodeTableFromParser:(SwiftParser *)parser wide:(BOOL)wide
{
    if (!m_codeTable) {
        m_codeTable = malloc(m_glyphCount * sizeof(UInt16));
    }

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

        // Skip through OffsetTable
        SwiftParserAdvance(parser, sizeof(UInt16) * m_glyphCount);

        [self _readGlyphPathsFromParser:parser];

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

        m_italic = isItalic;
        m_bold   = isBold;
        m_smallText = isSmallText;

        if (isANSIEncoding) {
            m_encoding = SwiftGetANSIStringEncoding();
        } else if (isShiftJIS) {
            m_encoding = NSShiftJISStringEncoding;
        } else {
            m_encoding = NSUnicodeStringEncoding;
        }

        UInt8 languageCode;
        SwiftParserReadUInt8(parser, &languageCode);
        m_languageCode = languageCode;
    
        NSString *name = nil;
        SwiftParserReadLengthPrefixedString(parser, &name);
        m_name = [name retain];
        
        UInt16 glyphCount;
        SwiftParserReadUInt16(parser, &glyphCount);
        m_glyphCount = glyphCount;
    
        // Skip OffsetTable and CodeTableOffset
        SwiftParserAdvance(parser, (usesWideOffsets ? sizeof(UInt32) : sizeof(UInt16)) * (glyphCount + 1));

        [self _readGlyphPathsFromParser:parser];
        [self _readCodeTableFromParser:parser wide:usesWideCodes];

        if (hasLayout) {
            m_hasLayout = YES;

            SInt16 ascent, descent, leading;
            SwiftParserReadSInt16(parser, &ascent);
            SwiftParserReadSInt16(parser, &descent);
            SwiftParserReadSInt16(parser, &leading);

            m_ascent  = SwiftGetCGFloatFromTwips(ascent);
            m_descent = SwiftGetCGFloatFromTwips(descent);
            m_leading = SwiftGetCGFloatFromTwips(leading);

            m_glyphAdvances = m_glyphCount ? malloc(sizeof(CGFloat) * m_glyphCount) : NULL;
            for (NSInteger i = 0; i < m_glyphCount; i++) {
                SInt16 advance;
                SwiftParserReadSInt16(parser, &advance);
                m_glyphAdvances[i] = SwiftGetCGFloatFromTwips(advance);
            }

            m_glyphBounds = m_glyphCount ? malloc(sizeof(CGRect) * m_glyphCount) : NULL;
            for (NSInteger i = 0; i < m_glyphCount; i++) {
                CGRect rect;
                SwiftParserReadRect(parser, &rect);
                m_glyphBounds[i] = rect;
            }

            UInt16 kerningCount;
            SwiftParserReadUInt16(parser, &kerningCount);
            m_kerningCount = kerningCount;
            m_kerningRecords = kerningCount ? malloc(sizeof(SwiftFontKerningRecord) * m_kerningCount) : NULL;

            for (NSInteger i = 0; i < m_kerningCount; i++) {
                if (usesWideCodes) {
                    UInt16 tmp;
                    SwiftParserReadUInt16(parser, &tmp);
                    m_kerningRecords[i].leftCharacterCode = tmp;

                    SwiftParserReadUInt16(parser, &tmp);
                    m_kerningRecords[i].rightCharacterCode = tmp;
    
                } else {
                    UInt8 tmp;
                    SwiftParserReadUInt8(parser, &tmp);
                    m_kerningRecords[i].leftCharacterCode = tmp;

                    SwiftParserReadUInt8(parser, &tmp);
                    m_kerningRecords[i].rightCharacterCode = tmp;
                }
                
                SInt16 adjustment;
                SwiftParserReadSInt16(parser, &adjustment);
                m_kerningRecords[i].adjustment = SwiftGetCGFloatFromTwips(adjustment);
            }
        }

    } else if (version == 4) {
        //!nyi: DefineFont4 tag
    }
}


- (void) readDefineFontNameTagFromParser:(SwiftParser *)parser
{
    NSString *name      = nil;
    SwiftParserReadString(parser, &name);
    m_fullName = [name retain];

    NSString *copyright = nil;
    SwiftParserReadString(parser, &copyright);
    m_copyright = [copyright retain];
}


- (void) readDefineFontInfoTagFromParser:(SwiftParser *)parser
{
    UInt32 reserved, isSmallText, isShiftJIS, isANSIEncoding, isItalic, isBold, usesWideCodes;

    NSString *name;
    SwiftParserReadLengthPrefixedString(parser, &name);
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
    m_smallText = isSmallText;

    if (isANSIEncoding) {
        m_encoding = SwiftGetANSIStringEncoding();
    } else if (isShiftJIS) {
        m_encoding = NSShiftJISStringEncoding;
    } else {
        m_encoding = NSUnicodeStringEncoding;
    }

    NSInteger version = SwiftParserGetCurrentTagVersion(parser);
    if (version == 2) {
        UInt8 languageCode;
        SwiftParserReadUInt8(parser, &languageCode);
        m_languageCode = languageCode;
    }

    m_glyphCount = SwiftParserGetBytesRemainingInCurrentTag(parser);
    if (usesWideCodes) m_glyphCount /= 2;
    
    [self _readCodeTableFromParser:parser wide:usesWideCodes];
}


- (void) readDefineFontAlignZonesFromParser:(SwiftParser *)parser
{
    //!nyi: DefineFontAlignZones tag
}


#pragma mark -
#pragma mark Accessors

@synthesize movie         = m_movie,
            libraryID     = m_libraryID,
            name          = m_name,
            fullName      = m_fullName,
            copyright     = m_copyright,
            glyphCount    = m_glyphCount,
            glyphPaths    = m_glyphPaths,
            codeTable     = m_codeTable,
            encoding      = m_encoding,
            languageCode  = m_languageCode,
            bold          = m_bold,
            italic        = m_italic,
            smallText     = m_smallText;

@synthesize hasLayout     = m_hasLayout,
            ascent        = m_ascent,
            descent       = m_descent,
            leading       = m_leading,
            glyphAdvances = m_glyphAdvances,
            glyphBounds   = m_glyphBounds,
            kerningCount  = m_kerningCount,
            kerningRecords = m_kerningRecords;


@end
