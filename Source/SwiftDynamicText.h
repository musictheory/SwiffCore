//
//  SwiftText.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

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
