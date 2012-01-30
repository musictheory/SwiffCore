/*
    SwiffPath.m
    Copyright (c) 2011-2012, musictheory.net, LLC.  All rights reserved.

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
#import "SwiffUtils.h"
#import "SwiffFillStyle.h"
#import "SwiffLineStyle.h"

static const NSUInteger sGrowthForOperations = 64;
static const NSUInteger sGrowthForFloats     = 256;


@implementation SwiffPath

static void SwiffPathAddTwipsToFloats(SwiffPath *path, const SwiffTwips twips)
{
    if ((path->m_floatsCount % sGrowthForFloats) == 0) {
        NSUInteger capacity = (path->m_floatsCount + sGrowthForFloats);
        path->m_floats = realloc(path->m_floats, sizeof(CGFloat) * capacity);
    }

    path->m_floats[path->m_floatsCount++] = SwiffGetCGFloatFromTwips(twips);
}


void SwiffPathAddOperationAndTwips(SwiffPath *path, SwiffPathOperation operation, ...)
{
    if ((path->m_operationsCount % sGrowthForOperations) == 0) {
        NSUInteger capacity = (path->m_operationsCount + sGrowthForOperations);
        path->m_operations = realloc(path->m_operations, sizeof(UInt8) * capacity);
    }

    va_list v;
    va_start(v, operation);

    path->m_operations[path->m_operationsCount++] = operation;
    
    if (operation == SwiffPathOperationCurve) {
        SwiffPathAddTwipsToFloats(path, va_arg(v, SwiffTwips));
        SwiffPathAddTwipsToFloats(path, va_arg(v, SwiffTwips));
        SwiffPathAddTwipsToFloats(path, va_arg(v, SwiffTwips));
        SwiffPathAddTwipsToFloats(path, va_arg(v, SwiffTwips));

    } else if (operation == SwiffPathOperationMove || operation == SwiffPathOperationLine) {
        SwiffPathAddTwipsToFloats(path, va_arg(v, SwiffTwips));
        SwiffPathAddTwipsToFloats(path, va_arg(v, SwiffTwips));
    
    } else if (operation == SwiffPathOperationHorizontalLine || operation == SwiffPathOperationVerticalLine) {
        SwiffPathAddTwipsToFloats(path, va_arg(v, SwiffTwips));
    }
    
    va_end(v);
}


void SwiffPathAddOperationEnd(SwiffPath *path)
{
    SwiffPathAddOperationAndTwips(path, SwiffPathOperationEnd);
    SwiffPathAddOperationAndTwips(path, SwiffPathOperationEnd);
}


- (id) initWithLineStyle:(SwiffLineStyle *)lineStyle fillStyle:(SwiffFillStyle *)fillStyle
{
    if ((self = [super init])) {
        m_fillStyle = fillStyle;
        m_lineStyle = lineStyle;
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
}


@synthesize operations            = m_operations,
            floats                = m_floats,
            operationsCount       = m_operationsCount,
            floatsCount           = m_floatsCount,
            fillStyle             = m_fillStyle,
            lineStyle             = m_lineStyle,
            usesFillHairlineWidth = m_usesFillHairlineWidth;

@end
