/*
    SwiftHTMLToCoreTextConverter.m
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

#import "SwiftHTMLToCoreTextConverter.h"

#import "SwiftBase.h"
#import "SwiftDynamicTextAttributes.h"

#include <libxml/HTMLparser.h>

enum {
    SwiftHTMLToCoreTextConverterTag_Unknown = 0,

    SwiftHTMLToCoreTextConverterTag_A,
    SwiftHTMLToCoreTextConverterTag_B,
    SwiftHTMLToCoreTextConverterTag_I,
    SwiftHTMLToCoreTextConverterTag_P,
    SwiftHTMLToCoreTextConverterTag_U,
    SwiftHTMLToCoreTextConverterTag_BR,
    SwiftHTMLToCoreTextConverterTag_LI,
    SwiftHTMLToCoreTextConverterTag_TAB,
    SwiftHTMLToCoreTextConverterTag_FONT,
    SwiftHTMLToCoreTextConverterTag_TEXTFORMAT
};
typedef NSInteger SwiftHTMLToCoreTextConverterTag;


@implementation SwiftHTMLToCoreTextConverter

+ (id) sharedInstance
{
    static id sharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}


#pragma mark -
#pragma mark Parsing

- (void) _flush
{
    if ([m_characters length]) {
        [m_attributes setBold:      (m_boldCount      > 0)];
        [m_attributes setItalic:    (m_italicCount    > 0)];
        [m_attributes setUnderline: (m_underlineCount > 0)];
        
        NSDictionary *coreTextAttributes = [m_attributes copyCoreTextAttributes];
       
        CFAttributedStringRef replacement = CFAttributedStringCreate(NULL, (__bridge CFStringRef)m_characters, (__bridge CFDictionaryRef)coreTextAttributes); 
        CFAttributedStringReplaceAttributedString(m_output, CFRangeMake(CFAttributedStringGetLength(m_output), 0), replacement);
        CFRelease(replacement);
        
        [coreTextAttributes release];
        
        [m_characters release];
        m_characters = [[NSMutableString alloc] init];
    }
}


- (void) _cloneAttributes
{
    SwiftDynamicTextAttributes *oldAttributes = m_attributes;
    m_attributes = [m_attributes copy];
    [oldAttributes release]; 
}


static SwiftHTMLToCoreTextConverterTag sGetTagForString(const xmlChar *inString)
{
    const char  c = toupper(inString[0]);
    const char *s = (const char *)inString;
    size_t length = strlen(s);

    if (     (c == 'A') && (0 == strncasecmp("A",          s, length)))  return SwiftHTMLToCoreTextConverterTag_A;
    else if ((c == 'B') && (0 == strncasecmp("B",          s, length)))  return SwiftHTMLToCoreTextConverterTag_B;
    else if ((c == 'B') && (0 == strncasecmp("BR",         s, length)))  return SwiftHTMLToCoreTextConverterTag_BR;
    else if ((c == 'F') && (0 == strncasecmp("FONT",       s, length)))  return SwiftHTMLToCoreTextConverterTag_FONT;
    else if ((c == 'I') && (0 == strncasecmp("I",          s, length)))  return SwiftHTMLToCoreTextConverterTag_I;
    else if ((c == 'L') && (0 == strncasecmp("LI",         s, length)))  return SwiftHTMLToCoreTextConverterTag_LI;
    else if ((c == 'P') && (0 == strncasecmp("P",          s, length)))  return SwiftHTMLToCoreTextConverterTag_P;
    else if ((c == 'T') && (0 == strncasecmp("TAB",        s, length)))  return SwiftHTMLToCoreTextConverterTag_TAB;
    else if ((c == 'T') && (0 == strncasecmp("TEXTFORMAT", s, length)))  return SwiftHTMLToCoreTextConverterTag_TEXTFORMAT;
    else if ((c == 'U') && (0 == strncasecmp("U",          s, length)))  return SwiftHTMLToCoreTextConverterTag_U;
    
    return SwiftHTMLToCoreTextConverterTag_Unknown;
}


static void sStartFontElement(SwiftHTMLToCoreTextConverter *self, xmlElementPtr element)
{
    SwiftDynamicTextAttributes *attributes = self->m_attributes;

    // Handle "face" attribute
    {
        char *faceCString = (char *)xmlGetProp((xmlNodePtr)element, (xmlChar *)"face");

        if (faceCString) {
            NSString *fontName = [[NSString alloc] initWithBytesNoCopy:faceCString length:strlen(faceCString) encoding:NSUTF8StringEncoding freeWhenDone:YES];
            [attributes setFontName:fontName];
            [fontName release];
        }
    }

    // Handle "size" attribute
    {
        char *sizeCString  = (char *)xmlGetProp((xmlNodePtr)element, (xmlChar *)"size");

        if (sizeCString) {
            char c0 = sizeCString[0];
            
            SwiftTwips fontSizeInTwips = [attributes fontSizeInTwips];
            
            if (c0 == '+') {
                fontSizeInTwips += atoi(&sizeCString[1]);
            } else if (c0 == '-') {
                fontSizeInTwips -= atoi(&sizeCString[1]);
            } else {
                fontSizeInTwips  = atoi(sizeCString);
            }
            
            [attributes setFontSizeInTwips:fontSizeInTwips];
            
            free(sizeCString);
        }
    }

    // Handle "color" attribute
    {
        char *colorCString = (char *)xmlGetProp((xmlNodePtr)element, (xmlChar *)"color");

        if (colorCString) {
            if (colorCString[0] == '#') {
            
//!i:                self->m_fontColor = strtoul(&colorCString[1], NULL, 16);
            }

            free(colorCString);
        }
    }
    
    //!spec: Handle undocumented "letterSpacing" attribute
    {
        char *spacingCString = (char *)xmlGetProp((xmlNodePtr)element, (xmlChar *)"letterSpacing");

        if (spacingCString) {
            free(spacingCString);
        }
    }
    
}


static void sStartParagraphElement(SwiftHTMLToCoreTextConverter *self, xmlElementPtr element)
{
    SwiftDynamicTextAttributes *attributes = self->m_attributes;

    char *alignCString  = (char *)xmlGetProp((xmlNodePtr)element, (xmlChar *)"align");

    if (alignCString) {
        if (0 == strcasecmp(alignCString, "left")) {
            [attributes setTextAlignment:kCTLeftTextAlignment];
        } else if (0 == strcasecmp(alignCString, "center")) {
            [attributes setTextAlignment:kCTCenterTextAlignment];
        } else if (0 == strcasecmp(alignCString, "right")) {
            [attributes setTextAlignment:kCTRightTextAlignment];
        }
    }
}


static void sStartTextFormatElement(SwiftHTMLToCoreTextConverter *self, xmlElementPtr element)
{
    SwiftDynamicTextAttributes *attributes = self->m_attributes;

    char *leftMarginCString  = (char *)xmlGetProp((xmlNodePtr)element, (xmlChar *)"leftmargin");
    char *rightMarginCString = (char *)xmlGetProp((xmlNodePtr)element, (xmlChar *)"rightmargin");
    char *indentCString      = (char *)xmlGetProp((xmlNodePtr)element, (xmlChar *)"indent");
    char *leadingCString     = (char *)xmlGetProp((xmlNodePtr)element, (xmlChar *)"leading");
    char *blockIndentCString = (char *)xmlGetProp((xmlNodePtr)element, (xmlChar *)"blockindent");
    char *tabStopsCString    = (char *)xmlGetProp((xmlNodePtr)element, (xmlChar *)"tabstops");

    if (leftMarginCString) {
        [attributes setLeftMarginInTwips:atoi(leftMarginCString)];
    }

    if (rightMarginCString) {
        [attributes setRightMarginInTwips:atoi(rightMarginCString)];
    }

    if (indentCString) {
        [attributes setIndentInTwips:atoi(indentCString)];
    }

    if (leadingCString) {
        [attributes setLeadingInTwips:atoi(leadingCString)];
    }

    if (tabStopsCString) {
        NSString *tabStops = [[NSString alloc] initWithBytesNoCopy:tabStopsCString length:strlen(tabStopsCString) encoding:NSUTF8StringEncoding freeWhenDone:YES];
        [attributes setTabStopsString:tabStops];
        [tabStops release];
    }

    // What is the difference between block indent and left margin?
    if (blockIndentCString) {
        SwiftTwips twips = [attributes leftMarginInTwips];
        twips += atoi(leftMarginCString); 
        [attributes setLeftMarginInTwips:twips];
    }

    free(leftMarginCString);
    free(rightMarginCString);
    free(indentCString);
    free(leadingCString);
    free(blockIndentCString);
    free(tabStopsCString);
}


static void sStartElement(SwiftHTMLToCoreTextConverter *self, xmlElementPtr element, SwiftHTMLToCoreTextConverterTag tag)
{
    if (tag == SwiftHTMLToCoreTextConverterTag_A) {
        // Not yet implemented: Dynamic Text HTML <a> support

    } else if (tag == SwiftHTMLToCoreTextConverterTag_B) {
        [self _flush];  self->m_boldCount++;

    } else if (tag == SwiftHTMLToCoreTextConverterTag_BR) {
        [self->m_characters appendString:@"\n"];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_FONT) {
        [self _flush];
        [self _cloneAttributes];
        sStartFontElement(self, element);

    } else if (tag == SwiftHTMLToCoreTextConverterTag_I) {
        [self _flush];  self->m_italicCount++;

    } else if (tag == SwiftHTMLToCoreTextConverterTag_LI) {
        [self->m_characters appendFormat:@"%C ", 0x2022];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_P) {
        [self _flush];
        [self _cloneAttributes];
        sStartParagraphElement(self, element);

    } else if (tag == SwiftHTMLToCoreTextConverterTag_TAB) {
        [self->m_characters appendString:@"\t"];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_TEXTFORMAT) {
        [self _flush];
        [self _cloneAttributes];
        sStartTextFormatElement(self, element);

    } else if (tag == SwiftHTMLToCoreTextConverterTag_U) {
        [self _flush];  self->m_underlineCount++;
    }
}


static void sEndElement(SwiftHTMLToCoreTextConverter *self, xmlElementPtr element, SwiftHTMLToCoreTextConverterTag tag)
{
    if (tag == SwiftHTMLToCoreTextConverterTag_A) {
        // Not yet implemented: Dynamic Text HTML <a> support

    } else if (tag == SwiftHTMLToCoreTextConverterTag_B) {
        self->m_boldCount--;  [self _flush];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_FONT) {
        [self _flush];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_I) {
        self->m_italicCount--;  [self _flush];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_LI) {
        [self->m_characters appendString:@"\n"];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_P) {
        // Not yet implemented: Dynamic Text HTML <p> support

    } else if (tag == SwiftHTMLToCoreTextConverterTag_TEXTFORMAT) {
        [self _flush];

    } else if (tag == SwiftHTMLToCoreTextConverterTag_U) {
        self->m_underlineCount--;  [self _flush];
    }
}


static void sParseNode(SwiftHTMLToCoreTextConverter *self, xmlNodePtr node)
{
    SwiftDynamicTextAttributes *savedAttributes = [self->m_attributes retain];
    
    xmlElementType type    = node->type;
    xmlElementPtr  element = (type == XML_ELEMENT_NODE) ? (xmlElementPtr)node : NULL;
    SwiftHTMLToCoreTextConverterTag tag = element ? sGetTagForString(element->name) : SwiftHTMLToCoreTextConverterTag_Unknown;

    if (tag != SwiftHTMLToCoreTextConverterTag_Unknown) {
        sStartElement(self, element, tag);
    }

    if (element || (type == XML_DOCUMENT_NODE) || (type == XML_HTML_DOCUMENT_NODE)) {
        xmlNodePtr childNode = xmlFirstElementChild(node);
        while (childNode) {
            sParseNode(self, childNode);
            childNode = xmlNextElementSibling(childNode);
        }
    } 
    
    if (node->content) {
        xmlChar *content = xmlNodeGetContent(node);

        if (content) {
            size_t length = strlen((const char *)content);

            NSString *string = [[NSString alloc] initWithBytesNoCopy:(void *)content length:length encoding:NSUTF8StringEncoding freeWhenDone:YES];
            [self->m_characters appendString:string];
            [string release];
        }
    }

    if (tag != SwiftHTMLToCoreTextConverterTag_Unknown) {
        sEndElement(self, element, tag);
    }

    // Restore parser state from stack
    [self->m_attributes release];
    self->m_attributes = savedAttributes;
}


- (CFAttributedStringRef) copyAttributedStringForHTML:(NSString *)string baseAttributes:(SwiftDynamicTextAttributes *)baseAttributes
{
    if (!string) return NULL;

    CFStringRef cfString = (__bridge CFStringRef)string;
    CFIndex     length   = 0;
    CFRange     range    = CFRangeMake(0, CFStringGetLength(cfString));

    CFStringGetBytes((__bridge CFStringRef)string, range, kCFStringEncodingUTF8, 0, 0, NULL, 0, &length);

    UInt8 *buffer = (UInt8 *)malloc(length);
    CFStringGetBytes(cfString, range, kCFStringEncodingUTF8, 0, 0, buffer, length, &length);
    
    htmlDocPtr htmlDoc = htmlReadMemory((const char *)buffer, length, NULL, "UTF-8", 0);
   
    m_characters     = [[NSMutableString alloc] init];
    m_output         = CFAttributedStringCreateMutable(NULL, 0);
    m_attributes     = [baseAttributes retain];
    m_boldCount      = [baseAttributes isBold]      ? 1 : 0;
    m_italicCount    = [baseAttributes isItalic]    ? 1 : 0;
    m_underlineCount = [baseAttributes isUnderline] ? 1 : 0;

    if (!m_attributes) {
        m_attributes = [[SwiftDynamicTextAttributes alloc] init];
    }

    if (htmlDoc) {
        sParseNode(self, (xmlNodePtr)htmlDoc);
        xmlFreeDoc(htmlDoc);

        [self _flush];
    }

    CFAttributedStringRef output = m_output;
    m_output = NULL;

    [m_attributes release];
    m_attributes = nil;

    [m_characters release];
    m_characters = nil;
    
    free(buffer);
    
    return output;
}

@end
