//
//  SwiftTextRecord.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-07.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwiftTextRecord : NSObject {
@private
    NSInteger m_fontID;
    NSInteger m_glyphCount;

    CGPoint m_offset;
    CGFloat m_height;
    SwiftColor m_color;
    BOOL m_hasFont;
    BOOL m_hasColor;
    
    UInt16  *m_glyphIndex;
    CGFloat *m_glyphAdvance;
}

+ (NSArray *) textRecordArrayWithParser: (SwiftParser *) parser
                                    tag: (SwiftTag) tag
                                version: (NSInteger) version
                              glyphBits: (UInt8) glyphBits
                            advanceBits: (UInt8) advanceBits;

- (id) initWithParser: (SwiftParser *) parser
                  tag: (SwiftTag) tag
              version: (NSInteger) version
            glyphBits: (UInt8) glyphBits
          advanceBits: (UInt8) advanceBits;

@end
