//
//  AlbumPickerController.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

//#import <FacebookSDK/FacebookSDK.h>
#import "ELCAlbumPickerController.h"
#import "ELCAssetTablePicker.h"

@interface ELCAlbumPickerController() {
    CGFloat rowHeight;
}

@end

@implementation ELCAlbumPickerController

#pragma mark -
#pragma mark View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self.navigationItem setTitle:@"Loading..."];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.view.backgroundColor = [UIColor blackColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    rowHeight = 57.f;
    
	self.assetGroups = [[NSMutableArray alloc] init];
    
    self.library = [[ALAssetsLibrary alloc] init];

    // Load Albums into assetGroups
    dispatch_async(dispatch_get_main_queue(), ^
    {        
        // Group enumerator Block
        void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) 
        {
            if (group == nil) 
            {
                return;
            }
            
            [self.assetGroups addObject:group];

            // Reload albums
            [self performSelectorOnMainThread:@selector(reloadTableView) withObject:nil waitUntilDone:YES];
        };
        
        // Group Enumerator Failure Block
        void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
            
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            
            NSLog(@"A problem occured %@", [error description]);	                                 
        };	
                
        // Enumerate Albums
        [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                               usingBlock:assetGroupEnumerator 
                             failureBlock:assetGroupEnumberatorFailure];
    });
    
    //[self requestAlbums];
}

-(void)reloadTableView {
	
	[self.tableView reloadData];
	[self.navigationItem setTitle:@"Select an Album"];
}

-(void)selectedAssets:(NSArray*)_assets
{
    [SVProgressHUD showProgress:0 status:@"Processing Images"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
            NSMutableArray *returnArray = [[NSMutableArray alloc] init];
            
            float progress = 0;
            int index = 0;
            for(ALAsset *asset in _assets)
            {
                index++;
                progress =  (float)index / _assets.count;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showProgress:progress status:@"Processing Images"];
                });
                NSMutableDictionary *workingDictionary = [[NSMutableDictionary alloc] init];
                [workingDictionary setObject:[asset valueForProperty:ALAssetPropertyType] forKey:@"UIImagePickerControllerMediaType"];
                UIImage *fullScreenImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
                [workingDictionary setObject:fullScreenImage forKey:@"UIImagePickerControllerOriginalImage"];
                NSURL *assetURL = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]];
                [workingDictionary setObject:assetURL forKey:@"UIImagePickerControllerReferenceURL"];
                [returnArray addObject:workingDictionary];
            }
        
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                ConfigGalleryViewController* configGalleryViewController = (ConfigGalleryViewController*)self.delegate;
                
                [self.delegate didFinishPickingMediaWithInfo:[NSArray arrayWithArray:returnArray]];
                [self.navigationController popToViewController:configGalleryViewController animated:YES];
            });
       });
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.assetGroups count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    // Get count
    ALAssetsGroup *g = (ALAssetsGroup*)[self.assetGroups objectAtIndex:indexPath.row];
    [g setAssetsFilter:[ALAssetsFilter allPhotos]];
    NSInteger gCount = [g numberOfAssets];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%ld)",[g valueForProperty:ALAssetsGroupPropertyName], (long)gCount];
    [cell.imageView setImage:[UIImage imageWithCGImage:[(ALAssetsGroup*)[self.assetGroups objectAtIndex:indexPath.row] posterImage]]];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	ELCAssetTablePicker *picker = [[ELCAssetTablePicker alloc] initWithNibName:@"ELCAssetTablePicker" bundle:[NSBundle mainBundle]];
	picker.parent = self;

    // Move me    
    picker.assetGroup = [self.assetGroups objectAtIndex:indexPath.row];
    [picker.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    
	[self.navigationController pushViewController:picker animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return rowHeight;
}

/*
- (void)requestAlbums
{
    
    // We will request the user's events
    // These are the permissions we need:
    NSArray *permissionsNeeded = @[@"user_photos"];
    
    // Request the permissions the user currently has
    [FBRequestConnection startWithGraphPath:@"/me/permissions"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error){
                                  NSDictionary *currentPermissions= [(NSArray *)[result data] objectAtIndex:0];
                                  NSLog(@"current permissions %@", currentPermissions);
                                  NSMutableArray *requestPermissions = [[NSMutableArray alloc] initWithArray:@[]];
                                  
                                  // Check if all the permissions we need are present in the user's current permissions
                                  // If they are not present add them to the permissions to be requested
                                  for (NSString *permission in permissionsNeeded){
                                      if (![currentPermissions objectForKey:permission]){
                                          [requestPermissions addObject:permission];
                                      }
                                  }
                                  
                                  // If we have permission to request
                                  if ([requestPermissions count] > 0){
                                      // Ask for the missing permissions
                                      [FBSession.activeSession requestNewReadPermissions:requestPermissions
                                                                       completionHandler:^(FBSession *session, NSError *error) {
                                                                           if (!error) {
                                                                               // Permission granted
                                                                               NSLog(@"new permissions %@", [FBSession.activeSession permissions]);
                                                                               // We can request the user information
                                                                               [self makeRequestForUserAlbums];
                                                                           } else {
                                                                               // An error occurred, we need to handle the error
                                                                               // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                                                               NSLog(@"error %@", error.description);
                                                                           }
                                                                       }];
                                  } else {
                                      // Permissions are present
                                      // We can request the user information
                                      [self makeRequestForUserAlbums];
                                  }
                                  
                              } else {
                                  // An error occurred, we need to handle the error
                                  // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                  NSLog(@"error %@", error.description);
                              }
                          }];
}

- (void)makeRequestForUserAlbums
{
    [FBRequestConnection startWithGraphPath:@"me/albums"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (!error) {
                                  // Success! Include your code to handle the results here
                                  NSLog(@"user albums: %@", result);
                              } else {
                                  // An error occurred, we need to handle the error
                                  // Check out our error handling guide: https://developers.facebook.com/docs/ios/errors/
                                  NSLog(@"error %@", error.description);
                              }
                          }];
    
 
    // NSString * albumId = @"123456789";
    // NSString * path = [NSString stringWithFormat:@"%@/photos", albumId];
    // [facebook requestWithGraphPath:path andDelegate:self];
 
}
*/
@end

