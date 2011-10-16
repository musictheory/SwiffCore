//
//  SwiftShape.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-05.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SwiftShape : NSObject {
@private
    NSInteger  m_libraryID;
    NSData    *m_tagData;
    CFArrayRef m_groups;
    NSArray   *m_fillStyles;
    NSArray   *m_lineStyles;
    NSArray   *m_paths;
    CGRect     m_bounds;
    CGRect     m_edgeBounds;
    BOOL       m_usesFillWindingRule;
    BOOL       m_usesNonScalingStrokes;
    BOOL       m_usesScalingStrokes;
    BOOL       m_hasEdgeBounds;
}

- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(SwiftVersion)version;

@property (nonatomic, assign, readonly) NSInteger libraryID;
@property (nonatomic, assign, readonly) CGRect bounds;
@property (nonatomic, assign, readonly) CGRect edgeBounds;

@property (nonatomic, retain, readonly) NSArray *paths;

@property (nonatomic, assign, readonly) BOOL usesFillWindingRule;
@property (nonatomic, assign, readonly) BOOL usesNonScalingStrokes;
@property (nonatomic, assign, readonly) BOOL usesScalingStrokes;
@property (nonatomic, assign, readonly) BOOL hasEdgeBounds;

@end
