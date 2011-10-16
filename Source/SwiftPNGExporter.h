//
//  SwiftPNGExporter.h
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-13.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwiftPNGExporter : NSObject

+ (id) sharedInstance;

- (BOOL) exportFrame:(SwiftFrame *)frame ofMovie:(SwiftMovie *)movie toFile:(NSString *)path;
- (BOOL) exportFrame:(SwiftFrame *)frame ofMovie:(SwiftMovie *)movie toURL:(NSURL *)fileURL;

@end
