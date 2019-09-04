//
//  InteractiveViewController.h
//  ELCImagePickerDemo
//
//  Created by William Powers on 1/18/13.
//  Copyright (c) 2013 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GL1View.h"

@interface InteractiveViewController : UIViewController

- (id)initWithFrame:(CGRect)frame;
- (int) SetupImage:(UIImage*)img  withImageURL:(NSString *)imgURL;
- (void) Start;
- (void)setThumbnailSize:(int)size;
- (void)setThumbnailCount:(int)count;

@property (nonatomic, strong) GL1View *gl1View;

@end
