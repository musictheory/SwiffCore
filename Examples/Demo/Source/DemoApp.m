/*
    DemoApp.m
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

#import "DemoApp.h"
#import "DemoMovieController.h"

static NSString *sCurrentMovieKey = @"CurrentMovie";

@interface DemoTableViewController ()
- (void) _pushMovieWithURLString:(NSString *)inURLString animated:(BOOL)animated;
@end


@implementation DemoTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    if ((self = [super initWithStyle:style])) {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"DemoMovies" ofType:@"plist"];
        NSData   *plistData =  [NSData dataWithContentsOfFile:plistPath];
        
        NSError *error = nil;
        m_moviesPlist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:NULL error:&error];

        [self setTitle:@"Movies"];
    }
    
    return self;
}


#pragma mark -
#pragma mark Superclass Overrides

- (void) viewDidAppear:(BOOL)animated
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:sCurrentMovieKey];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}


#pragma mark -
#pragma mark Private Methods

- (NSArray *) _movieDictionaries
{
    return [m_moviesPlist objectForKey:@"movies"];
}


- (void) _pushMovieWithURLString:(NSString *)inURLString animated:(BOOL)animated
{
    NSArray *movieDictionaries = [self _movieDictionaries];

    for (NSDictionary *dictionary in movieDictionaries) {
        NSString *urlString = [dictionary objectForKey:@"url"];

        if ([urlString isEqualToString:inURLString]) {
            NSURL    *url   = [NSURL URLWithString:urlString];
            NSString *title = [dictionary objectForKey:@"name"];

            DemoMovieController *vc = [[DemoMovieController alloc] initWithURL:url];
            [vc setTitle:title];
            
            [[self navigationController] pushViewController:vc animated:animated];

            [[NSUserDefaults standardUserDefaults] setObject:urlString forKey:sCurrentMovieKey];
            [[NSUserDefaults standardUserDefaults] synchronize];

            break;
        }
    }
}


#pragma mark -
#pragma mark UITableview Delegate Methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self _movieDictionaries] count];
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dictionary = [[self _movieDictionaries] objectAtIndex:[indexPath row]];

    NSString *urlString = [dictionary objectForKey:@"url"];
    [[NSUserDefaults standardUserDefaults] setObject:urlString forKey:sCurrentMovieKey];
    [self _pushMovieWithURLString:urlString animated:YES];
}


- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }

    NSDictionary *dictionary = [[self _movieDictionaries] objectAtIndex:[indexPath row]];

    [[cell textLabel] setText:[dictionary objectForKey:@"name"]];
    [[cell detailTextLabel] setText:[dictionary objectForKey:@"author"]];

    return cell;
}


@end




@implementation DemoAppDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    m_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    DemoTableViewController *vc = [[DemoTableViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController  *nc = [[UINavigationController  alloc] initWithRootViewController:vc];

    m_viewController = nc;

    [m_window setRootViewController:m_viewController];
    [m_window makeKeyAndVisible];

    NSString *currentURLString = [[NSUserDefaults standardUserDefaults] objectForKey:sCurrentMovieKey];
    if (currentURLString) {
        [vc _pushMovieWithURLString:currentURLString animated:NO];
    }

    return YES;
}

@synthesize window         = m_window,
            viewController = m_viewController;

@end
