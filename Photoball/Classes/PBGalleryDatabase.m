//
//  PBGalleryDatabase.m
//  ELCImagePickerDemo
//
//  Created by William Powers on 1/21/13.
//  Copyright (c) 2013 ELC Technologies. All rights reserved.
//

#import "PBGalleryDatabase.h"
#import "PBGallery.h"

@implementation PBGalleryDatabase

static PBGalleryDatabase *_database;

+ (PBGalleryDatabase*)database
{
    if (_database == nil)
    {
        _database = [[PBGalleryDatabase alloc] init];
    }
    return _database;
}

@end
