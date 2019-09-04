//
//  SliderTableViewCell.h
//  ELCImagePickerDemo
//
//  Created by William Powers on 1/18/13.
//  Copyright (c) 2013 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SliderTableViewCell : UITableViewCell {
    UILabel *descriptionLabel;
    UILabel *valueLabel;
    UIButton *increment;
    UIButton *decrement;
    UISlider *slider;
    int _sliderValue;
    id delegate;
}

@property (nonatomic, retain) UILabel *descriptionLabel;
@property (nonatomic, retain) UILabel *valueLabel;
@property (nonatomic, retain) UISlider *slider;
@property (nonatomic, retain) id delegate;
@property (assign) int sliderValue;

- (int) sliderValue;
- (void) setSliderValue:(int)newVal;

@end

@protocol SliderTableViewCellDelegate

- (void)sliderCellValueChanged:(SliderTableViewCell *)cell;

@end
