/*
    SwiffPath.m
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


#import "SwiffPath.h"


static const NSUInteger sGrowthForOperations = 64;
static const NSUInteger sGrowthForPoints     = 128;


@implementation SwiffPath

void SwiffPathAddOperation(SwiffPath *path, SwiffPathOperation operation, const CGPoint *toPoint, const CGPoint *controlPoint)
{
    if ((path->m_operationsCount % sGrowthForOperations) == 0) {
        NSUInteger capacity = (path->m_operationsCount + sGrowthForOperations);
        path->m_operations = realloc(path->m_operations, sizeof(UInt8) * capacity);
    }

    if ((path->m_pointsCount % sGrowthForPoints) == 0) {
        NSUInteger capacity = (path->m_pointsCount + sGrowthForPoints);
        path->m_points = realloc(path->m_points, sizeof(CGPoint) * capacity);
    }

    path->m_operations[path->m_operationsCount++] = operation;
    
    if (operation == SwiffPathOperationCurve) {
        path->m_points[path->m_pointsCount++] = *toPoint;
        path->m_points[path->m_pointsCount++] = *controlPoint;

    } else if (operation == SwiffPathOperationEnd) {
        path->m_points[path->m_pointsCount++] = CGPointZero;

    } else {
        path->m_points[path->m_pointsCount++] = *toPoint;
    }
}


- (id) initWithLineStyle:(SwiffLineStyle *)lineStyle fillStyle:(SwiffFillStyle *)fillStyle
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

    if (m_points) {
        free(m_points);
        m_points = NULL;
    }

    [m_fillStyle  release];  m_fillStyle  = nil;
    [m_lineStyle  release];  m_lineStyle  = nil;
    
    [super dealloc];
}


@synthesize operations      = m_operations,
            points          = m_points,
            operationsCount = m_operationsCount,
            pointsCount     = m_pointsCount,
            fillStyle       = m_fillStyle,
            lineStyle       = m_lineStyle;

@end
