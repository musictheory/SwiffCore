/*
    SwiffFont.h
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


#import <SwiffImport.h>
#import <SwiffDefinition.h>
#import <SwiffParser.h>

typedef struct SwiffFontKerningRecord {
    UInt16 leftCharacterCode;
    UInt16 rightCharacterCode;
    CGFloat adjustment;
} SwiffFontKerningRecord;


extern const CGFloat SwiffFontEmSquareHeight;           // 1024


@class SwiffMovie;

@interface SwiffFontDefinition : NSObject <SwiffDefinition> {
@private
    SwiffUnretained SwiffMovie *m_movie;
 
    NSString         *m_name;
    NSString         *m_fullName;
    NSString         *m_copyright;
    UInt16           *m_codeTable;

    SwiffLanguageCode m_languageCode;
    NSStringEncoding  m_encoding;
    NSUInteger        m_glyphCount;
    NSUInteger        m_kerningCount;
    CGPathRef        *m_glyphPaths;
    CGFloat          *m_glyphAdvances;
    CGRect           *m_glyphBounds;

    CGFloat           m_ascent;
    CGFloat           m_descent;
    CGFloat           m_leading;

    SwiffFontKerningRecord *m_kerningRecords;

    UInt16            m_libraryID;
    BOOL              m_bold;
    BOOL              m_italic;
    BOOL              m_smallText;
    BOOL              m_hasLayout;
}


// Font information is distributed among DefineFont/DefineFontInfo/DefineFontName tags.  Hence, the
// -initWithParser:tag:version: pattern used by other classes doesn't fit here.
//
// When encountering one of these tags, the movie should read the fontID from the stream, create or lookup
// the corresponding font, and then call one of the readDefineFont... methods
//
- (id) initWithLibraryID:(UInt16)libraryID movie:(SwiffMovie *)movie;

- (void) readDefineFontTagFromParser:(SwiffParser *)parser;
- (void) readDefineFontNameTagFromParser:(SwiffParser *)parser;
- (void) readDefineFontInfoTagFromParser:(SwiffParser *)parser;
- (void) readDefineFontAlignZonesFromParser:(SwiffParser *)parser;

@property (nonatomic, assign, readonly) UInt16 libraryID;

@property (nonatomic, assign, readonly) SwiffLanguageCode languageCode;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *fullName;
@property (nonatomic, strong, readonly) NSString *copyright;

@property (nonatomic, assign, readonly) NSUInteger glyphCount;
@property (nonatomic, readonly /*strong*/) CGPathRef *glyphPaths;   // CGPathRef[glyphCount]

@property (nonatomic, assign, readonly) UInt16 *codeTable;
@property (nonatomic, assign, readonly) NSStringEncoding encoding;

@property (nonatomic, assign, readonly, getter=isBold) BOOL bold;
@property (nonatomic, assign, readonly, getter=isItalic) BOOL italic;
@property (nonatomic, assign, readonly, getter=isSmallText) BOOL smallText;

// Layout info.  Relative to an EM square of 1024x1024 units (SwiffFontEmSquareHeight)
@property (nonatomic, assign, readonly) BOOL     hasLayout;
@property (nonatomic, assign, readonly) CGFloat  ascent;
@property (nonatomic, assign, readonly) CGFloat  descent;
@property (nonatomic, assign, readonly) CGFloat  leading;
@property (nonatomic,         readonly) CGFloat *glyphAdvances; // CGFloat[glyphCount]
@property (nonatomic,         readonly) CGRect  *glyphBounds;   // CGRect[glyphCount]
@property (nonatomic, assign, readonly) NSUInteger  kerningCount;
@property (nonatomic,         readonly) SwiffFontKerningRecord *kerningRecords; // SwiffFontKerningRecord[kerningCount]

@end
