//
//  SwiftPath.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-06.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SwiftLineStyle;
@class SwiftFillStyle;


@interface SwiftPath : NSObject {
@private
    NSArray        *m_operations;
    SwiftLineStyle *m_lineStyle;
    SwiftFillStyle *m_fillStyle;
}

- (id) initWithPathOperations: (NSArray *) operations
                    lineStyle: (SwiftLineStyle *) lineStyle
                    fillStyle: (SwiftFillStyle *) fillStyle;

@property (nonatomic, retain, readonly) NSArray *operations;
@property (nonatomic, retain, readonly) SwiftLineStyle *lineStyle;
@property (nonatomic, retain, readonly) SwiftFillStyle *fillStyle;

@end
