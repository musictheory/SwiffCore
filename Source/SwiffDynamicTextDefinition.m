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


@implementation SwiffDynamicTextDefinition {
    UInt16      _fontHeightInTwips;
    UInt16      _leftMarginInTwips;
    UInt16      _rightMarginInTwips;
    UInt16      _indentInTwips;
    SInt16      _leadingInTwips;

    BOOL        _wordWrap;
    BOOL        _password;
    BOOL        _multiline;
    BOOL        _autosize;
    BOOL        _border;
    BOOL        _wasStatic;
    BOOL        _useOutlines;
}

@synthesize libraryID = _libraryID,
            movie     = _movie,
            bounds    = _bounds;


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
        _movie     = movie;
        _libraryID = libraryID;
        
        SwiffParserReadRect(parser, &_bounds);

        SwiffParserReadUBits(parser, 1, &hasText);
        SwiffParserReadUBits(parser, 1, &wordWrap);       _wordWrap     = wordWrap;
        SwiffParserReadUBits(parser, 1, &multiline);      _multiline    = multiline;
        SwiffParserReadUBits(parser, 1, &password);       _password     = password;

        SwiffParserReadUBits(parser, 1, &readOnly);       _editable     = !readOnly;
        SwiffParserReadUBits(parser, 1, &hasColor);       _hasColor     = hasColor;
        SwiffParserReadUBits(parser, 1, &hasMaxLength);
        SwiffParserReadUBits(parser, 1, &hasFont);

        SwiffParserReadUBits(parser, 1, &hasFontClass);
        SwiffParserReadUBits(parser, 1, &autosize);       _autosize     = autosize;
        SwiffParserReadUBits(parser, 1, &hasLayout);      _hasLayout    = hasLayout;
        SwiffParserReadUBits(parser, 1, &noSelect);       _selectable   = !noSelect;

        SwiffParserReadUBits(parser, 1, &border);         _border       = border;
        SwiffParserReadUBits(parser, 1, &wasStatic);      _wasStatic    = wasStatic;
        SwiffParserReadUBits(parser, 1, &html);           _HTML         = html;
        SwiffParserReadUBits(parser, 1, &useOutlines);    _useOutlines  = useOutlines;

        if (hasFont) {
            UInt16 fontID;
            SwiffParserReadUInt16(parser, &fontID);
            _fontID  = fontID;
            _hasFont = YES;
        }

        if (hasFontClass) {
            NSString *fontClass = nil;
            SwiffParserReadString( parser, &fontClass);
            _fontClass = fontClass;
            _hasFontClass = YES;
        }
    
        if (hasFont) {
            SwiffParserReadUInt16(parser, &_fontHeightInTwips);
        }
        
        if (hasColor) {
            SwiffParserReadColorRGBA(parser, &_color);
            _hasColor = YES;
        }

        if (hasMaxLength) {
            UInt16 maxLength;
            SwiffParserReadUInt16(parser, &maxLength);
            _maxLength = maxLength;
        } else {
            _maxLength = NSIntegerMax;
        }

        if (hasLayout) {
            UInt8  align;
            SwiffParserReadUInt8(parser, &align);

            if      (align == 1) {  _textAlignment = kCTRightTextAlignment;      }
            else if (align == 2) {  _textAlignment = kCTCenterTextAlignment;     }
            else if (align == 3) {  _textAlignment = kCTJustifiedTextAlignment;  }
            else                 {  _textAlignment = kCTLeftTextAlignment;       }

            SwiffParserReadUInt16(parser, &_leftMarginInTwips);
            SwiffParserReadUInt16(parser, &_rightMarginInTwips);
            SwiffParserReadUInt16(parser, &_indentInTwips);
            SwiffParserReadSInt16(parser, &_leadingInTwips);
            
            _hasLayout = YES;
        }

        NSString *variableName;
        SwiffParserReadString(parser, &variableName);
        _variableName = variableName;
        
        if (hasText) {
            NSString *initialText;
            SwiffParserReadString(parser, &initialText);
            _initialText = initialText;
        }

    }
    
    return self;
}


- (void) clearWeakReferences
{
    _movie = nil;
}


#pragma mark -
#pragma mark Accessors

- (SwiffColor *) colorPointer
{
    return _hasColor ? &_color : NULL;
}


- (CGRect) renderBounds
{
    return _bounds;
}


- (CGFloat) fontHeight  { return SwiffGetCGFloatFromTwips(_fontHeightInTwips);  }
- (CGFloat) leftMargin  { return SwiffGetCGFloatFromTwips(_leftMarginInTwips);  }
- (CGFloat) rightMargin { return SwiffGetCGFloatFromTwips(_rightMarginInTwips); }
- (CGFloat) indent      { return SwiffGetCGFloatFromTwips(_indentInTwips);      }
- (CGFloat) leading     { return SwiffGetCGFloatFromTwips(_leadingInTwips);     }

- (SwiffTwips) fontHeightInTwips  { return _fontHeightInTwips;  }
- (SwiffTwips) leftMarginInTwips  { return _leftMarginInTwips;  }
- (SwiffTwips) rightMarginInTwips { return _rightMarginInTwips; }
- (SwiffTwips) indentInTwips      { return _indentInTwips;      }
- (SwiffTwips) leadingInTwips     { return _leadingInTwips;     }

@end
