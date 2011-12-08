/*
    SwiftDiffDocument.m
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

#import "SwiftDiffDocument.h"

@interface SwiftDiffDocument ()
- (void) _updateFlashPlayer;
- (void) _updateControls;
- (void) _setCurrentFrame:(NSInteger)frame;
- (void) _setCurrentMode:(NSInteger)mode;
@end

static NSMutableArray *sInstances = nil;

static NSString * const sDocumentStateKey = @"SwiftDiffDocumentState";

static NSString * const sCurrentFrameKey = @"CurrentFrame";
static NSString * const sCurrentModeKey  = @"CurrentMode";


@implementation SwiftDiffDocument

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

    for (SwiftDiffDocument *document in sInstances) {
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
    
    [o_modeSelect        release];  o_modeSelect        = nil;
    [o_currentFrameField release];  o_currentFrameField = nil;
    [o_totalFrameField   release];  o_totalFrameField   = nil;
    [o_frameSlider       release];  o_frameSlider       = nil;
    [o_containerView     release];  o_containerView     = nil;


    [m_movieView release]; m_movieView = nil;
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

    m_movieView = [[SwiftMovieView alloc] initWithFrame:[o_containerView bounds]];
    [m_movieView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [m_movieView setDrawsBackground:YES];

    [o_containerView addSubview:m_movieView];

    m_webView = [[WebView alloc] initWithFrame:[o_containerView bounds]];
    [m_webView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [m_webView setFrameLoadDelegate:self];
    [m_webView setResourceLoadDelegate:self];

    [[m_webView preferences] setPlugInsEnabled:YES];
    [[m_webView preferences] setJavaScriptEnabled:YES];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"template" withExtension:@"html"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [[m_webView mainFrame] loadRequest:request];
    [request release];
    
    [o_containerView addSubview:m_webView];

    NSInteger numberOfFrames = [[m_movie frames] count];
    [o_frameSlider setNumberOfTickMarks:numberOfFrames];
    [o_frameSlider setMinValue:1];
    [o_frameSlider setMaxValue:numberOfFrames];
    [o_totalFrameField setStringValue:[NSString stringWithFormat:@"/ %ld", (long)numberOfFrames]];

    [m_movieView setMovie:m_movie];

    NSDictionary *state = [[[self class] _allDocumentState] objectForKey:[[self fileURL] absoluteString]];
    [self loadState:state];

    [self _updateControls];
}


- (BOOL) readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    [m_movie release];
    m_movie = [[SwiftMovie alloc] initWithData:data];

    return YES;
}


- (void) saveState:(NSMutableDictionary *)state
{
    NSInteger frameIndex = [[[m_movieView playhead] frame] indexInMovie];

    [state setObject:[NSNumber numberWithInteger:frameIndex] forKey:sCurrentFrameKey];
    [state setObject:[NSNumber numberWithInteger:[o_modeSelect selectedSegment]] forKey:sCurrentModeKey];
}


- (void) loadState:(NSDictionary *)state
{
    NSNumber *currentFrame = [state objectForKey:sCurrentFrameKey];
    if (currentFrame) {
        [self _setCurrentFrame:[currentFrame integerValue]];
    }

    NSNumber *currentMode = [state objectForKey:sCurrentModeKey];
    if (currentMode) {
        [self _setCurrentMode:[currentMode integerValue]];
    }
}


#pragma mark -
#pragma mark Private Methods

- (void) _updateFlashPlayer
{
    NSInteger  frameIndex1 = [[[m_movieView playhead] frame] index1InMovie];
    NSArray   *arguments   = [NSArray arrayWithObject:[NSNumber numberWithInteger:frameIndex1]];
    
    [[m_webView windowScriptObject] callWebScriptMethod:@"GotoFrame" withArguments:arguments];
}


- (void) _updateControls
{
    NSInteger  frameIndex1 = [[[m_movieView playhead] frame] index1InMovie];
    [o_currentFrameField setStringValue:[NSString stringWithFormat:@"%ld", frameIndex1]];
    [o_frameSlider setIntegerValue:frameIndex1];
}


- (void) _setCurrentFrame:(NSInteger)frame
{
    [[m_movieView playhead] gotoFrameWithIndex:frame play:NO];

    [self _updateControls];
    [self _updateFlashPlayer];
}


- (void) _handleDiffTick:(NSTimer *)timer
{
    BOOL isHidden = [m_movieView isHidden];
    
    [m_movieView setHidden:!isHidden];
    [m_webView   setHidden:isHidden];
}


- (void) _setCurrentMode:(NSInteger)mode
{
    NSDisableScreenUpdates();

    [m_diffTimer invalidate];
    [m_diffTimer release];
    m_diffTimer = nil;

    if ((mode == 0) || (mode == 1)) {
        [m_movieView setHidden:(mode != 0)];
        [m_webView   setHidden:(mode == 0)];
   
    } else if (mode == 2) {
        m_diffTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_handleDiffTick:) userInfo:nil repeats:YES] retain];
        [self _handleDiffTick:m_diffTimer];
    }
    
    [[o_containerView window] display];
    [o_modeSelect setSelectedSegment:mode];

    NSEnableScreenUpdates();
}


#pragma mark -
#pragma mark IBActions

- (IBAction) changeMode:(id)sender
{
    [self _setCurrentMode:[sender selectedSegment]];
}


- (IBAction) viewActualSize:(id)sender
{
    CGSize stageSize = [m_movie stageRect].size;
    
    NSRect windowFrame    = [[o_containerView window] frame];
    NSRect containerFrame = [o_containerView frame];

    CGSize sizeDiff = CGSizeMake(
        windowFrame.size.width  - containerFrame.size.width,
        windowFrame.size.height - containerFrame.size.height
    );
    
    windowFrame.size = CGSizeMake(stageSize.width + sizeDiff.width, stageSize.height + sizeDiff.height);

    [[o_containerView window] setFrame:windowFrame display:YES animate:YES];
}

     
- (IBAction) changeCurrentFrame:(id)sender
{
    NSInteger frameIndex1 = [sender integerValue];

    if (frameIndex1 > 0) {
        [self _setCurrentFrame:(frameIndex1 - 1)];
    }
}


#pragma mark -
#pragma mark Delegate Methods

- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    NSArray *arguments = [[NSArray alloc] initWithObjects:[self fileURL], nil];

    [self _updateFlashPlayer];

    WebScriptObject *wso = [m_webView windowScriptObject];
    [wso callWebScriptMethod:@"DoLoad" withArguments:arguments];

    [arguments release];
}


#pragma mark -
#pragma mark Accessors

@synthesize modeSelect        = o_modeSelect,
            currentFrameField = o_currentFrameField,
            totalFrameField   = o_totalFrameField,
            frameSlider       = o_frameSlider,
            containerView     = o_containerView;

@end
