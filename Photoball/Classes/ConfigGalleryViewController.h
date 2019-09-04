//
//  ConfigGalleryViewController.h
//  ELCImagePickerDemo
//
//  Created by William Powers on 1/17/13.
//

#import <QuartzCore/QuartzCore.h>
//#import <DropboxSDK/DropboxSDK.h>
#import "SliderTableViewCell.h"
#import "ELCAlbumPickerController.h"
#import "AppDelegate.h"
#import "InteractiveViewController.h"
#import "PBGallery.h"
#import "PBImage.h"

@interface ConfigGalleryViewController : UITableViewController <UITextFieldDelegate, SliderTableViewCellDelegate> {
    InteractiveViewController *interactiveViewController;
    PBGallery *gallery;
    UITableViewCell *choosePhotoCell;
    NSArray *groupHeading;
    BOOL isTintingSupported;
    UIBarButtonItem *launchButton;
    UISlider *thumbnailSizeSlider;
    UISlider *thumbnailCountSlider;
}

@property (nonatomic, retain) PBGallery *gallery;

- (void)didFinishPickingMediaWithInfo:(NSArray *)info;

@end
