//
//  DemoApp.h
//  Demo
//
//  Created by Ricci Adams on 2011-10-12.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DemoViewController : UIViewController {
@private
    NSURLConnection *m_urlConnection;
    NSData          *m_movieData;
    SwiftMovie      *m_movie;
    SwiftMovieView  *m_movieView;
}

@end


@interface DemoAppDelegate : UIResponder <UIApplicationDelegate> {
@private
    UIWindow         *m_window;
    UIViewController *m_viewController;
}

@property (retain, nonatomic) UIWindow *window;
@property (retain, nonatomic) UIViewController *viewController;

@end
