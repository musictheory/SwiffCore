/*
    SwiftPlacedText.m
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

#import "SwiftPlacedDynamicText.h"

#import "SwiftDynamicTextAttributes.h"
#import "SwiftHTMLToCoreTextConverter.h"
#import "SwiftMovie.h"
#import "SwiftFontDefinition.h"


@implementation SwiftPlacedDynamicText

- (id) initWithPlacedObject:(SwiftPlacedObject *)placedObject
{
    if ((self = [super initWithPlacedObject:placedObject])) {

        if ([placedObject isKindOfClass:[SwiftPlacedDynamicText class]]) {
            SwiftPlacedDynamicText *placedText = (SwiftPlacedDynamicText *)placedObject;

            m_text = [placedText->m_text copy];
            m_HTML =  placedText->m_HTML;
            m_attributedTextOffset = placedText->m_attributedTextOffset;

            if (placedText->m_attributedText) {
                m_attributedText = CFAttributedStringCreateCopy(NULL, placedText->m_attributedText);
                m_framesetter = CTFramesetterCreateWithAttributedString(m_attributedText);
            }
        }
    }
    
    return self;
}

- (void) dealloc
{
    [m_text release];
    m_text = nil;

    if (m_attributedText) {
        CFRelease(m_attributedText);
        m_attributedText = NULL;
    }

    [super dealloc];
}


- (SwiftDynamicTextAttributes *) _newBaseAttributes
{
    SwiftDynamicTextDefinition *definition = [self definition];
    SwiftDynamicTextAttributes *attributes = [[SwiftDynamicTextAttributes alloc] init];

    if ([definition hasFont]) {
        SwiftFontDefinition *fontDefinition = [[definition movie] fontDefinitionWithLibraryID:[definition fontID]];

        [attributes setFontName: [fontDefinition name]];
        [attributes setBold:     [fontDefinition isBold]];
        [attributes setItalic:   [fontDefinition isItalic]];
    }
    
    [attributes setFontSizeInTwips:    [definition fontHeightInTwips]  ];
    [attributes setFontColor:          [definition colorPointer]       ];
    [attributes setTextAlignment:      [definition textAlignment]      ];
    [attributes setLeftMarginInTwips:  [definition leftMarginInTwips]  ];
    [attributes setRightMarginInTwips: [definition rightMarginInTwips] ];
    [attributes setIndentInTwips:      [definition indentInTwips]      ];
    [attributes setLeadingInTwips:     [definition leadingInTwips]     ];

    return attributes;
}


- (void) setText:(NSString *)text HTML:(BOOL)isHTML
{
    if ((m_text != text) || (isHTML != m_HTML)) {
        m_text = [text copy];
        m_HTML = isHTML;

        if (m_framesetter) CFRelease(m_framesetter);
        m_framesetter = NULL;
        
        if (m_attributedText) CFRelease(m_attributedText);
        m_attributedText = NULL;
        
        if (m_text) {
            if (isHTML) {
                SwiftHTMLToCoreTextConverter *converter = [SwiftHTMLToCoreTextConverter sharedInstance];
                
                SwiftDynamicTextAttributes *baseAttributes = [self _newBaseAttributes];
                m_attributedText = [converter copyAttributedStringForHTML:m_text baseAttributes:baseAttributes];
                [baseAttributes release];

                CFRetain(m_attributedText);

            } else {
                SwiftDynamicTextAttributes *attributes = [self _newBaseAttributes];
                NSDictionary *dictionary = [attributes copyCoreTextAttributes];

                m_attributedText = CFAttributedStringCreate(NULL, (__bridge CFStringRef)m_text, (__bridge CFDictionaryRef)dictionary);

                [dictionary release];
                [attributes release];
            }
        }

        if (m_attributedText) {
            m_framesetter = CTFramesetterCreateWithAttributedString(m_attributedText);
        }
    }
}


- (void) setDefinition:(SwiftDynamicTextDefinition *)definition
{
    if (m_definition != definition) {
        [m_definition release];
        m_definition = [definition retain];
        
        [self setText:[definition initialText] HTML:[definition isHTML]];
    }
}


- (void) setText:(NSString *)text
{
    [self setText:text HTML:NO];
}


@synthesize text                 = m_text,
            framesetter          = m_framesetter,
            attributedText       = m_attributedText,
            attributedTextOffset = m_attributedTextOffset,
            HTML                 = m_HTML;

@dynamic definition;

@end
