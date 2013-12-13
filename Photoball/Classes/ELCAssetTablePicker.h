//
//  AssetTablePicker.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ConfigGalleryViewController.h"
#import "SVProgressHUD.h"

@interface ELCAssetTablePicker : UITableViewController
{
	int selectedAssets;
	UIBarButtonItem *doneButtonItem;	
	NSOperationQueue *queue;
}

@property (nonatomic, weak) id parent;
@property (nonatomic, strong) ALAssetsGroup *assetGroup;
@property (nonatomic, strong) NSMutableArray *elcAssets;
@property (nonatomic, strong) IBOutlet UILabel *selectedAssetsLabel;

-(int)totalSelectedAssets;
-(void)preparePhotos;
-(void)doneAction:(id)sender;

@end