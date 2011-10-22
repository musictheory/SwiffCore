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

- (id) initWithPlacedObject:(SwiftPlacedObject *)placedObject
{
    if ((self = [super initWithPlacedObject:placedObject])) {

        if ([placedObject isKindOfClass:[SwiftPlacedText class]]) {
            SwiftPlacedText *placedText = (SwiftPlacedText *)placedObject;

            m_text = [placedText->m_text copy];
            m_HTML =  placedText->m_HTML;
            m_attributedTextOffset = placedText->m_attributedTextOffset;

            if (placedText->m_attributedText) {
                m_attributedText = CFAttributedStringCreateCopy(NULL, placedText->m_attributedText);
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

#if 0
    SWFDefineEditTextTag *tag = _dynamicTag;

    if (!string) {
        const char *initialText = (const char *)_dynamicTag->initialText;
        string = _dynamicTag->initialText ? [NSString stringWithCString:initialText encoding:NSUTF8StringEncoding] : nil;
    }

    if (tag->html) {
        NSDictionary *documentAttributes = nil;
        NSAttributedString *escaped = [[NSAttributedString alloc] initWithHTML:[string dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:&documentAttributes];
        string = [[[escaped string] retain] autorelease];
        [escaped release];
    }
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];

    NSFont *font = [_movie fontForID:tag->fontID size:tag->fontHeight];
    if (font) {
        [attributes setObject:font forKey:NSFontAttributeName];
    }

    if (tag->hasColor) {
        NSColor *color = [NSColor colorWithDeviceRed: (tag->color.red   / 255.0) 
                                               green: (tag->color.green / 255.0)
                                                blue: (tag->color.blue  / 255.0)
                                               alpha: (tag->color.alpha / 255.0)];
        
        [attributes setObject:color forKey:NSForegroundColorAttributeName];
    }

    NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:string attributes:attributes];

    NSRect bounds       = sNSRectFromSWFRect(&tag->bounds, tag->leftMargin, tag->rightMargin);
    NSRect boundingRect = [as boundingRectWithSize:NSMakeSize(INFINITY, INFINITY) options:NSStringDrawingOneShot];

    bounds.origin.y += (boundingRect.size.height + boundingRect.origin.y);

    // Flash seems to calculate lbearing and rbearing differently from all
    // other font rendering engines.  Tweak it by adding an additional 1 pixel
    // for font sizes 10-19, 2 pixels for 20-29, etc.
    //
    int fakePadding = ((int)floor(tag->fontHeight / 200));

    if (tag->align == SWFTextAlignRight) {
        bounds.origin.x  += bounds.size.width - boundingRect.size.width;
        bounds.origin.x  -= fakePadding;
        bounds.size.width = boundingRect.size.width;
    
    } else if (tag->align == SWFTextAlignCenter) {
        bounds.origin.x  += ((bounds.size.width - boundingRect.size.width) / 2.0);
        bounds.size.width = boundingRect.size.width;
    } else {
        bounds.origin.x += fakePadding;
    }

    [attributes release];

    *boundsPtr = bounds;
    *asPtr     = [as autorelease];
    
    return (as != nil);

#endif


- (void) setText:(NSString *)text HTML:(BOOL)isHTML
{
    if ((m_text != text) || (isHTML != m_HTML)) {
        m_text = [text copy];
        m_HTML = isHTML;
        
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


- (void) setDefinition:(SwiftTextDefinition *)definition
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
            attributedText       = m_attributedText,
            attributedTextOffset = m_attributedTextOffset,
            HTML                 = m_HTML;

@dynamic definition;

@end
