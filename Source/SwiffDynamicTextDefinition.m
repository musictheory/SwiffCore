/*
    SwiffDynamicText.m
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

#import "SwiffDynamicTextDefinition.h"

#import "SwiffParser.h"
#import "SwiffPlacedDynamicText.h"
#import "SwiffUtils.h"


@implementation SwiffDynamicTextDefinition

+ (Class) placedObjectClass
{
    return [SwiffPlacedDynamicText class];
}


- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie
{
    if ((self = [super init])) {
        UInt32 hasText, wordWrap, multiline, password, readOnly, hasColor,
               hasMaxLength, hasFont, hasFontClass, autosize, hasLayout,
               noSelect, border, wasStatic, html, useOutlines;
           
        UInt16 libraryID;
        SwiffParserReadUInt16(parser, &libraryID);
        m_movie     = movie;
        m_libraryID = libraryID;
        
        SwiffParserReadRect(parser, &m_bounds);

        SwiffParserReadUBits(parser, 1, &hasText);
        SwiffParserReadUBits(parser, 1, &wordWrap);       m_wordWrap     = wordWrap;
        SwiffParserReadUBits(parser, 1, &multiline);      m_multiline    = multiline;
        SwiffParserReadUBits(parser, 1, &password);       m_password     = password;

        SwiffParserReadUBits(parser, 1, &readOnly);       m_editable     = !readOnly;
        SwiffParserReadUBits(parser, 1, &hasColor);       m_hasColor     = hasColor;
        SwiffParserReadUBits(parser, 1, &hasMaxLength);
        SwiffParserReadUBits(parser, 1, &hasFont);

        SwiffParserReadUBits(parser, 1, &hasFontClass);
        SwiffParserReadUBits(parser, 1, &autosize);       m_autosize     = autosize;
        SwiffParserReadUBits(parser, 1, &hasLayout);      m_hasLayout    = hasLayout;
        SwiffParserReadUBits(parser, 1, &noSelect);       m_selectable   = !noSelect;

        SwiffParserReadUBits(parser, 1, &border);         m_border       = border;
        SwiffParserReadUBits(parser, 1, &wasStatic);      m_wasStatic    = wasStatic;
        SwiffParserReadUBits(parser, 1, &html);           m_HTML         = html;
        SwiffParserReadUBits(parser, 1, &useOutlines);    m_useOutlines  = useOutlines;

        if (hasFont) {
            UInt16 fontID;
            SwiffParserReadUInt16(parser, &fontID);
            m_fontID  = fontID;
            m_hasFont = YES;
        }

        if (hasFontClass) {
            NSString *fontClass = nil;
            SwiffParserReadString( parser, &fontClass);
            m_fontClass = fontClass;
            m_hasFontClass = YES;
        }
    
        if (hasFont) {
            SwiffParserReadUInt16(parser, &m_fontHeightInTwips);
        }
        
        if (hasColor) {
            SwiffParserReadColorRGBA(parser, &m_color);
            m_hasColor = YES;
        }

        if (hasMaxLength) {
            UInt16 maxLength;
            SwiffParserReadUInt16(parser, &maxLength);
            m_maxLength = maxLength;
        } else {
            m_maxLength = NSIntegerMax;
        }

        if (hasLayout) {
            UInt8  align;
            SwiffParserReadUInt8(parser, &align);

            if      (align == 1) {  m_textAlignment = kCTRightTextAlignment;      }
            else if (align == 2) {  m_textAlignment = kCTCenterTextAlignment;     }
            else if (align == 3) {  m_textAlignment = kCTJustifiedTextAlignment;  }
            else                 {  m_textAlignment = kCTLeftTextAlignment;       }

            SwiffParserReadUInt16(parser, &m_leftMarginInTwips);
            SwiffParserReadUInt16(parser, &m_rightMarginInTwips);
            SwiffParserReadUInt16(parser, &m_indentInTwips);
            SwiffParserReadSInt16(parser, &m_leadingInTwips);
            
            m_hasLayout = YES;
        }

        NSString *variableName;
        SwiffParserReadString(parser, &variableName);
        m_variableName = variableName;
        
        if (hasText) {
            NSString *initialText;
            SwiffParserReadString(parser, &initialText);
            m_initialText = initialText;
        }

    }
    
    return self;
}


- (void) clearWeakReferences
{
    m_movie = nil;
}


#pragma mark -
#pragma mark Accessors

- (SwiffColor *) colorPointer
{
    return m_hasColor ? &m_color : NULL;
}


- (CGRect) renderBounds
{
    return m_bounds;
}


- (CGFloat) fontHeight  { return SwiffGetCGFloatFromTwips(m_fontHeightInTwips);  }
- (CGFloat) leftMargin  { return SwiffGetCGFloatFromTwips(m_leftMarginInTwips);  }
- (CGFloat) rightMargin { return SwiffGetCGFloatFromTwips(m_rightMarginInTwips); }
- (CGFloat) indent      { return SwiffGetCGFloatFromTwips(m_indentInTwips);      }
- (CGFloat) leading     { return SwiffGetCGFloatFromTwips(m_leadingInTwips);     }

- (SwiffTwips) fontHeightInTwips  { return m_fontHeightInTwips;  }
- (SwiffTwips) leftMarginInTwips  { return m_leftMarginInTwips;  }
- (SwiffTwips) rightMarginInTwips { return m_rightMarginInTwips; }
- (SwiffTwips) indentInTwips      { return m_indentInTwips;      }
- (SwiffTwips) leadingInTwips     { return m_leadingInTwips;     }

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
