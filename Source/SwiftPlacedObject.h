//
//  SwiftPlacedObject.h
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-06.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwiftPlacedObject : NSObject <NSCopying> {
@private
    NSInteger           m_objectID;
    NSString           *m_instanceName;
    NSInteger           m_depth;
    NSInteger           m_clipDepth;
    CGFloat             m_ratio;
    CGAffineTransform   m_affineTransform;
    SwiftColorTransform m_colorTransform;
    BOOL                m_hasAffineTransform;
    BOOL                m_hasColorTransform;
}

- (id) initWithDepth:(NSInteger)depth;

@property (nonatomic, retain, readonly) NSString *instanceName;
@property (nonatomic, assign, readonly) NSInteger objectID;
@property (nonatomic, assign, readonly) NSInteger depth;
@property (nonatomic, assign, readonly) NSInteger clipDepth;
@property (nonatomic, assign, readonly) CGFloat   ratio;
@property (nonatomic, assign, readonly) CGAffineTransform affineTransform;
@property (nonatomic, assign, readonly) SwiftColorTransform colorTransform;

// Inside pointers, valid for lifetime of the SwiftPlacedObject
@property (nonatomic, assign, readonly) CGAffineTransform *affineTransformPointer;
@property (nonatomic, assign, readonly) SwiftColorTransform *colorTransformPointer;

@property (nonatomic, assign, readonly) BOOL hasAffineTransform;
@property (nonatomic, assign, readonly) BOOL hasColorTransform;

@end
