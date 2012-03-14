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

@synthesize operations            = _operations,
            floats                = _floats,
            operationsCount       = _operationsCount,
            floatsCount           = _floatsCount,
            fillStyle             = _fillStyle,
            lineStyle             = _lineStyle,
            usesFillHairlineWidth = _usesFillHairlineWidth;


static void SwiffPathAddTwipsToFloats(SwiffPath *path, const SwiffTwips twips)
{
    if ((path->_floatsCount % sGrowthForFloats) == 0) {
        NSUInteger capacity = (path->_floatsCount + sGrowthForFloats);
        path->_floats = realloc(path->_floats, sizeof(CGFloat) * capacity);
    }

    path->_floats[path->_floatsCount++] = SwiffGetCGFloatFromTwips(twips);
}


void SwiffPathAddOperationAndTwips(SwiffPath *path, SwiffPathOperation operation, ...)
{
    if ((path->_operationsCount % sGrowthForOperations) == 0) {
        NSUInteger capacity = (path->_operationsCount + sGrowthForOperations);
        path->_operations = realloc(path->_operations, sizeof(UInt8) * capacity);
    }

    va_list v;
    va_start(v, operation);

    path->_operations[path->_operationsCount++] = operation;
    
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
        _fillStyle = fillStyle;
        _lineStyle = lineStyle;
    }
    
    return self;
}


- (void) dealloc
{
    if (_operations) {
        free(_operations);
        _operations = NULL;
    }

    if (_floats) {
        free(_floats);
        _floats = NULL;
    }
}

@end
