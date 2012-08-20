/*
    SwiffPlacedText.m
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

#import "SwiffPlacedDynamicText.h"

#import "SwiffDynamicTextAttributes.h"
#import "SwiffHTMLToCoreTextConverter.h"
#import "SwiffMovie.h"
#import "SwiffFontDefinition.h"
#import "SwiffPlacedDynamicText.h"


@implementation SwiffPlacedDynamicText {
    CFAttributedStringRef  _attributedText;
}


- (id) initWithPlacedObject:(SwiffPlacedObject *)placedObject
{
    if ((self = [super initWithPlacedObject:placedObject])) {

        if ([placedObject isKindOfClass:[SwiffPlacedDynamicText class]]) {
            SwiffPlacedDynamicText *placedText = (SwiffPlacedDynamicText *)placedObject;

            _text = [placedText->_text copy];
            _HTML =  placedText->_HTML;

            if (placedText->_attributedText) {
                _attributedText = CFAttributedStringCreateCopy(NULL, placedText->_attributedText);
            }
        }
    }
    
    return self;
}


- (void) dealloc
{
    if (_attributedText) {
        CFRelease(_attributedText);
        _attributedText = NULL;
    }
}


- (SwiffDynamicTextAttributes *) _newBaseAttributes
{
    SwiffDynamicTextAttributes *attributes = [[SwiffDynamicTextAttributes alloc] init];

    if ([_definition hasFont]) {
        SwiffFontDefinition *fontDefinition = [[_definition movie] fontDefinitionWithLibraryID:[_definition fontID]];

        [attributes setFontName: [fontDefinition name]];
        [attributes setBold:     [fontDefinition isBold]];
        [attributes setItalic:   [fontDefinition isItalic]];
    }
    
    [attributes setFontSizeInTwips:    [_definition fontHeightInTwips]  ];
    [attributes setFontColor:          [_definition colorPointer]       ];
    [attributes setTextAlignment:      [_definition textAlignment]      ];
    [attributes setLeftMarginInTwips:  [_definition leftMarginInTwips]  ];
    [attributes setRightMarginInTwips: [_definition rightMarginInTwips] ];
    [attributes setIndentInTwips:      [_definition indentInTwips]      ];
    [attributes setLeadingInTwips:     [_definition leadingInTwips]     ];

    return attributes;
}


- (void) setupWithDefinition:(id<SwiffDefinition>)definition
{
    if (_definition != definition) {
        _definition = nil;
        
        if ([definition isKindOfClass:[SwiffDynamicTextDefinition class]]) {
            _definition = (SwiffDynamicTextDefinition *)definition;
            [self setText:[_definition initialText] HTML:[_definition isHTML]]; 
        }
    }
}


- (void) setText:(NSString *)text HTML:(BOOL)isHTML
{
    if ((_text != text) || (isHTML != _HTML)) {
        if (_text != text) {
            _text = [text copy];
        }

        _HTML = isHTML;

        if (_attributedText) CFRelease(_attributedText);
        _attributedText = NULL;
        
    }
}


- (void) setText:(NSString *)text
{
    [self setText:text HTML:NO];
}


- (CFAttributedStringRef) attributedText
{
    if (!_attributedText && _text) {
        if (_HTML) {
            SwiffHTMLToCoreTextConverter *converter = [SwiffHTMLToCoreTextConverter sharedInstance];
            
            SwiffDynamicTextAttributes *baseAttributes = [self _newBaseAttributes];
            _attributedText = [converter copyAttributedStringForHTML:_text baseAttributes:baseAttributes];

        } else {
            SwiffDynamicTextAttributes *attributes = [self _newBaseAttributes];
            NSDictionary *dictionary = [attributes copyCoreTextAttributes];

            _attributedText = CFAttributedStringCreate(NULL, (__bridge CFStringRef)_text, (__bridge CFDictionaryRef)dictionary);
        }
    }

    return _attributedText;
}

@end
