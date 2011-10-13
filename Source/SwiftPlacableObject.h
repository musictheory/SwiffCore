//
//  SwiftPlacableObject.h
//  SwiftCore
//
//  Created by Ricci Adams on 2011-10-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

@protocol SwiftPlacableObject <NSObject>
@property (nonatomic, assign, readonly) NSInteger libraryID;
@property (nonatomic, assign, readonly) CGRect bounds;
@property (nonatomic, assign, readonly) CGRect edgeBounds;
@property (nonatomic, assign, readonly) BOOL hasEdgeBounds;
@end