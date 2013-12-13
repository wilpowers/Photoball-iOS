//
//  Asset.h
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>


@interface ELCAsset : UIView {
	UIImageView *overlayView;
	BOOL selected;
}

@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic, weak) id parent;

-(id)initWithAsset:(ALAsset*)_asset;
-(BOOL)selected;
-(void)setSelected:(BOOL)_selected;

@end