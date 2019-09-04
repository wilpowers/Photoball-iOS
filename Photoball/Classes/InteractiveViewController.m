//
//  InteractiveViewController.m
//  ELCImagePickerDemo
//
//  Created by William Powers on 1/18/13.
//  Copyright (c) 2013 ELC Technologies. All rights reserved.
//

#import "InteractiveViewController.h"
#import "PhotoBallViewController.h"

@interface InteractiveViewController ()
{
    PhotoBallViewController *photoBallVC;
}

@end

@implementation InteractiveViewController

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self)
    {
        self.gl1View = [[GL1View alloc] initWithFrame:frame];
        self.gl1View.parent = self;
        [self.view addSubview:self.gl1View];
        
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.toolbarHidden = YES;
    [super viewWillAppear:animated];
}

- (void) Start
{
    if (self.gl1View)
    {
        [_gl1View Start];
    }
    else
    {
        photoBallVC = [[PhotoBallViewController alloc] init];
        [self presentViewController:photoBallVC animated:YES completion:^{
            
        }];
    }
}

- (void)setThumbnailSize:(int)size
{
    if (self.gl1View)
    {
        [_gl1View setThumbnailSize:size];
    }
}

- (void)setThumbnailCount:(int)count
{
    if (self.gl1View)
    {
        [_gl1View setThumbnailCount:count];
    }
}

- (int) SetupImage:(UIImage*)img withImageURL:(NSString *)imgURL
{
    if (self.gl1View)
    {
        [_gl1View SetupImage:img withImageURL:imgURL];
        return 1;
    }
    return 0;
}

// iOS6
-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

// iOS6
- (BOOL)shouldAutorotate
{
    return NO;
}

@end
