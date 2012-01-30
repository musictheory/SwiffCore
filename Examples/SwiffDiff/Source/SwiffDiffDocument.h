/*
    SwiffDiffDocument.h
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

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface SwiffDiffDocument : NSDocument <NSApplicationDelegate, SwiffViewDelegate> {
@private
    NSSegmentedControl *__weak o_modeSelect;
    NSTextField        *__weak o_currentFrameField;
    NSTextField        *__weak o_totalFrameField;
    NSSlider           *__weak o_frameSlider;
    NSView             *__weak o_containerView;
    NSButton           *__weak o_wantsLayer;

    NSWindow           *o_optionsWindow;
    NSButton           *__weak o_antialias;
    NSButton           *__weak o_smoothFonts;
    NSButton           *__weak o_subpixelPositionFonts;
    NSButton           *__weak o_subpixelQuantizeFonts;
    NSTextField        *__weak o_hairlineWidth;
    NSTextField        *__weak o_fillHairlineWidth;
    
    NSTimer            *m_diffTimer;
    SwiffMovie         *m_movie;
    SwiffView          *m_swiffView;
    WebView            *m_webView;
    
}

+ (void) restoreDocuments;
+ (void) saveState;

- (void) saveState:(NSMutableDictionary *)state;
- (void) loadState:(NSDictionary *)state;

- (IBAction) changeMode:(id)sender;
- (IBAction) changeOptions:(id)sender;
- (IBAction) changeCurrentFrame:(id)sender;
- (IBAction) toggleWantsLayer:(id)sender;

- (IBAction) nextFrame:(id)sender;
- (IBAction) previousFrame:(id)sender;

- (IBAction) viewActualSize:(id)sender;
- (IBAction) viewZoomIn:(id)sender;
- (IBAction) viewZoomOut:(id)sender;
- (IBAction) showOptions:(id)sender;

@property (weak)   IBOutlet NSSegmentedControl *modeSelect;
@property (weak)   IBOutlet NSTextField *currentFrameField;
@property (weak)   IBOutlet NSTextField *totalFrameField;
@property (weak)   IBOutlet NSSlider *frameSlider;
@property (weak)   IBOutlet NSView *containerView;
@property (weak)   IBOutlet NSButton *wantsLayerButton;

@property (strong) IBOutlet NSWindow    *optionsWindow;
@property (weak)   IBOutlet NSButton    *antialias;
@property (weak)   IBOutlet NSButton    *smoothFonts;
@property (weak)   IBOutlet NSButton    *subpixelPositionFonts;
@property (weak)   IBOutlet NSButton    *subpixelQuantizeFonts;
@property (weak)   IBOutlet NSTextField *hairlineWidth;
@property (weak)   IBOutlet NSTextField *fillHairlineWidth;

@end
