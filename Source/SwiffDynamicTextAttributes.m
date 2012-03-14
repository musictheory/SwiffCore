/*
    SwiffDynamicTextAttributes.m
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


#import "SwiffDynamicTextAttributes.h"
#import "SwiffUtils.h"

static NSString * const SwiffTextVerticalOffsetAttributeName = @"SwiffTextVerticalOffset";


enum {
    SwiffFontMapTypeDirect             = 0,
    SwiffFontMapTypeIndirectUnknown    = -1,
    SwiffFontMapTypeIndirectSans       = 1,
    SwiffFontMapTypeIndirectSerif      = 2,
    SwiffFontMapTypeIndirectTypewriter = 3
}; 
typedef NSInteger SwiffFontMapType;


CGFloat SwiffTextGetMaximumVerticalOffset(CFAttributedStringRef as, CFRange range)
{
    CFIndex i = range.location;
    CFIndex endI = i + range.length;
    CGFloat result = -INFINITY;

    while (i < endI) {

        CFRange effectiveRange;
        CFNumberRef type = CFAttributedStringGetAttribute(as, i, (__bridge CFStringRef)SwiffTextVerticalOffsetAttributeName, &effectiveRange);
    
        if (type) {
            CGFloat value;
            if (CFNumberGetValue(type, kCFNumberCGFloatType, &value)) {
                if (value > result) result = value;
            }
            
            i = (effectiveRange.location + effectiveRange.length);

        } else {
            i++;
        }
    }

    return (result == -INFINITY) ? 0 : result;
}


static void sGetMapTypeAndName(NSString *inName, NSString **outName, SwiffFontMapType *outMapType)
{
    SwiffFontMapType mapType = SwiffFontMapTypeDirect;
    NSString *name = nil;

    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSArray        *components = [inName componentsSeparatedByString:@","];
    
    for (NSString *component in components) {
        NSString *trimmedComponent = [component stringByTrimmingCharactersInSet:whitespace];

        if ([inName hasPrefix:@"_"]) {
            if ([inName isEqualToString:@"_sans"]) {
                mapType = SwiffFontMapTypeIndirectSans;
                name = @"Helvetica";

            } else if ([inName isEqualToString:@"_serif"]) {
                mapType = SwiffFontMapTypeIndirectSerif;
                name = @"Times";

            } else if ([inName isEqualToString:@"_typewriter"]) {
                mapType = SwiffFontMapTypeIndirectTypewriter;
                name = @"Courier";

            } else {
                mapType = SwiffFontMapTypeIndirectUnknown;
            }
        }
        
        if (mapType == SwiffFontMapTypeDirect) {
            CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)trimmedComponent, 12.0, NULL);

            if (font) {
                name = trimmedComponent;
                CFRelease(font);
            }
        }

        if (name) break;
    }
    
    if (!name) name = @"Helvetica";

    if (outName)    *outName    = name;
    if (outMapType) *outMapType = mapType;
}


@implementation SwiffDynamicTextAttributes {
    NSString        *_tabStopsString;
    SwiffColor       _fontColor;
    NSInteger        _mapType;
    BOOL             _hasFontColor;
}


@synthesize fontName           = _fontName,
            mappedFontName     = _mappedFontName,
            fontSizeInTwips    = _fontSizeInTwips,
            bold               = _bold,
            italic             = _italic,
            underline          = _underline,
            textAlignment      = _textAlignment,
            leftMarginInTwips  = _leftMarginInTwips,
            rightMarginInTwips = _rightMarginInTwips,
            indentInTwips      = _indentInTwips,
            leadingInTwips     = _leadingInTwips,
            tabStopsString     = _tabStopsString;


- (id) copyWithZone:(NSZone *)zone
{
    SwiffDynamicTextAttributes *result = [[SwiffDynamicTextAttributes alloc] init];

    result->_fontName           = [_fontName copy];
    result->_mappedFontName     = [_mappedFontName copy];
    result->_tabStopsString     = [_tabStopsString copy];
    result->_fontSizeInTwips    = _fontSizeInTwips;
    result->_fontColor          = _fontColor;
    result->_textAlignment      = _textAlignment;
    result->_leftMarginInTwips  = _leftMarginInTwips;
    result->_rightMarginInTwips = _rightMarginInTwips;
    result->_indentInTwips      = _indentInTwips;
    result->_leadingInTwips     = _leadingInTwips;
    result->_mapType            = _mapType;
    result->_bold               = _bold;
    result->_italic             = _italic;
    result->_underline          = _underline;
    result->_hasFontColor       = _hasFontColor;

    return result;
}


#pragma mark -
#pragma mark - Public Methods

- (CTFontRef) copyCTFont
{
    CGFloat   fontSize = SwiffGetCGFloatFromTwips(_fontSizeInTwips);

    CTFontRef base   = CTFontCreateWithName((__bridge CFStringRef)_mappedFontName, fontSize, NULL);
    CTFontRef result = NULL;

    if (base) {
        CTFontSymbolicTraits desiredTraits = 0;
        if (_bold)   desiredTraits |= kCTFontBoldTrait;
        if (_italic) desiredTraits |= kCTFontItalicTrait;

        CTFontSymbolicTraits traits = CTFontGetSymbolicTraits(base);
        CTFontSymbolicTraits mask   = (kCTFontBoldTrait | kCTFontItalicTrait);

        if ((traits & mask) != desiredTraits) {
            result = CTFontCreateCopyWithSymbolicTraits(base, 0, NULL, desiredTraits, mask);
        }
        
        if (!result) {
            result = CFRetain(base);
        }

        CFRelease(base);
    }
    
    return result;
}


- (NSDictionary *) copyCoreTextAttributes
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:5];

    CGFloat fontPointSize = SwiffGetCGFloatFromTwips(_fontSizeInTwips);
    CTFontRef font = [self copyCTFont];

    CGFloat leftMarginTweak     = 2.0;
    CGFloat rightMarginTweak    = 2.0;
    CGFloat verticalOffsetTweak = 3.0;

    CGFloat firstLineHeadIndent = SwiffGetCGFloatFromTwips(  _leftMarginInTwips + _indentInTwips ) + leftMarginTweak;
    CGFloat headIndent          = SwiffGetCGFloatFromTwips(  _leftMarginInTwips)  + leftMarginTweak;
    CGFloat tailIndent          = SwiffGetCGFloatFromTwips( -_rightMarginInTwips) - rightMarginTweak;
    CGFloat lineSpacingAdjust   = SwiffGetCGFloatFromTwips(  _leadingInTwips );
    CGFloat minimumLineHeight   = 0.0;
    CGFloat maximumLineHeight   = 0.0;

    CGFloat ascent  = CTFontGetAscent(font);
    CGFloat descent = CTFontGetDescent(font);
    CGFloat leading = CTFontGetLeading(font);

    // For direct fonts, Flash appears to use a line height exactly equal to the font size
    if (_mapType == SwiffFontMapTypeDirect) {
        minimumLineHeight = maximumLineHeight = SwiffFloor(ascent + descent) - SwiffFloor(leading);
        
    } else {
        // Tweak for mapping indirect font to Helvetica or Times
        minimumLineHeight = maximumLineHeight = SwiffFloor(fontPointSize * 1.15);
    }

    if (font) {
        [result setObject:(__bridge id)font forKey:(id)kCTFontAttributeName];
        CFRelease(font);
    } 

   
    if (_hasFontColor) {
        CGColorRef cgColor = SwiffColorCopyCGColor(_fontColor);
        if (cgColor) {
            [result setObject:(__bridge id)cgColor forKey:(id)kCTForegroundColorAttributeName];
            CFRelease(cgColor);
        }
    }

    if (_underline) {
        NSNumber *number = [NSNumber numberWithInteger:kCTUnderlineStyleSingle];
        [result setObject:number forKey:(id)kCTUnderlineStyleAttributeName];
    }

    NSNumber *number = [NSNumber numberWithDouble:(double)verticalOffsetTweak];
    [result setObject:number forKey:SwiffTextVerticalOffsetAttributeName];

    CTParagraphStyleSetting settings[] = {
        { kCTParagraphStyleSpecifierAlignment,              sizeof(CTTextAlignment), &_textAlignment        },
        { kCTParagraphStyleSpecifierFirstLineHeadIndent,    sizeof(CGFloat),         &firstLineHeadIndent    },
        { kCTParagraphStyleSpecifierHeadIndent,             sizeof(CGFloat),         &headIndent             },
        { kCTParagraphStyleSpecifierTailIndent,             sizeof(CGFloat),         &tailIndent             },
        { kCTParagraphStyleSpecifierLineSpacingAdjustment,  sizeof(CGFloat),         &lineSpacingAdjust      },
        { kCTParagraphStyleSpecifierMinimumLineHeight,      sizeof(CGFloat),         &minimumLineHeight      },
        { kCTParagraphStyleSpecifierMaximumLineHeight,      sizeof(CGFloat),         &maximumLineHeight      }
    };

    CTParagraphStyleRef ps = CTParagraphStyleCreate(settings, 7);
    if (ps) {
        [result setObject:(__bridge id)ps forKey:(id)kCTParagraphStyleAttributeName];
        CFRelease(ps);
    }
    
    return result;
}


#pragma mark -
#pragma mark Accessors

- (void) setFontSize:(CGFloat)f    { _fontSizeInTwips    = SwiffGetTwipsFromCGFloat(f); }
- (void) setLeftMargin:(CGFloat)f  { _leftMarginInTwips  = SwiffGetTwipsFromCGFloat(f); }
- (void) setRightMargin:(CGFloat)f { _rightMarginInTwips = SwiffGetTwipsFromCGFloat(f); }
- (void) setIndent:(CGFloat)f      { _indentInTwips      = SwiffGetTwipsFromCGFloat(f); }
- (void) setLeading:(CGFloat)f     { _leadingInTwips     = SwiffGetTwipsFromCGFloat(f); }

- (CGFloat) fontSize    { return SwiffGetCGFloatFromTwips(_fontSizeInTwips);    }
- (CGFloat) leftMargin  { return SwiffGetCGFloatFromTwips(_leftMarginInTwips);  }
- (CGFloat) rightMargin { return SwiffGetCGFloatFromTwips(_rightMarginInTwips); }
- (CGFloat) indent      { return SwiffGetCGFloatFromTwips(_indentInTwips);      }
- (CGFloat) leading     { return SwiffGetCGFloatFromTwips(_leadingInTwips);     }

- (void) setFontName:(NSString *)fontName
{
    if (_fontName != fontName) {
        _fontName = [fontName copy];
        
        NSString *mappedName = nil;
        sGetMapTypeAndName(fontName, &mappedName, &_mapType);

        _mappedFontName = [mappedName copy];
    }
}


- (void) setFontColor:(SwiffColor *)fontColor
{
    if (fontColor) {
        _fontColor    = *fontColor;
        _hasFontColor = YES;
    } else {
        _hasFontColor = NO;
    }
}


- (SwiffColor *) fontColor
{
    return _hasFontColor ? &_fontColor : NULL;
}


@end

