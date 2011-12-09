/*
    SwiftDynamicText.m
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

#import "SwiftDynamicTextDefinition.h"

#import "SwiftParser.h"

@implementation SwiftDynamicTextDefinition

- (id) initWithParser:(SwiftParser *)parser movie:(SwiftMovie *)movie
{
    if ((self = [super init])) {
        UInt32 hasText, wordWrap, multiline, password, readOnly, hasColor,
               hasMaxLength, hasFont, hasFontClass, autosize, hasLayout,
               noSelect, border, wasStatic, html, useOutlines;
           
        UInt16 libraryID;
        SwiftParserReadUInt16(parser, &libraryID);
        m_movie     = movie;
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
        SwiftParserReadUBits(parser, 1, &html);           m_HTML         = html;
        SwiftParserReadUBits(parser, 1, &useOutlines);    m_useOutlines  = useOutlines;

        if (hasFont) {
            UInt16 fontID;
            SwiftParserReadUInt16(parser, &fontID);
            m_fontID  = fontID;
            m_hasFont = YES;
        }

        if (hasFontClass) {
            NSString *fontClass = nil;
            SwiftParserReadString( parser, &fontClass);
            m_fontClass = [fontClass retain];
            m_hasFontClass = YES;
        }
    
        if (hasFont) {
            SwiftParserReadUInt16(parser, &m_fontHeightInTwips);
        }
        
        if (hasColor) {
            SwiftParserReadColorRGBA(parser, &m_color);
            m_hasColor = YES;
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
            SwiftParserReadUInt8(parser, &align);

            if      (align == 1) {  m_textAlignment = kCTRightTextAlignment;      }
            else if (align == 2) {  m_textAlignment = kCTCenterTextAlignment;     }
            else if (align == 3) {  m_textAlignment = kCTJustifiedTextAlignment;  }
            else                 {  m_textAlignment = kCTLeftTextAlignment;       }

            SwiftParserReadUInt16(parser, &m_leftMarginInTwips);
            SwiftParserReadUInt16(parser, &m_rightMarginInTwips);
            SwiftParserReadUInt16(parser, &m_indentInTwips);
            SwiftParserReadSInt16(parser, &m_leadingInTwips);
            
            m_hasLayout = YES;
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
    [m_fontClass    release];  m_fontClass    = nil;

    [super dealloc];
}


- (void) clearWeakReferences
{
    m_movie = nil;
}


#pragma mark -
#pragma mark Accessors

- (CGRect) edgeBounds  { return CGRectZero; }
- (BOOL) hasEdgeBounds { return NO; }


- (SwiftColor *) colorPointer
{
    return m_hasColor ? &m_color : NULL;
}


- (CGFloat) fontHeight  { return SwiftGetCGFloatFromTwips(m_fontHeightInTwips);  }
- (CGFloat) leftMargin  { return SwiftGetCGFloatFromTwips(m_leftMarginInTwips);  }
- (CGFloat) rightMargin { return SwiftGetCGFloatFromTwips(m_rightMarginInTwips); }
- (CGFloat) indent      { return SwiftGetCGFloatFromTwips(m_indentInTwips);      }
- (CGFloat) leading     { return SwiftGetCGFloatFromTwips(m_leadingInTwips);     }

- (SwiftTwips) fontHeightInTwips  { return m_fontHeightInTwips;  }
- (SwiftTwips) leftMarginInTwips  { return m_leftMarginInTwips;  }
- (SwiftTwips) rightMarginInTwips { return m_rightMarginInTwips; }
- (SwiftTwips) indentInTwips      { return m_indentInTwips;      }
- (SwiftTwips) leadingInTwips     { return m_leadingInTwips;     }

@synthesize movie         = m_movie,
            libraryID     = m_libraryID,
            bounds        = m_bounds,
            variableName  = m_variableName,
            initialText   = m_initialText,
            maxLength     = m_maxLength,
            textAlignment = m_textAlignment,
            editable      = m_editable,
            selectable    = m_selectable,
            HTML          = m_HTML,
            hasLayout     = m_hasLayout,
            hasFont       = m_hasFont,
            hasFontClass  = m_hasFontClass,
            fontClass     = m_fontClass,
            fontID        = m_fontID,
            hasColor      = m_hasColor,
            color         = m_color;

@end
