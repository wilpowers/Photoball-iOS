//
//  AssetTablePicker.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"


@implementation ELCAssetTablePicker

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = YES;
}

-(void)viewDidLoad
{	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	[self.tableView setAllowsSelection:NO];
    self.view.backgroundColor = [UIColor blackColor];
    
    self.elcAssets = [[NSMutableArray alloc] init];
	
	doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
	[self.navigationItem setRightBarButtonItem:doneButtonItem];
	[self.navigationItem setTitle:@"Loading..."];

    //[self preparePhotos];
    [self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

-(void)preparePhotos
{
    [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) 
     {
         if(result)
         {
             ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
             [elcAsset setParent:self];
             [self.elcAssets addObject:elcAsset];
         }
     }];
    
    if (self.elcAssets.count > 0)
    {
        ELCAlbumPickerController* albumPickerController = self.parent;
        ConfigGalleryViewController* configGalleryViewController = albumPickerController.delegate;
        PBGallery *gallery = configGalleryViewController.gallery;
        
        for(ELCAsset *elcAsset in self.elcAssets)
        {
            NSString *strURL = [[[elcAsset.asset defaultRepresentation] url] absoluteString];
            for (PBImage *img in gallery.imageData)
            {
                if ([strURL isEqualToString:img.imgURL])
                {
                    [elcAsset setSelected:YES];
                }
            }
        }
    }
    
    [self.tableView reloadData];
    [self.navigationItem setTitle:@"Select Photos"];
}

- (void) doneAction:(id)sender
{
    doneButtonItem.enabled = NO;
    NSMutableArray *selectedAssetsImages = [[NSMutableArray alloc] init];
    
    for(ELCAsset *elcAsset in self.elcAssets)
    {
        if([elcAsset selected])
        {
            [selectedAssetsImages addObject:[elcAsset asset]];
        }
    }
    
    ELCAlbumPickerController* albumPickerController = (ELCAlbumPickerController*)self.parent;
    if (selectedAssetsImages.count == 0)
    {
        ConfigGalleryViewController* configGalleryViewController = (ConfigGalleryViewController*)albumPickerController.delegate;
        [self.navigationController popToViewController:configGalleryViewController animated:YES];
    }
    else    // copy the images over on an async thread and pop the view controller from picker
    {
        [albumPickerController selectedAssets:selectedAssetsImages];
    }
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ceil([self.assetGroup numberOfAssets] / 4.0);
}

- (NSArray*)assetsForIndexPath:(NSIndexPath*)indexPath
{
	NSUInteger startIndex = (indexPath.row*4);
	NSUInteger lastIndex = (startIndex+3);
    
	//NSLog(@"Getting assets for %d to %d with array count %d", index, lastIndex, [self.elcAssets count]);
    
	if (lastIndex < [self.elcAssets count])
    {
		return @[[self.elcAssets objectAtIndex:startIndex],
				[self.elcAssets objectAtIndex:startIndex+1],
				[self.elcAssets objectAtIndex:startIndex+2],
				[self.elcAssets objectAtIndex:startIndex+3]];
	}
	else if (lastIndex-1 < [self.elcAssets count])
    {
        
		return @[[self.elcAssets objectAtIndex:startIndex],
				[self.elcAssets objectAtIndex:startIndex+1],
				[self.elcAssets objectAtIndex:startIndex+2]];
	}
	else if (lastIndex-2 < [self.elcAssets count])
    {
        
		return @[[self.elcAssets objectAtIndex:startIndex],
				[self.elcAssets objectAtIndex:startIndex+1]];
	}
	else if (lastIndex-3 < [self.elcAssets count])
    {
        
		return @[[self.elcAssets objectAtIndex:startIndex]];
	}
    
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) 
    {		        
        cell = [[ELCAssetCell alloc] initWithAssets:[self assetsForIndexPath:indexPath] reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }	
	else 
    {
		[cell setAssets:[self assetsForIndexPath:indexPath]];
	}
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 79;
}

- (int)totalSelectedAssets
{
    int count = 0;
    for (ELCAsset *asset in self.elcAssets)
    {
		if([asset selected]) 
        {            
            count++;	
		}
	}
    
    return count;
}

@end
