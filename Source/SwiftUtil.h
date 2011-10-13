//
//  SwiftUtil.h
//  SwiftKick
//
//  Created by Ricci Adams on 2011-10-09.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

extern void _SwiftLog(NSInteger level, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);
extern BOOL _SwiftShouldLog;

extern void SwiftEnableLogging(void);
#define SwiftShouldLog() _SwiftShouldLog
#define SwiftLog( ...) { if (_SwiftShouldLog) _SwiftLog(6, __VA_ARGS__); }
#define SwiftWarn(...) { _SwiftLog(4, __VA_ARGS__); }

extern SwiftColor SwiftColorApplyColorTransform(SwiftColor color, SwiftColorTransform transform);