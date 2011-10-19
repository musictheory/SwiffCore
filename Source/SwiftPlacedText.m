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

#import "SwiftPlacedText.h"

#import "SwiftHTMLToCoreTextConverter.h"

@implementation SwiftPlacedText

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


- (id) copyWithZone:(NSZone *)zone
{
    SwiftPlacedText *result = [super copyWithZone:zone];

    result->m_text = [m_text copy];
    result->m_attributedText = CFAttributedStringCreateCopy(NULL, m_attributedText);

    return result;
}


- (void) setText:(NSString *)text HTML:(BOOL)isHTML
{
    if ((m_text != text) || (isHTML != m_HTML)) {
        m_text = [text copy];
        m_HTML = m_HTML;
        
        if (m_attributedText) CFRelease(m_attributedText);
        m_attributedText = NULL;
        
        if (m_text) {
            if (isHTML) {
                SwiftHTMLToCoreTextConverter *converter = [SwiftHTMLToCoreTextConverter sharedInstance];
                m_attributedText = [converter copyAttributedStringForHTML:m_text baseFont:NULL];
                CFRetain(m_attributedText);

            } else {
                NSDictionary *attributes = [NSDictionary dictionary];
                m_attributedText = CFAttributedStringCreate(NULL, (__bridge CFStringRef)m_text, (__bridge CFDictionaryRef)attributes);
            }
        }
    }
}


- (void) setText:(NSString *)text
{
    [self setText:text HTML:NO];
}


@synthesize text = m_text,
            attributedText = m_attributedText,
            HTML = m_HTML;


@end
