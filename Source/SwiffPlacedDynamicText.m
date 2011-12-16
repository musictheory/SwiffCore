/*
    SwiffPlacedText.m
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

#import "SwiffPlacedDynamicText.h"

#import "SwiffDynamicTextAttributes.h"
#import "SwiffHTMLToCoreTextConverter.h"
#import "SwiffMovie.h"
#import "SwiffFontDefinition.h"
#import "SwiffPlacedDynamicText.h"


@implementation SwiffPlacedDynamicText

- (id) initWithPlacedObject:(SwiffPlacedObject *)placedObject
{
    if ((self = [super initWithPlacedObject:placedObject])) {

        if ([placedObject isKindOfClass:[SwiffPlacedDynamicText class]]) {
            SwiffPlacedDynamicText *placedText = (SwiffPlacedDynamicText *)placedObject;

            m_text = [placedText->m_text copy];
            m_HTML =  placedText->m_HTML;

            if (placedText->m_attributedText) {
                m_attributedText = CFAttributedStringCreateCopy(NULL, placedText->m_attributedText);
            }
        }
    }
    
    return self;
}


- (void) dealloc
{
    [m_definition release];
    m_definition = nil;

    [m_text release];
    m_text = nil;

    if (m_attributedText) {
        CFRelease(m_attributedText);
        m_attributedText = NULL;
    }

    [super dealloc];
}


- (SwiffDynamicTextAttributes *) _newBaseAttributes
{
    SwiffDynamicTextAttributes *attributes = [[SwiffDynamicTextAttributes alloc] init];

    if ([m_definition hasFont]) {
        SwiffFontDefinition *fontDefinition = [[m_definition movie] fontDefinitionWithLibraryID:[m_definition fontID]];

        [attributes setFontName: [fontDefinition name]];
        [attributes setBold:     [fontDefinition isBold]];
        [attributes setItalic:   [fontDefinition isItalic]];
    }
    
    [attributes setFontSizeInTwips:    [m_definition fontHeightInTwips]  ];
    [attributes setFontColor:          [m_definition colorPointer]       ];
    [attributes setTextAlignment:      [m_definition textAlignment]      ];
    [attributes setLeftMarginInTwips:  [m_definition leftMarginInTwips]  ];
    [attributes setRightMarginInTwips: [m_definition rightMarginInTwips] ];
    [attributes setIndentInTwips:      [m_definition indentInTwips]      ];
    [attributes setLeadingInTwips:     [m_definition leadingInTwips]     ];

    return attributes;
}


- (void) setupWithDefinition:(id<SwiffPlacableDefinition>)definition
{
    if (m_definition != definition) {
        [m_definition release];
        m_definition = nil;
        
        if ([definition isKindOfClass:[SwiffDynamicTextDefinition class]]) {
            m_definition = (SwiffDynamicTextDefinition *)[definition retain];
            [self setText:[m_definition initialText] HTML:[m_definition isHTML]]; 
        }
    }
}


- (void) setText:(NSString *)text HTML:(BOOL)isHTML
{
    if ((m_text != text) || (isHTML != m_HTML)) {
        if (m_text != text) {
            [m_text release];
            m_text = [text copy];
        }

        m_HTML = isHTML;

        if (m_attributedText) CFRelease(m_attributedText);
        m_attributedText = NULL;
        
        if (m_text) {
            if (isHTML) {
                SwiffHTMLToCoreTextConverter *converter = [SwiffHTMLToCoreTextConverter sharedInstance];
                
                SwiffDynamicTextAttributes *baseAttributes = [self _newBaseAttributes];
                m_attributedText = [converter copyAttributedStringForHTML:m_text baseAttributes:baseAttributes];
                [baseAttributes release];

                CFRetain(m_attributedText);

            } else {
                SwiffDynamicTextAttributes *attributes = [self _newBaseAttributes];
                NSDictionary *dictionary = [attributes copyCoreTextAttributes];

                m_attributedText = CFAttributedStringCreate(NULL, (__bridge CFStringRef)m_text, (__bridge CFDictionaryRef)dictionary);

                [dictionary release];
                [attributes release];
            }
        }
    }
}


- (void) setText:(NSString *)text
{
    [self setText:text HTML:NO];
}


@synthesize text           = m_text,
            definition     = m_definition,
            attributedText = m_attributedText,
            HTML           = m_HTML;

@end
