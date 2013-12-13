//
//  SliderTableViewCell.m
//  ELCImagePickerDemo
//
//  Created by William Powers on 1/18/13.
//  Copyright (c) 2013 ELC Technologies. All rights reserved.
//

#import "SliderTableViewCell.h"

@implementation SliderTableViewCell
@synthesize slider;
@synthesize descriptionLabel;
@synthesize valueLabel;
@synthesize delegate;
@synthesize sliderValue = _sliderValue;

- (int)sliderValue
{
    return _sliderValue;
}

- (void)setSliderValue:(int)newVal
{
    if (newVal != _sliderValue)
    {
        _sliderValue = newVal;
        if (slider)
        {
            slider.value = _sliderValue;
        }
        if (valueLabel)
        {
            valueLabel.text = [NSString stringWithFormat:@"%d", _sliderValue];
        }
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        slider = [[UISlider alloc] initWithFrame:CGRectMake(44, 22, 212, 20)];
        [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
        slider.continuous = YES;
        slider.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:slider];
        
        descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(46, 4, 160, 20)];
        descriptionLabel.textColor = [UIColor darkGrayColor];
        descriptionLabel.backgroundColor = [UIColor clearColor];
        descriptionLabel.font = [UIFont systemFontOfSize:14];
        descriptionLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:descriptionLabel];
        
        valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(94, 4, 160, 20)];
        valueLabel.textColor = [UIColor darkGrayColor];
        valueLabel.backgroundColor = [UIColor clearColor];
        valueLabel.font = [UIFont systemFontOfSize:14];
        valueLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:valueLabel];
        
        decrement = [UIButton buttonWithType:UIButtonTypeCustom];
        [decrement setImage:[UIImage imageNamed:@"subtract.png"] forState:UIControlStateNormal];
        [decrement addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventTouchUpInside];
        decrement.frame = CGRectMake(-2,8,50,50);
        [self.contentView addSubview:decrement];
        
        increment = [UIButton buttonWithType:UIButtonTypeCustom];
        [increment setImage:[UIImage imageNamed:@"add.png"] forState:UIControlStateNormal];
        [increment addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventTouchUpInside];
        increment.frame = CGRectMake(253,8,50,50);
        [self.contentView addSubview:increment];
    }
    return self;
}

- (void) valueChanged:(id)sender
{
    UIButton *button = (UIButton*)sender;
    int maxValue = (int)slider.maximumValue;
    int minValue = (int)slider.minimumValue;
    int value = (int)slider.value;
    value += (button == increment) ? 1 : -1;
    slider.value = value;
    decrement.enabled = !(minValue == value);
    increment.enabled = !(maxValue == value);
    valueLabel.text = [NSString stringWithFormat:@"%d", value];
    
    if ([delegate respondsToSelector:@selector(sliderCellValueChanged:)])
    {
		[delegate performSelector:@selector(sliderCellValueChanged:) withObject:self];
	}
}

- (void) sliderAction:(id)sender
{
    int maxValue = (int)slider.maximumValue;
    int minValue = (int)slider.minimumValue;
    int value = (int)slider.value;
    decrement.enabled = !(minValue == value);
    increment.enabled = !(maxValue == value);
    valueLabel.text = [NSString stringWithFormat:@"%d", value];
    
    if ([delegate respondsToSelector:@selector(sliderCellValueChanged:)])
    {
		[delegate performSelector:@selector(sliderCellValueChanged:) withObject:self];
	}
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
