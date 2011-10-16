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
    UInt16               m_objectID;
    UInt16               m_depth;
    UInt16               m_clipDepth;
    UInt16               m_ratio;
    NSString            *m_instanceName;
    SwiftColorTransform *m_colorTransformPtr;
    CGAffineTransform    m_affineTransform;
}

- (id) initWithDepth:(NSInteger)depth;

@property (nonatomic, retain, readonly) NSString *instanceName;
@property (nonatomic, assign, readonly) UInt16 objectID;
@property (nonatomic, assign, readonly) UInt16 depth;
@property (nonatomic, assign, readonly) UInt16 clipDepth;
@property (nonatomic, assign, readonly) CGFloat ratio;
@property (nonatomic, assign, readonly) CGAffineTransform affineTransform;
@property (nonatomic, assign, readonly) SwiftColorTransform colorTransform;

// Inside pointers, valid for lifetime of the SwiftPlacedObject
@property (nonatomic, assign, readonly) CGAffineTransform *affineTransformPointer;
@property (nonatomic, assign, readonly) SwiftColorTransform *colorTransformPointer;

@property (nonatomic, assign, readonly) BOOL hasAffineTransform;
@property (nonatomic, assign, readonly) BOOL hasColorTransform;

@end
