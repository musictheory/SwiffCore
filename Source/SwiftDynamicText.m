//
//  SwiftText.m
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftDynamicText.h"

#import "SwiftParser.h"

@implementation SwiftDynamicText

- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)tagVersion
{
    if ((self = [super init])) {
        UInt32 hasText, wordWrap, multiline, password, readOnly, hasColor,
               hasMaxLength, hasFont, hasFontClass, autosize, hasLayout,
               noSelect, border, wasStatic, html, useOutlines;
           
        UInt16 libraryID;
        SwiftParserReadUInt16(parser, &libraryID);
        m_libraryID = libraryID;
        
        SwiftParserReadRect(parser, &m_bounds);

        SwiftParserReadUBits(parser, 1, &hasText);
        SwiftParserReadUBits(parser, 1, &wordWrap);       m_wordWrap     = wordWrap;
        SwiftParserReadUBits(parser, 1, &multiline);      m_multiline    = multiline;
        SwiftParserReadUBits(parser, 1, &password);       m_password     = password;

        SwiftParserReadUBits(parser, 1, &readOnly);       m_editable     = !readOnly;
        SwiftParserReadUBits(parser, 1, &hasColor);       m_hasColor     = hasColor;
        SwiftParserReadUBits(parser, 1, &hasMaxLength);
        SwiftParserReadUBits(parser, 1, &hasFont);

        SwiftParserReadUBits(parser, 1, &hasFontClass);
        SwiftParserReadUBits(parser, 1, &autosize);       m_autosize     = autosize;
        SwiftParserReadUBits(parser, 1, &hasLayout);      m_hasLayout    = hasLayout;
        SwiftParserReadUBits(parser, 1, &noSelect);       m_selectable   = !noSelect;

        SwiftParserReadUBits(parser, 1, &border);         m_border       = border;
        SwiftParserReadUBits(parser, 1, &wasStatic);      m_wasStatic    = wasStatic;
        SwiftParserReadUBits(parser, 1, &html);           m_html         = html;
        SwiftParserReadUBits(parser, 1, &useOutlines);    m_useOutlines  = useOutlines;

        if (hasFont) {
            UInt16 fontID;
            SwiftParserReadUInt16(parser, &fontID);
        }

        if (hasFontClass) {
            NSString *fontClass;
            SwiftParserReadString( parser, &fontClass);
        }
    
        if (hasFont) {
            UInt16 fontHeight;
            SwiftParserReadUInt16(parser, &fontHeight);
        }
        
        if (hasColor) {
            SwiftParserReadColorRGBA(parser, &m_color);
        }

        if (hasMaxLength) {
            UInt16 maxLength;
            SwiftParserReadUInt16(parser, &maxLength);
            m_maxLength = maxLength;
        } else {
            m_maxLength = NSIntegerMax;
        }

        if (hasLayout) {
            UInt8  align;
            UInt16 leftMargin, rightMargin, indent;
            SInt16 leading;
        
            SwiftParserReadUInt8( parser, &align);
            SwiftParserReadUInt16(parser, &leftMargin);
            SwiftParserReadUInt16(parser, &rightMargin);
            SwiftParserReadUInt16(parser, &indent);
            SwiftParserReadSInt16(parser, &leading);
            
//            tag->align       = align;
//            tag->leftMargin  = leftMargin;
//            tag->rightMargin = rightMargin;
//            tag->indent      = indent;
//            tag->leading     = leading;
        }

        NSString *variableName;
        SwiftParserReadString(parser, &variableName);
        m_variableName = [variableName retain];
        
        if (hasText) {
            NSString *initialText;
            SwiftParserReadString(parser, &initialText);
            m_initialText = [initialText retain];
        }

    }
    
    return self;
}

- (void) dealloc
{
    [m_initialText  release];  m_initialText  = nil;
    [m_variableName release];  m_variableName = nil;

    [super dealloc];
}


- (CGRect) edgeBounds  { return CGRectZero; }
- (BOOL) hasEdgeBounds { return NO; }

@synthesize libraryID    = m_libraryID,
            bounds       = m_bounds,
            variableName = m_variableName,
            initialText  = m_initialText,
            editable     = m_editable,
            selectable   = m_selectable;

@end
