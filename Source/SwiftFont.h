//
//  SwiftFont.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    SwiftFontLanguageCodeNoLanguage = 0,
    SwiftFontLanguageCodeLatin = 1,
    SwiftFontLanguageCodeJapanese = 2,
    SwiftFontLanguageCodeKorean = 3,
    SwiftFontLanguageCodeSimplifiedChinese = 4,
    SwiftFontLanguageCodeTraditionalChinese = 5
};
typedef NSInteger SwiftFontLanguageCode;

@interface SwiftFont : NSObject {
@private
    NSInteger  m_libraryID;
 
    NSString  *m_name;
    NSString  *m_fullName;
    NSString  *m_copyright;

    UInt16    *codeTable;

    NSInteger  m_languageCode;
    NSInteger  m_glyphCount;

    CGFloat    m_ascenderHeight;
    CGFloat    m_descenderHeight;
    CGFloat    m_leadingHeight;

#if 0
    SInt16    *advanceTable;
    SWFRect   *boundsTable;
    SWFShape **glyph;
#endif
    
    BOOL       m_bold;
    BOOL       m_italic;
    BOOL       m_pixelAligned;
    BOOL       m_smallText;
    BOOL       m_hasLayout;
}


// Font information is distributed among DefineFont/DefineFontInfo/DefineFontName tags.  Hence, the
// -initWithParser:tag:version: pattern used by other classes doesn't fit here.
//
// When encountering one of these tags, the movie should read the fontID from the stream, create or lookup
// the corresponding font, and then call one of the readDefineFont... methods
//
- (id) initWithLibraryID:(NSInteger)libraryID;
- (void) readDefineFontTagFromParser:(SwiftParser *)parser version:(NSInteger)version;
- (void) readDefineFontNameTagFromParser:(SwiftParser *)parser version:(NSInteger)version;
- (void) readDefineFontInfoTagFromParser:(SwiftParser *)parser version:(NSInteger)version;


@property (nonatomic, assign) NSInteger libraryID;

@property (nonatomic, assign, readonly) SwiftFontLanguageCode languageCode;

@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, retain, readonly) NSString *fullName;
@property (nonatomic, retain, readonly) NSString *copyright;

@property (nonatomic, assign, readonly) CGFloat ascenderHeight;
@property (nonatomic, assign, readonly) CGFloat descenderHeight;
@property (nonatomic, assign, readonly) CGFloat leadingHeight;

@property (nonatomic, assign, readonly, getter=isBold)   BOOL bold;
@property (nonatomic, assign, readonly, getter=isItalic) BOOL italic;

@property (nonatomic, readonly, assign, getter=isPixelAligned) BOOL pixelAligned;

@property (nonatomic, assign, readonly) BOOL hasLayoutInformation;


@end
