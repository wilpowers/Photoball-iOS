//
//  ConfigGalleryViewController.m
//  ELCImagePickerDemo
//
//  Created by William Powers on 1/16/13.
//  Copyright (c) 2013 ELC Technologies. All rights reserved.
//

#import "ConfigGalleryViewController.h"

@interface ConfigGalleryViewController ()

@end

@implementation ConfigGalleryViewController
@synthesize gallery;

+ (UIImage *)generatePhotoThumbnail:(UIImage *)image
{
	// Create a thumbnail version of the image for the event object.
	CGSize size = image.size;
	CGSize croppedSize;
	CGFloat ratio = 256.f;
	CGFloat offsetX = 0.f;
	CGFloat offsetY = 0.f;
	
	// check the size of the image, we want to make it
	// a square with sides the size of the smallest dimension
	if (size.width > size.height) {
		offsetX = (size.height - size.width) / 2;
		croppedSize = CGSizeMake(size.height, size.height);
	} else {
		offsetY = (size.width - size.height) / 2;
		croppedSize = CGSizeMake(size.width, size.width);
	}
	
	// Crop the image before resize
	CGRect clippedRect = CGRectMake(offsetX * -1, offsetY * -1, croppedSize.width, croppedSize.height);
	CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], clippedRect);
	// Done cropping
	
	// Resize the image
	CGRect rect = CGRectMake(0.0, 0.0, ratio, ratio);
	
	UIGraphicsBeginImageContext(rect.size);
	[[UIImage imageWithCGImage:imageRef] drawInRect:rect];
	UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	// Done Resizing
    
    UIImageView *imgView = [[UIImageView alloc] initWithImage:thumbnail];
    imgView.layer.cornerRadius = 20.f;
    imgView.layer.masksToBounds = YES;
    imgView.opaque = NO;
    imgView.backgroundColor = [UIColor clearColor];
    
    CGSize newSize = [imgView bounds].size;
    UIGraphicsBeginImageContext(newSize);
    [[imgView layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
	return newImage;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = @"Unnamed Gallery";
        groupHeading = @[@"Gallery", @"Thumbnail Settings", @"Choose Photos"];
        isTintingSupported = NO;
        NSString *reqSysVer = @"6.0";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
        {
            isTintingSupported = YES;
        }
        gallery = [[PBGallery alloc] init];
        
        launchButton = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                  target:self
                                  action:@selector(launchPhotoBall:)];
        
        NSArray *items = [NSArray arrayWithObjects:launchButton, nil];
        
        self.toolbarItems = items;
        launchButton.enabled = NO;
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.rowHeight = 50;
        self.view.backgroundColor = [UIColor blackColor];

    }
    return self;
}

