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
    NSArray   *m_fillStyles;
    NSArray   *m_lineStyles;
    NSArray   *m_paths;
    NSArray   *m_operations;
    CGRect     m_frame;
    CGRect     m_edgeFrame;
    BOOL       m_usesFillWindingRule;
    BOOL       m_usesNonScalingStrokes;
    BOOL       m_usesScalingStrokes;
}

- (id) initWithParser:(SwiftParser *)parser tag:(SwiftTag)tag version:(SwiftVersion)version;

@property (nonatomic, assign, readonly) NSInteger libraryID;
@property (nonatomic, assign, readonly) CGRect frame;
@property (nonatomic, assign, readonly) CGRect edgeFrame;

@property (nonatomic, retain, readonly) NSArray *paths;

@property (nonatomic, assign, readonly) BOOL usesFillWindingRule;
@property (nonatomic, assign, readonly) BOOL usesNonScalingStrokes;
@property (nonatomic, assign, readonly) BOOL usesScalingStrokes;

@end
