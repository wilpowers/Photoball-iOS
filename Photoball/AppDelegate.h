//
//  AppDelegate.h
//  Photoball
//
//  Created by William Powers on 11/27/13.
//  Copyright (c) 2013 Gyrocade, LLC. All rights reserved.
//

//#import <FacebookSDK/FacebookSDK.h>
//#import <DropboxSDK/DropboxSDK.h>
#import "GalleryViewController.h"

@class GalleryViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate, UINavigationControllerDelegate>

//- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) GalleryViewController *viewController;
@property (nonatomic, strong) UINavigationController *navController;


@end
