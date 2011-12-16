/*
    SwiffPlacedObject.m
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


#import "SwiffPlacedObject.h"

typedef struct _SwiffPlacedObjectAdditionalStorage
{
    NSString *name;
    SwiffColorTransform colorTransform;
    UInt16 clipDepth;
    UInt16 ratio;
    BOOL   hasColorTransform;
    BOOL   hidden;
} SwiffPlacedObjectAdditionalStorage;

#define ADDITIONAL ((SwiffPlacedObjectAdditionalStorage *)m_additional)
#define MAKE_ADDITIONAL { if (!m_additional) m_additional = calloc(sizeof(SwiffPlacedObjectAdditionalStorage), 1); }

@implementation SwiffPlacedObject


- (id) initWithDepth:(NSInteger)depth
{
    if ((self = [super init])) {
        m_affineTransform = CGAffineTransformIdentity;
        m_depth = depth;
    }

    return self;
}


- (id) initWithPlacedObject:(SwiffPlacedObject *)placedObject
{
    if ((self = [self initWithDepth:placedObject->m_depth])) {
        m_libraryID         = placedObject->m_libraryID;
        m_affineTransform   = placedObject->m_affineTransform;

        if (placedObject->m_additional) {
            m_additional = malloc(sizeof(SwiffPlacedObjectAdditionalStorage));

            SwiffPlacedObjectAdditionalStorage *other = placedObject->m_additional;

            ADDITIONAL->name              = [other->name copy];
            ADDITIONAL->clipDepth         =  other->clipDepth;
            ADDITIONAL->ratio             =  other->ratio;
            ADDITIONAL->hasColorTransform =  other->hasColorTransform;
            ADDITIONAL->hidden            =  other->hidden;

            if (other->hasColorTransform) {
                ADDITIONAL->colorTransform = other->colorTransform;
            }
        }
    }
    
    return self;
}


- (void) dealloc
{
    if (m_additional) {
        [ADDITIONAL->name release];

        free(m_additional);
        m_additional = NULL;
    }

    [super dealloc];
}

- (void) setupWithDefinition:(id<SwiffPlacableDefinition>)definition
{
    // ABSTRACT
}


#pragma mark -
#pragma mark Accessors

- (BOOL) hasAffineTransform
{
    return !CGAffineTransformIsIdentity(m_affineTransform);
}


- (CGAffineTransform *) affineTransformPointer
{
    return &m_affineTransform;
}


- (void) setHidden:(BOOL)hidden
{
    MAKE_ADDITIONAL;
    ADDITIONAL->hidden = hidden;
}


- (BOOL) isHidden
{
    return m_additional ? ADDITIONAL->hidden : NO;
}


- (void) setRatio:(CGFloat)ratio
{
    MAKE_ADDITIONAL;
    ADDITIONAL->ratio = round(ratio * 65535.0);
}


- (CGFloat) ratio
{
    return m_additional ? (ADDITIONAL->ratio / 65535.0) : 0;
}


- (void) setColorTransform:(SwiffColorTransform)colorTransform
{
    MAKE_ADDITIONAL;
    ADDITIONAL->colorTransform = colorTransform;
    ADDITIONAL->hasColorTransform = YES;
}


- (SwiffColorTransform) colorTransform
{
    if (m_additional && ADDITIONAL->hasColorTransform) {
        return ADDITIONAL->colorTransform;
    } else {
        return SwiffColorTransformIdentity;
    }
}


- (SwiffColorTransform *) colorTransformPointer
{
    if (m_additional && ADDITIONAL->hasColorTransform) {
        return &(ADDITIONAL->colorTransform);
    } else {
        return NULL;
    }
}


- (BOOL) hasColorTransform
{
    return m_additional && ADDITIONAL->hasColorTransform;
}


- (void) setName:(NSString *)name
{
    if (name != [self name]) {
        MAKE_ADDITIONAL;
        [ADDITIONAL->name release];
        ADDITIONAL->name = [name copy];
    }
}


- (NSString *) name
{
    return m_additional ? ADDITIONAL->name : nil;
}


- (void) setClipDepth:(UInt16)clipDepth
{
    if (clipDepth != [self clipDepth]) {
        MAKE_ADDITIONAL;
        ADDITIONAL->clipDepth = clipDepth;
    }
}


- (UInt16) clipDepth
{
    return m_additional ? ADDITIONAL->clipDepth : 0;
}


@synthesize libraryID        = m_libraryID,
            depth            = m_depth,
            clipDepth        = m_clipDepth,
            affineTransform  = m_affineTransform;

@end
