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
static const NSUInteger sGrowthForFloats     = 256;


@implementation SwiffPath

static void SwiffPathAddFloat(SwiffPath *path, const CGFloat value)
{
    if ((path->m_floatsCount % sGrowthForFloats) == 0) {
        NSUInteger capacity = (path->m_floatsCount + sGrowthForFloats);
        path->m_floats = realloc(path->m_floats, sizeof(CGFloat) * capacity);
    }

    path->m_floats[path->m_floatsCount++] = value;
}


void SwiffPathAddOperation(SwiffPath *path, SwiffPathOperation operation, ...)
{
    if ((path->m_operationsCount % sGrowthForOperations) == 0) {
        NSUInteger capacity = (path->m_operationsCount + sGrowthForOperations);
        path->m_operations = realloc(path->m_operations, sizeof(UInt8) * capacity);
    }

    va_list v;
    va_start(v, operation);

    path->m_operations[path->m_operationsCount++] = operation;
    
    if (operation == SwiffPathOperationCurve) {
        SwiffPathAddFloat(path, va_arg(v, CGFloat));
        SwiffPathAddFloat(path, va_arg(v, CGFloat));
        SwiffPathAddFloat(path, va_arg(v, CGFloat));
        SwiffPathAddFloat(path, va_arg(v, CGFloat));

    } else if (operation == SwiffPathOperationMove || operation == SwiffPathOperationLine) {
        SwiffPathAddFloat(path, va_arg(v, CGFloat));
        SwiffPathAddFloat(path, va_arg(v, CGFloat));
    
    } else if (operation == SwiffPathOperationHorizontalLine || operation == SwiffPathOperationVerticalLine) {
        SwiffPathAddFloat(path, va_arg(v, CGFloat));
    }
    
    va_end(v);
}


- (id) initWithLineStyle:(SwiffLineStyle *)lineStyle fillStyle:(SwiffFillStyle *)fillStyle
{
    if ((self = [super init])) {
        m_fillStyle = [fillStyle  retain];
        m_lineStyle = [lineStyle  retain];
    }
    
    return self;
}


- (void) dealloc
{
    if (m_operations) {
        free(m_operations);
        m_operations = NULL;
    }

    if (m_floats) {
        free(m_floats);
        m_floats = NULL;
    }

    [m_fillStyle  release];  m_fillStyle  = nil;
    [m_lineStyle  release];  m_lineStyle  = nil;
    
    [super dealloc];
}


@synthesize operations      = m_operations,
            floats          = m_floats,
            operationsCount = m_operationsCount,
            pointsCount     = m_pointsCount,
            fillStyle       = m_fillStyle,
            lineStyle       = m_lineStyle,
            useHairlineWithFillWidth = m_useHairlineWithFillWidth;

@end
