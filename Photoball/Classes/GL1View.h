//
//  GL1View.h
//  PhotoBall
//
//  Created by William Powers on 5/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>
#import "EAGLView.h"
#import "OpenGL_Internal.h"
#import "Vector2.h"

#define FIELD_OF_VIEW 45.f

@interface PhotoRect : NSObject
{
@public
    int textureIndex;
    GLKVector3 pt;
    GLKVector2 angle;
}
@end

@interface GL1View : EAGLView
{
    GLuint					texture[512];
    CGRect                 screenRect;
    NSInteger             animationFrameInterval;
    CADisplayLink      *displayLink;
    NSTimer               *renderTimer;
    GLfloat                     azimuth, elevation, azmDelt, elvDelt, lastAzimuth, lastElevation;
    GLfloat                     pinchDistance;
    GLfloat                       screenSize[2];
    GLfloat                       _itemWidth;
    GLfloat                       _itemHeight;
    GLfloat                       _verticalPadding;
    GLfloat                       _horizontalPadding;
    int                         numberOfRectangles;
    GLfloat                   targetAzimuth;
    GLfloat                   targetElevation;
    GLfloat                   startAzimuth;
    GLfloat                   startElevation;
    GLfloat                   startCameraZ;
    GLfloat                   startCameraY;
    GLfloat                   targetCameraZ;
    GLfloat                   targetCameraY;
    GLfloat                   deltaCameraZ;
    GLfloat                   deltaCameraY;
    GLfloat                   sliderX;
    
    BOOL                isFocusing;
    BOOL                isFocused;
    BOOL                isImageShowing;
    BOOL                isTouchingInterface;
    BOOL                isHUDShowing;
    CGRect              focusRect;
    
    uint32_t                     focusingTime;
    uint32_t                     focusDuration;
    
    GLfloat					mat_projection[16];
	GLfloat					mat_modelview[16];
	int						mat_viewport[4];
    
    GLKVector3          photoVertex[200*4];
    GLushort            photoTexCoord[8];
    CGPoint             frameDelta;
    
    CGRect              closeImage;
    CGRect              closeGallery;
    
    BOOL                   coasting, stopping, isTouching, touchMoved;
    BOOL                bHasGyro;
    
    GLKQuaternion smGyroQuat;
    GLfloat zoomFactor;
    
    GLKMatrix4 worldMatrix;
    
    int                         selectedImage;
    
    // CFDictionary to map touch events to touch-views.
	CFMutableDictionaryRef touchMap;
    NSMutableArray *touchPoint;
    UIImageView    *testSlider;
    UIImageView     *imgView;
    NSMutableArray *imageURL;
    NSMutableArray *photoRect;
    
    CMMotionManager *motionManager;
}

- (void) Start;
- (void) CreateSpherePoints;
- (void) MainLoop:(id)sender;
- (void) DrawPhotoBall;
- (void) setupGL;
- (void) InitializeCamera;
- (int) SetupImage:(UIImage*)img withImageURL:(NSString*)imgURL;
- (id)initWithFrame:(CGRect)frame;
- (void)setThumbnailSize:(int)size;
- (void)setThumbnailCount:(int)count;
- (void)Pick:(CGPoint)touchPoint;

@property (nonatomic, weak) id parent;

@end
