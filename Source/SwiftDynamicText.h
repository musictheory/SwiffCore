/*
    SwiftDynamicText.h
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

#import <Foundation/Foundation.h>

@interface SwiftDynamicText : NSObject <SwiftPlacableObject> {
@private
    NSInteger m_libraryID;
    CGRect m_bounds;
    
    SwiftColor m_color;
    CGColorRef m_cgColor;
    
    NSInteger m_maxLength;
    
    NSString *m_variableName;
    NSString *m_initialText;
    
    BOOL m_wordWrap;
    BOOL m_hasText;
    BOOL m_password;
    BOOL m_multiline;
    BOOL m_editable;
    BOOL m_selectable;
    BOOL m_hasColor;
    BOOL m_autosize;
    BOOL m_hasLayout;
    
    BOOL m_border;
    BOOL m_wasStatic;
    BOOL m_html;
    BOOL m_useOutlines;
}

- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)tagVersion;

@property (nonatomic, retain, readonly) NSString *variableName;
@property (nonatomic, retain, readonly) NSString *initialText;

@property (nonatomic, assign, readonly, getter=isEditable) BOOL editable;
@property (nonatomic, assign, readonly, getter=isSelectable) BOOL selectable;


@end
