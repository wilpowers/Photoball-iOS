//
//  AlbumPickerController.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "SVProgressHUD.h"
#import "ConfigGalleryViewController.h"
#import "ELCAssetTablePicker.h"

@interface ELCAlbumPickerController : UITableViewController {
	
	NSOperationQueue *queue;
}

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) NSMutableArray *assetGroups;
@property (nonatomic, strong) ALAssetsLibrary *library;

-(void)selectedAssets:(NSArray*)a;

@end


