//
//  PBGallery.m
//  ELCImagePickerDemo
//
//  Created by William Powers on 1/16/13.
//  Copyright (c) 2013 ELC Technologies. All rights reserved.
//

#import "PBGallery.h"

@implementation PBGallery
@synthesize uniqueId = _uniqueId;
@synthesize name = _name;
@synthesize numberOfThumbnails = _numberOfThumbnails;
@synthesize thumbnailSize = _thumbnailSize;
@synthesize imageData = _imageData;

- (id) init
{
    if ((self = [super init]))
    {
        _imageData = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    return self;
}

- (void)removeImages
{
    [_imageData removeAllObjects];
}

- (void) dealloc
{
    _name = nil;
    [_imageData removeAllObjects];
}

@end
