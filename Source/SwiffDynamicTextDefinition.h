/*
    SwiffDynamicText.h
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

#import <SwiffImport.h>
#import <SwiffTypes.h>
#import <SwiffDefinition.h>
#import <SwiffParser.h>

@class SwiffMovie;


@interface SwiffDynamicTextDefinition : NSObject <SwiffDefinition>

- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie;

@property (nonatomic, strong, readonly) NSString *variableName;
@property (nonatomic, strong, readonly) NSString *initialText;

@property (nonatomic, assign, readonly) NSUInteger maxLength;

@property (nonatomic, assign, readonly, getter=isEditable) BOOL editable;
@property (nonatomic, assign, readonly, getter=isSelectable) BOOL selectable;
@property (nonatomic, assign, readonly, getter=isHTML) BOOL HTML;

@property (nonatomic, assign, readonly) BOOL hasLayout;
@property (nonatomic, assign, readonly) CTTextAlignment textAlignment;

@property (nonatomic, assign, readonly) SwiffTwips leftMarginInTwips;
@property (nonatomic, assign, readonly) SwiffTwips rightMarginInTwips;
@property (nonatomic, assign, readonly) SwiffTwips indentInTwips;
@property (nonatomic, assign, readonly) SwiffTwips leadingInTwips;

@property (nonatomic, assign, readonly) CGFloat leftMargin;
@property (nonatomic, assign, readonly) CGFloat rightMargin;
@property (nonatomic, assign, readonly) CGFloat indent;
@property (nonatomic, assign, readonly) CGFloat leading;

@property (nonatomic, assign, readonly) BOOL hasFont;
@property (nonatomic, assign, readonly) BOOL hasFontClass;
@property (nonatomic, assign, readonly) UInt16 fontID;
@property (nonatomic, strong, readonly) NSString *fontClass;
@property (nonatomic, assign, readonly) CGFloat fontHeight;
@property (nonatomic, assign, readonly) SwiffTwips fontHeightInTwips;

@property (nonatomic, assign, readonly) BOOL hasColor;
@property (nonatomic, assign, readonly) SwiffColor color;
@property (nonatomic, assign, readonly) SwiffColor *colorPointer;

@end
