/*
    SwiftPath.m
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


#import "SwiftPath.h"


const CGFloat SwiftPathOperationMove  = 0.0;
const CGFloat SwiftPathOperationLine  = 1.0;
const CGFloat SwiftPathOperationCurve = 2.0;
const CGFloat SwiftPathOperationEnd   = 3.0;

extern void SwiftPathAddOperation(SwiftPath *path, CGFloat type, CGPoint *toPoint, CGPoint *controlPoint);


@implementation SwiftPath

void SwiftPathAddOperation(SwiftPath *path, CGFloat type, CGPoint *toPoint, CGPoint *controlPoint)
{
    NSUInteger spaceNeeded = (type == SwiftPathOperationCurve) ? 5 : 3;
    NSUInteger newCount    = path->m_operationsCount + spaceNeeded;

    if (newCount >= path->m_operationsCapacity) {
        path->m_operationsCapacity *= 2;
        if (!path->m_operationsCapacity) path->m_operationsCapacity = 64;
        path->m_operations = realloc(path->m_operations, sizeof(CGFloat) * path->m_operationsCapacity);
    }
    
    path->m_operations[path->m_operationsCount + 0] = type;
    path->m_operations[path->m_operationsCount + 1] = toPoint->x;
    path->m_operations[path->m_operationsCount + 2] = toPoint->y;

    if (type == SwiftPathOperationCurve) {
        path->m_operations[path->m_operationsCount + 3] = controlPoint->x;
        path->m_operations[path->m_operationsCount + 4] = controlPoint->y;
    }
    
    path->m_operationsCount += spaceNeeded;
}


- (id) initWithLineStyle:(SwiftLineStyle *)lineStyle fillStyle:(SwiftFillStyle *)fillStyle
{
    if ((self = [super init])) {
        m_fillStyle  = [fillStyle  retain];
        m_lineStyle  = [lineStyle  retain];
    }
    
    return self;
}


- (void) dealloc
{
    if (m_operations) {
        free(m_operations);
        m_operations = NULL;
    }

    [m_fillStyle  release];  m_fillStyle  = nil;
    [m_lineStyle  release];  m_lineStyle  = nil;
    
    [super dealloc];
}


@synthesize operations      = m_operations,
            fillStyle       = m_fillStyle,
            lineStyle       = m_lineStyle;

@end
