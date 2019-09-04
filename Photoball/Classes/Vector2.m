//
//  Vector2.m
//  PhotoBall
//
//  Created by William Powers on 8/27/13.
//  Copyright (c) 2013 William Powers. All rights reserved.
//

#import "Vector2.h"

@implementation Vector2

- (id)initWithX:(float)x Y:(float)y
{
    self = [super init];
    if (self)
    {
        _v.x = x;
        _v.y = y;
    }
    
    return self;
}

- (void)setX:(float)x
{
    _v.x = x;
}

- (void)setY:(float)y
{
    _v.y = y;
}

- (float)x
{
    return _v.x;
}

- (float)y
{
    return _v.y;
}


@end
