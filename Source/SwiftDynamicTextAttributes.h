/*
    SwiftDynamicTextAttributes.h
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

#import <SwiftImport.h>
#import <SwiftBase.h>

extern CGFloat SwiftTextGetMaximumVerticalOffset(CFAttributedStringRef as, CFRange range);

@interface SwiftDynamicTextAttributes : NSObject <NSCopying> {
@private
    NSString        *m_fontName;
    NSString        *m_mappedFontName;
    NSString        *m_tabStopsString;
    SwiftTwips       m_fontSizeInTwips;
    SwiftColor       m_fontColor;
    CTTextAlignment  m_textAlignment;
    SwiftTwips       m_leftMarginInTwips;
    SwiftTwips       m_rightMarginInTwips;
    SwiftTwips       m_indentInTwips;
    SwiftTwips       m_leadingInTwips;
    NSInteger        m_mapType;
    BOOL             m_bold;
    BOOL             m_italic;
    BOOL             m_underline;
    BOOL             m_hasFontColor;
}

- (CTFontRef) copyCTFont CF_RETURNS_RETAINED;
- (NSDictionary *) copyCoreTextAttributes NS_RETURNS_RETAINED;

@property (nonatomic, copy)   NSString       *fontName;
@property (nonatomic, copy)   NSString       *mappedFontName;
@property (nonatomic, assign) SwiftTwips      fontSizeInTwips;
@property (nonatomic, assign) CGFloat         fontSize;
@property (nonatomic, assign) SwiftColor     *fontColor;

@property (nonatomic, assign, getter=isBold) BOOL bold;
@property (nonatomic, assign, getter=isItalic) BOOL italic;
@property (nonatomic, assign, getter=isUnderline) BOOL underline;

@property (nonatomic, assign) CTTextAlignment textAlignment;
@property (nonatomic, assign) SwiftTwips      leftMarginInTwips;
@property (nonatomic, assign) SwiftTwips      rightMarginInTwips;
@property (nonatomic, assign) SwiftTwips      indentInTwips;
@property (nonatomic, assign) SwiftTwips      leadingInTwips;
@property (nonatomic, copy)   NSString       *tabStopsString;

@property (nonatomic, assign) CGFloat         leftMargin;
@property (nonatomic, assign) CGFloat         rightMargin;
@property (nonatomic, assign) CGFloat         indent;
@property (nonatomic, assign) CGFloat         leading;

@end

extern CTFontRef SwiftCreateFont(NSString *name, CGFloat size, BOOL isBold, BOOL isItalic);
