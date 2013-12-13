//
//  Vector2.h
//  PhotoBall
//
//  Created by William Powers on 8/27/13.
//  Copyright (c) 2013 William Powers. All rights reserved.
//

#import <GLKit/GLKit.h>

// convenience wrapper class for GLKVector2, for use with touch events
@interface Vector2 : NSObject {

}

@property (readwrite) GLKVector2 v;
@property (readwrite) float x;
@property (readwrite) float y;

- (id)initWithX:(float)x Y:(float)y;

@end
