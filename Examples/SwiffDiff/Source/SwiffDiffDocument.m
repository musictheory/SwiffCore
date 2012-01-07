/*
    SwiffDiffDocument.m
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

#import "SwiffDiffDocument.h"

@interface SwiffDiffDocument ()
- (void) _updateFlashPlayer;
- (void) _updateControls;
- (void) _setCurrentFrame:(NSInteger)frame;
- (void) _setCurrentMode:(NSInteger)mode;
@end

static NSMutableArray *sInstances = nil;

static NSString * const sDocumentStateKey = @"SwiffDiffDocumentState";

static NSString * const sCurrentFrameKey          = @"CurrentFrame";
static NSString * const sCurrentModeKey           = @"CurrentMode";
static NSString * const sAntialiasKey             = @"Antialias";
static NSString * const sSmoothFontsKey           = @"SmoothFonts";
static NSString * const sSubpixelPositionFontsKey = @"SubpixelPositionFonts";
static NSString * const sSubpixelQuantizeFontsKey = @"SubpixelQuantizeFonts";
static NSString * const sHairlineWidthKey         = @"HairlineWidth";
static NSString * const sFillHairlineWidthKey     = @"FillHairlineWidth";


@implementation SwiffDiffDocument

+ (NSDictionary *) _allDocumentState
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:sDocumentStateKey];
}

+ (void) restoreDocuments
{
    for (NSString *urlString in [self _allDocumentState]) {
        NSURL *fileURL = [NSURL URLWithString:urlString];
        
        if (fileURL) {
            [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:fileURL display:YES completionHandler:NULL];
        }
    }
}


+ (void) saveState
{
    NSMutableDictionary *allState = [[NSMutableDictionary alloc] init];

    for (SwiffDiffDocument *document in sInstances) {
        NSString *key = [[document fileURL] absoluteString];
        
        NSMutableDictionary *state = [[NSMutableDictionary alloc] init]; 
        [document saveState:state];

        [allState setObject:state forKey:key];

        [state release];
    }

    [[NSUserDefaults standardUserDefaults] setObject:allState forKey:sDocumentStateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [allState release];
}


- (id) init
{
    if ((self = [super init])) {
        if (!sInstances) {
            sInstances = [[NSHashTable hashTableWithWeakObjects] retain];
        }
        
        [sInstances addObject:self];
    }
    
    return self;
}


- (void) dealloc
{
    [sInstances removeObject:self];

    [m_webView setFrameLoadDelegate:nil];
    [m_webView setResourceLoadDelegate:nil];
    [m_webView setUIDelegate:nil];

    [m_swiffView setDelegate:nil];

    [m_diffTimer invalidate];
    [m_diffTimer release];
    m_diffTimer = nil;

    [o_modeSelect setTarget:nil];
    [o_modeSelect setAction:NULL];

    [o_currentFrameField setTarget:nil];
    [o_currentFrameField setAction:NULL];

    [o_totalFrameField setTarget:nil];
    [o_totalFrameField setAction:NULL];

    [o_frameSlider setTarget:nil];
    [o_frameSlider setAction:NULL];

    [o_smoothFonts setTarget:nil];
    [o_smoothFonts setAction:NULL];

    [o_subpixelPositionFonts setTarget:nil];
    [o_subpixelPositionFonts setAction:NULL];

    [o_subpixelQuantizeFonts setTarget:nil];
    [o_subpixelQuantizeFonts setAction:NULL];

    [o_hairlineWidth setTarget:nil];
    [o_hairlineWidth setAction:NULL];

    [o_fillHairlineWidth setTarget:nil];
    [o_fillHairlineWidth setAction:NULL];

    o_modeSelect            = nil;
    o_currentFrameField     = nil;
    o_totalFrameField       = nil;
    o_frameSlider           = nil;
    o_containerView         = nil;
    o_smoothFonts           = nil;
    o_subpixelPositionFonts = nil;
    o_subpixelQuantizeFonts = nil;
    o_hairlineWidth         = nil;
    o_fillHairlineWidth     = nil;

    [o_optionsWindow release];
    o_optionsWindow = nil;

    [m_swiffView release]; m_swiffView = nil;
    [m_movie     release]; m_movie = nil;
    
    [super dealloc];
}


- (NSString *) windowNibName
{
    return @"Document";
}


- (void) windowControllerDidLoadNib:(NSWindowController *)aController
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitDeveloperExtras"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [super windowControllerDidLoadNib:aController];

    [[o_containerView window] setFrameAutosaveName:[[self fileURL] absoluteString]];
    [o_optionsWindow setFrameAutosaveName:[NSString stringWithFormat:@"_Options%@", [[self fileURL] absoluteString]]];

    m_swiffView = [[SwiffView alloc] initWithFrame:[o_containerView bounds] movie:m_movie];
    [m_swiffView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [m_swiffView setDrawsBackground:YES];
    [m_swiffView setDelegate:self];

    [o_containerView addSubview:m_swiffView];

    m_webView = [[WebView alloc] initWithFrame:[o_containerView bounds]];
    [m_webView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [m_webView setFrameLoadDelegate:self];
    [m_webView setResourceLoadDelegate:self];
    [m_webView setUIDelegate:self];

    [[m_webView preferences] setPlugInsEnabled:YES];
    [[m_webView preferences] setJavaScriptEnabled:YES];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"template" withExtension:@"html"];
    
    static NSInteger sCounter = 0;
    url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%d", [url absoluteString], sCounter++]];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [[m_webView mainFrame] loadRequest:request];
    [request release];
    
    [o_containerView addSubview:m_webView];

    NSInteger numberOfFrames = [[m_movie frames] count];
    [o_frameSlider setNumberOfTickMarks:numberOfFrames];
    [o_frameSlider setMinValue:1];
    [o_frameSlider setMaxValue:numberOfFrames];
    [o_totalFrameField setStringValue:[NSString stringWithFormat:@"/ %ld", (long)numberOfFrames]];

    NSDictionary *state = [[[self class] _allDocumentState] objectForKey:[[self fileURL] absoluteString]];
    [self loadState:state];

    [self _updateControls];
}


- (BOOL) readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    [m_movie release];
    m_movie = [[SwiffMovie alloc] initWithData:data];

    return YES;
}


- (void) saveState:(NSMutableDictionary *)state
{
    NSInteger frameIndex = [[[m_swiffView playhead] frame] indexInMovie];

    [state setObject:[NSNumber numberWithInteger:frameIndex] forKey:sCurrentFrameKey];
    [state setObject:[NSNumber numberWithInteger:[o_modeSelect selectedSegment]] forKey:sCurrentModeKey];

    [state setObject:[NSNumber numberWithInteger:[o_antialias state]]   forKey:sAntialiasKey];
    [state setObject:[NSNumber numberWithInteger:[o_smoothFonts state]] forKey:sSmoothFontsKey];
    [state setObject:[NSNumber numberWithInteger:[o_subpixelPositionFonts state]] forKey:sSubpixelPositionFontsKey];
    [state setObject:[NSNumber numberWithInteger:[o_subpixelQuantizeFonts state]] forKey:sSubpixelQuantizeFontsKey];

    [state setObject:[NSNumber numberWithDouble:[o_hairlineWidth     doubleValue]] forKey:sHairlineWidthKey];
    [state setObject:[NSNumber numberWithDouble:[o_fillHairlineWidth doubleValue]] forKey:sFillHairlineWidthKey];
    
}


- (void) loadState:(NSDictionary *)state
{ 
    double hairlineWidth     = [[state objectForKey:sHairlineWidthKey] doubleValue];
    double fillHairlineWidth = [[state objectForKey:sFillHairlineWidthKey] doubleValue]; 

    if (hairlineWidth == 0) hairlineWidth = 1.0;
    [o_hairlineWidth setDoubleValue:hairlineWidth];
    [o_fillHairlineWidth setDoubleValue:fillHairlineWidth];
    
    NSNumber *antialiasNumber = [state objectForKey:sAntialiasKey];
    BOOL antialias = antialiasNumber ? [antialiasNumber boolValue] : YES;

    [o_antialias             setState: antialias];
    [o_smoothFonts           setState: [[state objectForKey:sSmoothFontsKey] boolValue]];
    [o_subpixelPositionFonts setState: [[state objectForKey:sSubpixelPositionFontsKey] boolValue]];
    [o_subpixelQuantizeFonts setState: [[state objectForKey:sSubpixelQuantizeFontsKey] boolValue]];

    NSNumber *currentFrame = [state objectForKey:sCurrentFrameKey];
    if (currentFrame) {
        [self _setCurrentFrame:[currentFrame integerValue]];
    }

    NSNumber *currentMode = [state objectForKey:sCurrentModeKey];
    if (currentMode) {
        [self _setCurrentMode:[currentMode integerValue]];
    }

    [self changeOptions:nil];
}


#pragma mark -
#pragma mark Private Methods

- (void) _updateFlashPlayer
{
    NSInteger  frameIndex1 = [[[m_swiffView playhead] frame] index1InMovie];
    NSArray   *arguments   = [NSArray arrayWithObject:[NSNumber numberWithInteger:frameIndex1]];
    
    [[m_webView windowScriptObject] callWebScriptMethod:@"GotoFrame" withArguments:arguments];
}


- (void) _updateControls
{
    NSInteger  frameIndex1 = [[[m_swiffView playhead] frame] index1InMovie];
    [o_currentFrameField setStringValue:[NSString stringWithFormat:@"%ld", frameIndex1]];
    [o_frameSlider setIntegerValue:frameIndex1];
}


- (void) _setCurrentFrame:(NSInteger)frame
{
    [[m_swiffView playhead] gotoFrameWithIndex:frame play:NO];

    [self _updateControls];
    [self _updateFlashPlayer];
}


- (void) _handleDiffTick:(NSTimer *)timer
{
    BOOL isHidden = [m_swiffView isHidden];
    
    [m_swiffView setHidden:!isHidden];
    [m_webView   setHidden:isHidden];
}


- (void) _setCurrentMode:(NSInteger)mode
{
    NSDisableScreenUpdates();

    [m_diffTimer invalidate];
    [m_diffTimer release];
    m_diffTimer = nil;

    if ((mode == 0) || (mode == 1)) {
        [m_swiffView setHidden:(mode != 0)];
        [m_webView   setHidden:(mode == 0)];
   
    } else if (mode == 2) {
        m_diffTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_handleDiffTick:) userInfo:nil repeats:YES] retain];
        [self _handleDiffTick:m_diffTimer];
    }
    
    [[o_containerView window] display];
    [o_modeSelect setSelectedSegment:mode];

    NSEnableScreenUpdates();
}


- (void) _setZoomLevel:(CGFloat)level
{
    NSRect windowFrame    = [[o_containerView window] frame];
    NSRect containerFrame = [o_containerView frame];

    CGSize sizeDiff = CGSizeMake(
        windowFrame.size.width  - containerFrame.size.width,
        windowFrame.size.height - containerFrame.size.height
    );
    
    CGSize sizeToUse = [m_movie stageRect].size;
    sizeToUse.width  *= level;
    sizeToUse.height *= level;
    
    windowFrame.size = NSMakeSize(sizeToUse.width + sizeDiff.width, sizeToUse.height + sizeDiff.height);

    [[o_containerView window] setFrame:windowFrame display:YES animate:YES];

    [SwiffDiffDocument saveState];
}


- (CGFloat) _zoomLevel
{
    NSRect containerFrame = [o_containerView frame];
    CGSize movieSize      = [m_movie stageRect].size;

    CGFloat widthRatio  = containerFrame.size.width / movieSize.width;
    CGFloat heightRatio = containerFrame.size.width / movieSize.width;

    CGFloat ratio = (widthRatio < heightRatio) ? widthRatio : heightRatio;
    return SwiffRound(ratio * 2) / 2;
}


#pragma mark -
#pragma mark IBActions

- (IBAction) changeMode:(id)sender
{
    if ([sender respondsToSelector:@selector(selectedSegment)]) {
        [self _setCurrentMode:[sender selectedSegment]];
    } else {
        [self _setCurrentMode:[sender tag]];
    }

    [SwiffDiffDocument saveState];
}


- (IBAction) changeOptions:(id)sender
{
    [m_swiffView setShouldAntialias:[o_antialias state]];
    [m_swiffView setShouldSmoothFonts:[o_smoothFonts state]];
    [m_swiffView setShouldSubpixelPositionFonts:[o_subpixelPositionFonts state]];
    [m_swiffView setShouldSubpixelQuantizeFonts:[o_subpixelQuantizeFonts state]];
    [m_swiffView setHairlineWidth:[o_hairlineWidth doubleValue]];
    [m_swiffView setFillHairlineWidth:[o_fillHairlineWidth doubleValue]];

    [SwiffDiffDocument saveState];
}


- (IBAction) viewActualSize:(id)sender
{
    [self _setZoomLevel:1.0];
}


- (IBAction) viewZoomIn:(id)sender
{
    [self _setZoomLevel:[self _zoomLevel] + 0.5];
}


- (IBAction) viewZoomOut:(id)sender
{
    CGFloat zoomLevel = [self _zoomLevel];
    zoomLevel -= 0.5;

    if (zoomLevel < 0.5) {
        zoomLevel = 0.5;
    }

    [self _setZoomLevel:zoomLevel];
}


- (IBAction) toggleWantsLayer:(id)sender
{
    BOOL yn = ([o_wantsLayer state] == NSOnState);

    if (sender != o_wantsLayer) {
        yn = !yn;
        [o_wantsLayer setState:yn];
    }

    for (SwiffFrame *frame in [m_movie frames]) {
        for (SwiffPlacedObject *po in [frame placedObjects]) {
            [po setWantsLayer:yn];
        }
    }

    [m_swiffView redisplay];

    [SwiffDiffDocument saveState];
}

     
- (IBAction) changeCurrentFrame:(id)sender
{
    NSInteger frameIndex1 = [sender integerValue];

    if (frameIndex1 > 0) {
        [self _setCurrentFrame:(frameIndex1 - 1)];
    }

    [SwiffDiffDocument saveState];
}


- (IBAction) showOptions:(id)sender
{
    [o_optionsWindow makeKeyAndOrderFront:self];
}


- (IBAction) nextFrame:(id)sender
{
    NSInteger frameIndex0 = [[[m_swiffView playhead] frame] indexInMovie];
    NSInteger count = [[m_movie frames] count];

    if (frameIndex0 < (count - 1)) {
        [self _setCurrentFrame:(frameIndex0 + 1)];
    }
}


- (IBAction) previousFrame:(id)sender
{
    NSInteger frameIndex0 = [[[m_swiffView playhead] frame] indexInMovie];
    if (frameIndex0 > 0) {
        [self _setCurrentFrame:(frameIndex0 - 1)];
    }
}


#pragma mark -
#pragma mark Delegate Methods

- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    NSArray *arguments = [[NSArray alloc] initWithObjects:[self fileURL], nil];

    [self _updateFlashPlayer];

    WebScriptObject *wso = [m_webView windowScriptObject];
    [wso callWebScriptMethod:@"SetURL" withArguments:arguments];
    
    [arguments release];
}


- (void) webView: (WebView*)webView addMessageToConsole: (NSDictionary*)dictionary
{
    NSString *message   = [dictionary objectForKey:@"message"];
    NSString *sourceURL = [dictionary objectForKey:@"sourceURL"];
    NSInteger line     = [[dictionary objectForKey:@"lineNumber"] integerValue];
    
    NSString *filename = [[NSURL URLWithString:sourceURL] lastPathComponent];

    NSLog(@"%@:%ld %@", filename, (long)line, message); 
}


- (BOOL) swiffView:(SwiffView *)swiffView shouldInterpolateFromFrame:(SwiffFrame *)fromFrame toFrame:(SwiffFrame *)toFrame
{
    return ([o_wantsLayer state] == NSOnState);
}


#pragma mark -
#pragma mark Accessors

@synthesize modeSelect        = o_modeSelect,
            currentFrameField = o_currentFrameField,
            totalFrameField   = o_totalFrameField,
            frameSlider       = o_frameSlider,
            containerView     = o_containerView,
            wantsLayerButton  = o_wantsLayer;

@synthesize optionsWindow         = o_optionsWindow,
            antialias             = o_antialias,
            smoothFonts           = o_smoothFonts,
            subpixelPositionFonts = o_subpixelPositionFonts,
            subpixelQuantizeFonts = o_subpixelQuantizeFonts,
            hairlineWidth         = o_hairlineWidth,
            fillHairlineWidth     = o_fillHairlineWidth;

@end
