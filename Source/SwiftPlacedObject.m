//
//  SwiftPlacedObject.m
//  TheoryLessons
//
//  Created by Ricci Adams on 2011-10-06.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftPlacedObject.h"

@interface SwiftPlacedObject ()
@property (nonatomic, retain) NSString *instanceName;
@property (nonatomic, assign) NSInteger objectID;
@property (nonatomic, assign) NSInteger depth;
@property (nonatomic, assign) NSInteger clipDepth;
@property (nonatomic, assign) CGFloat   ratio;
@property (nonatomic, assign) CGAffineTransform affineTransform;
@property (nonatomic, assign) SwiftColorTransform colorTransform;
@end

@implementation SwiftPlacedObject

- (id) initWithDepth:(NSInteger)depth
{
    if ((self = [super init])) {
        m_affineTransform = CGAffineTransformIdentity;
        m_depth = depth;
    }

    return self;
}


- (void) dealloc
{
    if (m_colorTransformPtr) {
        free(m_colorTransformPtr);
        m_colorTransformPtr = NULL;
    }

    [m_instanceName release];
    m_instanceName = nil;
    
    [super dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
    SwiftPlacedObject *result = NSCopyObject(self, 0, zone);

    if (m_colorTransformPtr) {
        result->m_colorTransformPtr = NULL;
        [result setColorTransform:*m_colorTransformPtr];
    }

    result->m_instanceName = [m_instanceName copy];

    return result;
}


#pragma mark -
#pragma mark Accessors

- (CGAffineTransform *) affineTransformPointer
{
    return &m_affineTransform;
}


- (void) setColorTransform:(SwiftColorTransform)colorTransform
{
    if (!m_colorTransformPtr) {
        m_colorTransformPtr = malloc(sizeof(SwiftColorTransform));
    }

    *m_colorTransformPtr = colorTransform;
}


- (SwiftColorTransform) colorTransform
{
    return m_colorTransformPtr ? *m_colorTransformPtr : SwiftColorTransformIdentity;
}


- (SwiftColorTransform *) colorTransformPointer
{
    return m_colorTransformPtr ? m_colorTransformPtr : &SwiftColorTransformIdentity;
}


- (void) setRatio:(CGFloat)ratio
{
    m_ratio = ratio * 65535.0;
}


- (CGFloat) ratio
{
    return m_ratio / 65535.0;
}


@synthesize instanceName       = m_instanceName,
            objectID           = m_objectID,
            depth              = m_depth,
            clipDepth          = m_clipDepth,
            affineTransform    = m_affineTransform,
            hasAffineTransform = m_hasAffineTransform,
            hasColorTransform  = m_hasColorTransform;


@end
