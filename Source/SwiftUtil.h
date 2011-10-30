/*
    SwiftUtil.h
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

extern void _SwiftLog(NSInteger level, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);
extern void _SwiftWarnFrozen(id self, const char * const prettyFunction);
extern BOOL _SwiftShouldLog;

extern void SwiftEnableLogging(void);
#define SwiftShouldLog() _SwiftShouldLog
#define SwiftLog( ...) { if (_SwiftShouldLog) _SwiftLog(6, __VA_ARGS__); }
#define SwiftWarn(...) { _SwiftLog(4, __VA_ARGS__); }

#define SwiftFloatFromTwips(TWIPS) ((TWIPS) / 20.0)

#define SwiftFrozenImplementation { _SwiftWarnFrozen(self, __PRETTY_FUNCTION__); }

extern CGColorRef SwiftColorCopyCGColor(SwiftColor color) CF_RETURNS_RETAINED;

extern SwiftColor SwiftColorApplyColorTransform(SwiftColor color, SwiftColorTransform transform);

extern NSString *SwiftStringFromColor(SwiftColor color);


// CFArrayRef values must be valid (SwiftColorTransform *).  If stack is NULL, color is returned
extern SwiftColor SwiftColorApplyColorTransformStack(SwiftColor color, CFArrayRef stack);

extern NSString *SwiftStringFromColorTransform(SwiftColorTransform transform);
extern NSString *SwiftStringFromColorTransformStack(CFArrayRef stack);