- (void)launchPhotoBall:(id)sender
{
    CGRect frame;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        frame = CGRectMake(0,0,768,1024);
    }
    else
    {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        if (screenBounds.size.height == 568)
        {
            frame = CGRectMake(0,0,320,568);
        }
        else
        {
            frame = CGRectMake(0,0,320,480);
        }
    }
    interactiveViewController = [[InteractiveViewController alloc] initWithFrame:frame];
    for (PBImage* img in gallery.imageData)
    {
        [interactiveViewController SetupImage:img.img withImageURL:img.imgURL];
    }
    
    [interactiveViewController setThumbnailCount:thumbnailCountSlider.value];
    [interactiveViewController setThumbnailSize:thumbnailSizeSlider.value];
    [self presentViewController:interactiveViewController animated:YES completion:^{
        [interactiveViewController Start];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.toolbarHidden = NO;
    launchButton.enabled = gallery.imageData.count ? YES : NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return  [groupHeading count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [groupHeading objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int static const sectionCount[3] = { 1, 2, 1 };
    return sectionCount[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([indexPath section])
    {
        case 1:
            return 50;
        case 2:
            return 48;
        default:
            return 46;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    //NSInteger sectionRows = [tableView numberOfRowsInSection:[indexPath section]];
    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
    {
        if (section == 2)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                           reuseIdentifier:CellIdentifier];
        }
        else if (section == 1)
        {
            cell = [[SliderTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            SliderTableViewCell* sliderCell = (SliderTableViewCell*)cell;
            if (row == 0)
            {
                thumbnailCountSlider = sliderCell.slider;
                sliderCell.slider.minimumValue = 10;
                sliderCell.slider.maximumValue = 200;
                sliderCell.sliderValue = 200;
                sliderCell.tag = 1;
                sliderCell.descriptionLabel.text = @"Number of Thumbnails";
            }
            else if (row == 1)
            {
                thumbnailSizeSlider = sliderCell.slider;
                sliderCell.slider.minimumValue = 20;
                sliderCell.slider.maximumValue = 100;
                sliderCell.sliderValue = 70;
                sliderCell.tag = 2;
                sliderCell.descriptionLabel.text = @"Size of Thumbnails";
            }
        }
        else
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier];
        }
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.textLabel.textColor = [UIColor darkGrayColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
 
        switch (section)
        {
            case 0:
            {
                cell.textLabel.text = @"Name";
                
                UITextField *nameTextField = [[UITextField alloc] initWithFrame:CGRectMake(120, 12, 170, 30)];
                nameTextField.adjustsFontSizeToFitWidth = NO;
                nameTextField.textColor = [UIColor colorWithRed:0.206 green:0.291 blue:0.601 alpha:1.000];
                nameTextField.placeholder = @"Unnamed Gallery";
                nameTextField.keyboardType = UIKeyboardTypeDefault;
                nameTextField.returnKeyType = UIReturnKeyDefault;
                nameTextField.backgroundColor = [UIColor clearColor];
                nameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
                nameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
                nameTextField.textAlignment = NSTextAlignmentRight;
                nameTextField.userInteractionEnabled = NO;
                nameTextField.tag = 5;
                nameTextField.delegate = self;
                
                nameTextField.clearButtonMode = UITextFieldViewModeNever; // no clear 'x' button to the right
                [nameTextField setEnabled:YES];
                [cell.contentView addSubview:nameTextField];
            }
            break;
            case 2:
            {
                choosePhotoCell = cell;
                cell.textLabel.text = @"Select an Album";
                if (gallery.imageData.count)
                {
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu photos selected.", (unsigned long)gallery.imageData.count];
                    cell.detailTextLabel.textColor = [UIColor blueColor];
                }
                else
                {
                    cell.detailTextLabel.text = @"No photos selected.";
                    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
                }
                cell.detailTextLabel.backgroundColor = [UIColor clearColor];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
        }
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    return cell;
}

- (void)sliderCellValueChanged:(SliderTableViewCell*)cell
{
    if (cell.tag == 1)
    {
        gallery.numberOfThumbnails = cell.slider.value;
    }
    else if (cell.tag == 2)
    {
        gallery.thumbnailSize = CGSizeMake(cell.slider.value, cell.slider.value);
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    headerView.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 6, tableView.bounds.size.width - 10, 18)];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor blackColor];
    label.shadowOffset = CGSizeMake(2, 2);
    label.font = [UIFont boldSystemFontOfSize:18];
    label.backgroundColor = [UIColor clearColor];
    [headerView addSubview:label];
    return headerView;
}

// Saves the user name and score after the user enters it in the provided text field.
- (void) textFieldDidEndEditing:(UITextField*)textField
{
    textField.userInteractionEnabled = NO;
    if ([textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0)
    {
        gallery.name = @"Unnamed Gallery";
        self.title = gallery.name;
    }
    else
    {
        gallery.name = textField.text;
        self.title = gallery.name;
    }
}

// Terminates the editing session
- (BOOL) textFieldShouldReturn:(UITextField*)textField
{
	//Terminate editing
	[textField resignFirstResponder];
	textField.userInteractionEnabled = NO;
	return YES;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([indexPath section] == 0)
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UITextView *textView = (UITextView*)[cell.contentView viewWithTag:5];
        textView.userInteractionEnabled = YES;
        [textView becomeFirstResponder];
    }
    else if ([indexPath section] == 2)
    {
        ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] initWithNibName:@"ELCAlbumPickerController" bundle:[NSBundle mainBundle]];
        [albumController setDelegate:self];
        [self.navigationController pushViewController:albumController animated:YES];
    }
}

- (void)didFinishPickingMediaWithInfo:(NSArray *)info
{
    [gallery removeImages];
	for(NSDictionary *dict in info)
    {
        PBImage *imgData = [[PBImage alloc] init];
        imgData.imgURL = [[dict objectForKey:@"UIImagePickerControllerReferenceURL"] absoluteString];
        UIImage* img = [dict objectForKey:UIImagePickerControllerOriginalImage];
        UIImage* newImage = [ConfigGalleryViewController generatePhotoThumbnail:img];
        imgData.img = newImage;
        [gallery.imageData addObject:imgData];
    }
    
    if (gallery.imageData.count)
    {
        choosePhotoCell.detailTextLabel.text = [NSString stringWithFormat:@"%lu photos selected.", (unsigned long)gallery.imageData.count];
        choosePhotoCell.detailTextLabel.textColor = [UIColor blueColor];
    }
    else
    {
        choosePhotoCell.detailTextLabel.text = @"No photos selected.";
        choosePhotoCell.detailTextLabel.textColor = [UIColor darkGrayColor];
    }
}

@end
