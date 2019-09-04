//
//  GalleryViewController.m
//  PhotoBall
//
//  Created by William Powers on 3/26/13.
//  Copyright (c) 2013 William Powers. All rights reserved.
//

#import "GalleryViewController.h"

@interface GalleryViewController ()

@end

@implementation GalleryViewController
@synthesize toolBar;

-(void)launchConfigGallery:(id)sender
{
    ConfigGalleryViewController *configGalleryViewController = [[ConfigGalleryViewController alloc] initWithNibName:@"ConfigGalleryViewController" bundle:[NSBundle mainBundle]];
    
	[self.navigationController pushViewController:configGalleryViewController animated:YES];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (id) init
{
    self = [super init];
    if (self)
    {
        // Show toolbar
        self.navigationController.toolbar.barStyle = UIBarStyleBlack;
        
        UIBarButtonItem *item1 = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                  target:self
                                  action:@selector(launchConfigGallery:)];
        
        NSArray *items = [NSArray arrayWithObjects:item1, nil];
        
        self.toolbarItems = items;
        MExtendedTableView *tableView = [[MExtendedTableView alloc] initWithFrame:self.view.bounds];
        UIView *theView = [tableView emptyViewWithTitle:@"No Galleries Created"];
        tableView.emptyView = theView;
        self.tableView = tableView;
        self.tableView.dataSource = self;
        self.view.backgroundColor = [UIColor blackColor];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.title = @"Galleries";
    self.navigationController.toolbarHidden = NO;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    [self.tableView reloadData];
}


@end
