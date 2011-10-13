//
//  SwiftStaticText.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-07.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwiftStaticText : NSObject <SwiftPlacableObject> {
@private
    NSInteger m_libraryID;
    CGRect m_bounds;
    CGAffineTransform m_affineTransform;
    
    NSArray *m_textRecords;
}

- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(NSInteger)tagVersion;

@end
