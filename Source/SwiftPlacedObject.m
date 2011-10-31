/*
    SwiftPlacedObject.m
    Copyright (c) 2011, musictheory.net, LLC.  All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
          notice, this list of conditions and the following disclaimer in the
          documentation and/or other materials provided with the distribution.
        * Neither the name of musictheory.net, LLC nor the names of its contributors
          may be used to endorse or promote products derived from this software
          without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL MUSICTHEORY.NET, LLC BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import "SwiftPlacedObject.h"


@implementation SwiftPlacedObject


- (id) initWithDepth:(NSInteger)depth
{
    if ((self = [super init])) {
        m_affineTransform = CGAffineTransformIdentity;
        m_depth = depth;
    }

    return self;
}


- (id) initWithPlacedObject:(SwiftPlacedObject *)placedObject
{
    if ((self = [self initWithDepth:placedObject->m_depth])) {
        m_libraryID         = placedObject->m_libraryID;
        m_clipDepth         = placedObject->m_clipDepth;
        m_ratio             = placedObject->m_ratio;
        m_affineTransform   = placedObject->m_affineTransform;
        m_instanceName      = [placedObject->m_instanceName copy];
        m_definition        = [placedObject->m_definition retain];

        if (placedObject->m_colorTransformPtr) {
            [self setColorTransform:*placedObject->m_colorTransformPtr];
        }
    }
    
    return self;
}


- (void) dealloc
{
    [m_definition release];
    m_definition = nil;
    
    if (m_colorTransformPtr) {
        free(m_colorTransformPtr);
        m_colorTransformPtr = NULL;
    }

    [m_instanceName release];
    m_instanceName = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark Accessors

- (void) setRatio:(CGFloat)ratio
{
    m_ratio = ratio * 65535.0;
}


- (CGFloat) ratio
{
    return m_ratio / 65535.0;
}


- (BOOL) hasAffineTransform
{
    return !CGAffineTransformIsIdentity(m_affineTransform);
}


- (CGAffineTransform *) affineTransformPointer
{
    return &m_affineTransform;
}


- (BOOL) hasColorTransform
{
    return (m_colorTransformPtr != NULL);
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


@synthesize definition         = m_definition,
            instanceName       = m_instanceName,
            libraryID          = m_libraryID,
            depth              = m_depth,
            clipDepth          = m_clipDepth,
            affineTransform    = m_affineTransform;

@end
