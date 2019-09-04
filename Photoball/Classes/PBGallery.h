//
//  Gallery.h
//  ELCImagePickerDemo
//
//  Created by William Powers on 1/16/13.
//  Copyright (c) 2013 ELC Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBImage.h"

@interface PBGallery : NSObject {

}

@property (nonatomic, assign) int uniqueId;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, assign) NSUInteger numberOfThumbnails;
@property (nonatomic, assign) CGSize  thumbnailSize;
@property (nonatomic, retain) NSMutableArray  *imageData;

- (void) removeImages;

@end
