//
//  SwiftPathOperation.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-06.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//


enum {
    SwiftPathOperationTypeMove  = 0,
    SwiftPathOperationTypeLine  = 1,
    SwiftPathOperationTypeCurve = 2
};
typedef NSInteger SwiftPathOperationType;


@interface SwiftPathOperation : NSObject {
@private
    NSInteger  m_type;
    CGPoint    m_fromPoint;
    CGPoint    m_controlPoint;
    CGPoint    m_toPoint;

@package
    SwiftPoint m_fromSwiftPoint;
    SwiftPoint m_toSwiftPoint;
    UInt16     m_lineStyleIndex;
    UInt16     m_fillStyleIndex;
    BOOL       m_duplicate;
}

- (id) initWithType: (SwiftPathOperationType) type
          fromPoint: (CGPoint) fromPoint
       controlPoint: (CGPoint) controlPoint
            toPoint: (CGPoint) toPoint;

@property (nonatomic, assign, readonly) SwiftPathOperationType type;

@property (nonatomic, assign, readonly) CGPoint fromPoint;
@property (nonatomic, assign, readonly) CGPoint controlPoint;
@property (nonatomic, assign, readonly) CGPoint toPoint;

@end
