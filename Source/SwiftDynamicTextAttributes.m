/*
    SwiftDynamicTextAttributes.m
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


#import "SwiftDynamicTextAttributes.h"

static NSString * const SwiftTextVerticalOffsetAttributeName = @"SwiftTextVerticalOffset";


enum {
    _SwiftFontMapTypeDirect             = 0,
    _SwiftFontMapTypeIndirectUnknown    = -1,
    _SwiftFontMapTypeIndirectSans       = 1,
    _SwiftFontMapTypeIndirectSerif      = 2,
    _SwiftFontMapTypeIndirectTypewriter = 3
}; 
typedef NSInteger _SwiftFontMapType;


CGFloat SwiftTextGetMaximumVerticalOffset(CFAttributedStringRef as, CFRange range)
{
    CFIndex i = range.location;
    CFIndex endI = i + range.length;
    CGFloat result = -INFINITY;

    while (i < endI) {

        CFRange effectiveRange;
        CFNumberRef type = CFAttributedStringGetAttribute(as, i, (CFStringRef)SwiftTextVerticalOffsetAttributeName, &effectiveRange);
    
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


static void sGetMapTypeAndName(NSString *inName, NSString **outName, _SwiftFontMapType *outMapType)
{
    _SwiftFontMapType mapType = _SwiftFontMapTypeDirect;
    NSString *name = nil;

    @autoreleasepool {
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSArray        *components = [inName componentsSeparatedByString:@","];
        
        for (NSString *component in components) {
            component = [component stringByTrimmingCharactersInSet:whitespace];

            if ([inName hasPrefix:@"_"]) {
                if ([inName isEqualToString:@"_sans"]) {
                    mapType = _SwiftFontMapTypeIndirectSans;
                    name = @"Helvetica";

                } else if ([inName isEqualToString:@"_serif"]) {
                    mapType = _SwiftFontMapTypeIndirectSerif;
                    name = @"Times";

                } else if ([inName isEqualToString:@"_typewriter"]) {
                    mapType = _SwiftFontMapTypeIndirectTypewriter;
                    name = @"Courier";

                } else {
                    mapType = _SwiftFontMapTypeIndirectUnknown;
                }
            }
            
            if (mapType == _SwiftFontMapTypeDirect) {
                CTFontRef font = CTFontCreateWithName((CFStringRef)component, 12.0, NULL);

                if (font) {
                    name = [component retain];
                    CFRelease(font);
                }
            }

            if (name) break;
        }
    }
    
    if (!name) name = @"Helvetica";
    [name autorelease];

    if (outName)    *outName    = name;
    if (outMapType) *outMapType = mapType;
}


@implementation SwiftDynamicTextAttributes

- (void) dealloc
{
    [m_fontName       release];  m_fontName       = nil;
    [m_mappedFontName release];  m_mappedFontName = nil;
    [m_tabStopsString release];  m_tabStopsString = nil;

    [super dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
    SwiftDynamicTextAttributes *result = [[SwiftDynamicTextAttributes alloc] init];

    result->m_fontName           = [m_fontName copy];
    result->m_mappedFontName     = [m_mappedFontName copy];
    result->m_tabStopsString     = [m_tabStopsString copy];
    result->m_fontSizeInTwips    = m_fontSizeInTwips;
    result->m_fontColor          = m_fontColor;
    result->m_textAlignment      = m_textAlignment;
    result->m_leftMarginInTwips  = m_leftMarginInTwips;
    result->m_rightMarginInTwips = m_rightMarginInTwips;
    result->m_indentInTwips      = m_indentInTwips;
    result->m_leadingInTwips     = m_leadingInTwips;
    result->m_mapType            = m_mapType;
    result->m_bold               = m_bold;
    result->m_italic             = m_italic;
    result->m_underline          = m_underline;
    result->m_hasFontColor       = m_hasFontColor;

    return result;
}


#pragma mark -
#pragma mark - Public Methods

- (CTFontRef) copyCTFont
{
    CGFloat   fontSize = SwiftGetCGFloatFromTwips(m_fontSizeInTwips);

    CTFontRef base   = CTFontCreateWithName((CFStringRef)m_mappedFontName, fontSize, NULL);
    CTFontRef result = NULL;

    if (base) {
        CTFontSymbolicTraits desiredTraits = 0;
        if (m_bold)   desiredTraits |= kCTFontBoldTrait;
        if (m_italic) desiredTraits |= kCTFontItalicTrait;

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

    CGFloat fontPointSize = SwiftGetCGFloatFromTwips(m_fontSizeInTwips);
    CTFontRef font = [self copyCTFont];

    CGFloat leftMarginTweak     = 2.0;
    CGFloat rightMarginTweak    = 2.0;
    CGFloat verticalOffsetTweak = 3.0;

    CGFloat firstLineHeadIndent = SwiftGetCGFloatFromTwips(  m_leftMarginInTwips + m_indentInTwips ) + leftMarginTweak;
    CGFloat headIndent          = SwiftGetCGFloatFromTwips(  m_leftMarginInTwips)  + leftMarginTweak;
    CGFloat tailIndent          = SwiftGetCGFloatFromTwips( -m_rightMarginInTwips) - rightMarginTweak;
    CGFloat lineSpacingAdjust   = SwiftGetCGFloatFromTwips(  m_leadingInTwips );
    CGFloat minimumLineHeight   = 0.0;
    CGFloat maximumLineHeight   = 0.0;

    // For direct fonts, Flash appears to use a line height exactly equal to the font size
    if (m_mapType == _SwiftFontMapTypeDirect) {
        CGFloat ascent  = CTFontGetAscent(font);
        CGFloat descent = CTFontGetDescent(font);

        minimumLineHeight = maximumLineHeight = floor(ascent) + floor(descent);

    } else if (m_mapType == _SwiftFontMapTypeIndirectSans) {
        // Tweak for mapping _sans -> Helvetica
        verticalOffsetTweak -= (round(fontPointSize / 10.0) - 1);

    } else if (m_mapType == _SwiftFontMapTypeIndirectSerif) {
        // Tweak for mapping _serif -> Times
        verticalOffsetTweak -=  round(fontPointSize / 12.0);
    }

    if (font) {
        [result setObject:(id)font forKey:(id)kCTFontAttributeName];
        CFRelease(font);
    } 

   
    if (m_hasFontColor) {
        CGColorRef cgColor = SwiftColorCopyCGColor(m_fontColor);
        NSLog(@"%@", cgColor);
        if (cgColor) {
            [result setObject:(id)cgColor forKey:(id)kCTForegroundColorAttributeName];
            CFRelease(cgColor);
        }
    }

    if (m_underline) {
        NSNumber *number = [NSNumber numberWithInteger:kCTUnderlineStyleSingle];
        [result setObject:number forKey:(id)kCTUnderlineStyleAttributeName];
    }

    NSNumber *number = [NSNumber numberWithDouble:(double)verticalOffsetTweak];
    [result setObject:number forKey:SwiftTextVerticalOffsetAttributeName];

    CTParagraphStyleSetting settings[] = {
        { kCTParagraphStyleSpecifierAlignment,              sizeof(CTTextAlignment), &m_textAlignment        },
        { kCTParagraphStyleSpecifierFirstLineHeadIndent,    sizeof(CGFloat),         &firstLineHeadIndent    },
        { kCTParagraphStyleSpecifierHeadIndent,             sizeof(CGFloat),         &headIndent             },
        { kCTParagraphStyleSpecifierTailIndent,             sizeof(CGFloat),         &tailIndent             },
        { kCTParagraphStyleSpecifierLineSpacingAdjustment,  sizeof(CGFloat),         &lineSpacingAdjust      },
        { kCTParagraphStyleSpecifierMinimumLineHeight,      sizeof(CGFloat),         &minimumLineHeight      },
        { kCTParagraphStyleSpecifierMaximumLineHeight,      sizeof(CGFloat),         &maximumLineHeight      }
    };

    CTParagraphStyleRef ps = CTParagraphStyleCreate(settings, 7);
    if (ps) {
        [result setObject:(id)ps forKey:(id)kCTParagraphStyleAttributeName];
        CFRelease(ps);
    }
    
    return result;
}


#pragma mark -
#pragma mark Accessors

- (void) setFontSize:(CGFloat)f    { m_fontSizeInTwips    = SwiftGetTwipsFromCGFloat(f); }
- (void) setLeftMargin:(CGFloat)f  { m_leftMarginInTwips  = SwiftGetTwipsFromCGFloat(f); }
- (void) setRightMargin:(CGFloat)f { m_rightMarginInTwips = SwiftGetTwipsFromCGFloat(f); }
- (void) setIndent:(CGFloat)f      { m_indentInTwips      = SwiftGetTwipsFromCGFloat(f); }
- (void) setLeading:(CGFloat)f     { m_leadingInTwips     = SwiftGetTwipsFromCGFloat(f); }

- (CGFloat) fontSize    { return SwiftGetCGFloatFromTwips(m_fontSizeInTwips);    }
- (CGFloat) leftMargin  { return SwiftGetCGFloatFromTwips(m_leftMarginInTwips);  }
- (CGFloat) rightMargin { return SwiftGetCGFloatFromTwips(m_rightMarginInTwips); }
- (CGFloat) indent      { return SwiftGetCGFloatFromTwips(m_indentInTwips);      }
- (CGFloat) leading     { return SwiftGetCGFloatFromTwips(m_leadingInTwips);     }

- (void) setFontName:(NSString *)fontName
{
    if (m_fontName != fontName) {
        [m_fontName release];
        m_fontName = [fontName copy];
        
        NSString *mappedName = nil;
        sGetMapTypeAndName(fontName, &mappedName, &m_mapType);

        [m_mappedFontName release];
        m_mappedFontName = [mappedName copy];
    }
}


- (void) setFontColor:(SwiftColor *)fontColor
{
    if (fontColor) {
        m_fontColor    = *fontColor;
        m_hasFontColor = YES;
    } else {
        m_hasFontColor = NO;
    }
}

- (SwiftColor *) fontColor
{
    return m_hasFontColor ? &m_fontColor : NULL;
}

@synthesize fontName           = m_fontName,
            mappedFontName     = m_mappedFontName,
            fontSizeInTwips    = m_fontSizeInTwips,
            bold               = m_bold,
            italic             = m_italic,
            underline          = m_underline,
            textAlignment      = m_textAlignment,
            leftMarginInTwips  = m_leftMarginInTwips,
            rightMarginInTwips = m_rightMarginInTwips,
            indentInTwips      = m_indentInTwips,
            leadingInTwips     = m_leadingInTwips,
            tabStopsString     = m_tabStopsString;

@end

