/*
    SwiftPlacedStaticText.m
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

#import "SwiftPlacedStaticText.h"

#if 0
#import "SwiftFontDefinition.h"
#import "SwiftMovie.h"
#import "SwiftStaticTextRecord.h"


static CFStringRef sCreateGlyphs(SwiftFontDefinition *fontDefinition, SwiftStaticTextRecord *textRecord) CF_RETURNS_RETAINED;

static CFStringRef sCreateGlyphs(SwiftFontDefinition *fontDefinition, SwiftStaticTextRecord *textRecord)
{
    NSUInteger                  glyphEntriesCount = [textRecord glyphEntriesCount];
    SwiftTextRecordGlyphEntry *glyphEntries      = [textRecord glyphEntries];
    NSUInteger       codeTableCount    = [fontDefinition glyphCount];
    UInt16          *codeTable         = [fontDefinition codeTable];

    if (!glyphEntriesCount) return NULL;

    unichar *buffer = (unichar *)alloca(glyphEntriesCount * sizeof(unichar));
        
    for (NSUInteger i = 0; i < glyphEntriesCount; i++) {
        UInt16 glyphIndex = glyphEntries[i].index;
        
        if (glyphIndex >= 0 && glyphIndex < codeTableCount) {
            buffer[i] = (unichar)codeTable[glyphIndex];
        }
    }

    return CFStringCreateWithCharacters(NULL, buffer, glyphEntriesCount);
}


@implementation SwiftPlacedStaticText

- (id) initWithPlacedObject:(SwiftPlacedObject *)placedObject
{
    if ((self = [super initWithPlacedObject:placedObject])) {

        if ([placedObject isKindOfClass:[SwiftPlacedStaticText class]]) {
            SwiftPlacedStaticText *placedStaticText = (SwiftPlacedStaticText *)placedObject;

            m_attributedTextOffset = placedStaticText->m_attributedTextOffset;

            if (placedStaticText->m_attributedText) {
                m_attributedText = CFAttributedStringCreateCopy(NULL, placedStaticText->m_attributedText);
            }
        }
    }
    
    return self;
}


- (void) _generateText
{
    if (m_attributedText) return;
    
    CFMutableAttributedStringRef as = CFAttributedStringCreateMutable(NULL, 0);
    CFMutableDictionaryRef attributes = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    m_attributedText = as;

    SwiftStaticTextDefinition *textDefinition = [self definition];
    SwiftFontDefinition       *fontDefinition = nil;

    NSArray  *textRecords       = [textDefinition textRecords];
    NSInteger currentFontID     = 0;
    CGFloat   currentTextHeight = 0.0;
    BOOL      needsFontUpdate   = NO;

    for (SwiftStaticTextRecord *textRecord in textRecords) {
        if ([textRecord hasFont]) {
            NSInteger recordFontID = [textRecord fontID];
            if (currentFontID != recordFontID) {
                currentFontID  = recordFontID;
                fontDefinition = [[textDefinition movie] fontDefinitionWithLibraryID:currentFontID];
                needsFontUpdate = YES;
            }

            CGFloat recordTextHeight = [textRecord textHeight];
            if (currentTextHeight != recordTextHeight) {
                currentTextHeight = recordTextHeight;
                needsFontUpdate = YES;
            }
        }

        if ([textRecord hasColor]) {
            CGColorRef color = SwiftColorCopyCGColor([textRecord color]);
            CFDictionarySetValue(attributes, kCTForegroundColorAttributeName, color);
            CGColorRelease(color);
        }

        if (fontDefinition) {
            if (needsFontUpdate) {
                CTFontRef font = CTFontCreateWithFontDescriptor([fontDefinition fontDescriptor], currentTextHeight, &CGAffineTransformIdentity);

                if (font) {
                    CFDictionarySetValue(attributes, kCTFontAttributeName, font);
                    CFRelease(font);
                }
                
                needsFontUpdate = NO;
            }

            CFStringRef glyphs = sCreateGlyphs(fontDefinition, textRecord);
            if (glyphs) {
                CFAttributedStringRef replacement = NULL;

                if (CFStringGetLength(glyphs)) {
                    replacement = CFAttributedStringCreate(NULL, glyphs, attributes);
                }
                
                if (replacement) {
                    CFAttributedStringReplaceAttributedString(as, CFRangeMake(CFAttributedStringGetLength(as), 0), replacement);
                    CFRelease(replacement);
                }
                
                CFRelease(glyphs);
            }
        }
    }

    if (attributes) CFRelease(attributes);

    if ([textRecords count] > 0) {
        SwiftStaticTextRecord *firstTextRecord = [textRecords objectAtIndex:0];
        m_attributedTextOffset = [firstTextRecord offset];
    }
}    


- (CFAttributedStringRef) attributedText
{
    if (!m_attributedText) {
        [self _generateText];
    }
    
    return m_attributedText;
}


- (CGPoint) attributedTextOffset
{
    if (!m_attributedText) {
        [self _generateText];
    }

    return m_attributedTextOffset;
}


@synthesize attributedText = m_attributedText,
            attributedTextOffset = m_attributedTextOffset;

@dynamic definition;

@end

#endif
