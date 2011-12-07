//
//  SwiftDiffAppDelegate.m
//  SwiftDiff
//
//  Created by Ricci Adams on 2011-12-02.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SwiftDiffAppDelegate.h"
#import "SwiftDiffDocument.h"

@implementation SwiftDiffAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    [SwiftDiffDocument restoreDocuments];
}

- (void) applicationWillTerminate:(NSNotification *)notification
{
    [SwiftDiffDocument saveState];
}

@end
