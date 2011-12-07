//
//  AppDelegate.h
//  SwiftCoreCompare
//
//  Created by Ricci Adams on 2011-12-01.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface SwiftDiffDocument : NSDocument <NSApplicationDelegate> {
@private
    NSSegmentedControl *o_modeSelect;
    NSTextField        *o_currentFrameField;
    NSTextField        *o_totalFrameField;
    NSSlider           *o_frameSlider;
    NSView             *o_containerView;

    NSTimer            *m_diffTimer;
    SwiftMovie         *m_movie;
    SwiftMovieView     *m_movieView;
    WebView            *m_webView;
    
}

+ (void) restoreDocuments;
+ (void) saveState;

- (void) saveState:(NSMutableDictionary *)state;
- (void) loadState:(NSDictionary *)state;

- (IBAction) changeMode:(id)sender;
- (IBAction) changeCurrentFrame:(id)sender;
- (IBAction) viewActualSize:(id)sender;

@property (retain) IBOutlet NSSegmentedControl *modeSelect;
@property (retain) IBOutlet NSTextField *currentFrameField;
@property (retain) IBOutlet NSTextField *totalFrameField;
@property (retain) IBOutlet NSSlider *frameSlider;
@property (retain) IBOutlet NSView *containerView;

@end
