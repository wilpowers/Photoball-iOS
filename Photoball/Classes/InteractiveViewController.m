//
//  InteractiveViewController.m
//  ELCImagePickerDemo
//
//  Created by William Powers on 1/18/13.
//  Copyright (c) 2013 ELC Technologies. All rights reserved.
//

#import "InteractiveViewController.h"

@interface InteractiveViewController ()

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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
