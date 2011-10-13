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
        m_colorTransform  = SwiftColorTransformIdentity;
        m_depth           = depth;
    }

    return self;
}


- (void) dealloc
{
    [m_instanceName release];
    m_instanceName = nil;
    
    [super dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
    SwiftPlacedObject *result = NSCopyObject(self, 0, zone);
    result->m_instanceName = [m_instanceName copy];
    return result;
}


- (CGAffineTransform *) affineTransformPointer
{
    return &m_affineTransform;
}


- (SwiftColorTransform *) colorTransformPointer
{
    return &m_colorTransform;
}


- (void) setAffineTransform:(CGAffineTransform)affineTransform
{
    if (m_hasAffineTransform || !CGAffineTransformIsIdentity(affineTransform)) {
        m_affineTransform = affineTransform;
        m_hasAffineTransform = YES;
    }
}


- (void) setColorTransform:(SwiftColorTransform)colorTransform
{
    m_colorTransform = colorTransform;
    m_hasColorTransform = YES;
}


@synthesize instanceName       = m_instanceName,
            objectID           = m_objectID,
            depth              = m_depth,
            clipDepth          = m_clipDepth,
            ratio              = m_ratio,
            affineTransform    = m_affineTransform,
            colorTransform     = m_colorTransform,
            hasAffineTransform = m_hasAffineTransform,
            hasColorTransform  = m_hasColorTransform;


@end
