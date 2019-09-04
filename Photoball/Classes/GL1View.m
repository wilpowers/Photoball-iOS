//
//  InteractiveView.m
//  PhotoBall
//
//  Created by William Powers on 5/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GL1View.h"
#import "Common.h"

@implementation PhotoRect


@end

@interface GL1View() {
    GLKVector3 _camPosition;
    GLfloat _camDistance;
    GLfloat _sphereRadius;
    NSUInteger _numberOfImages;
    CGSize _screenSize;
    short _scale;
    BOOL                isZooming;
    BOOL                isFocusing;
    BOOL                isFocused;
    BOOL                isImageShowing;
    BOOL                isTouchingInterface;
    BOOL                isHUDShowing;
    CGRect              focusRect;
    uint32_t            focusingTime;
    uint32_t            focusDuration;
}

@end

@implementation GL1View

- (void)setThumbnailSize:(int)size
{
    _tileSize = size;
}

- (void)setThumbnailCount:(int)count
{
    _numberOfRectangles = count;
}

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame pixelFormat:GL_RGB565_OES depthFormat:GL_DEPTH_COMPONENT16_OES preserveBackbuffer:NO]))
	{
        _scale = [[UIScreen mainScreen] scale];
        _screenSize = CGSizeMake(frame.size.width*_scale, frame.size.height*_scale);
        [self setMultipleTouchEnabled:YES];
        screenRect = CGRectMake(0, 0, frame.size.width*_scale, frame.size.height*_scale);
        animationFrameInterval = 1;
        _numberOfRectangles = 200;
        _numberOfImages = 0;
        _tileSize = 70;
        _verticalPadding = 0;
        _horizontalPadding = 0;
        azimuth = 0.f;
        elevation = 0.f;
        targetAzimuth = 0.f;
        targetElevation = 0.f;
        azmDelt = 0.f;
        elvDelt = 0.f;
        sliderX = 0.f;
        _camPosition = GLKVector3Make(0, 0, -1.4f);
        _camDistance = GLKVector3Length(_camPosition);
        selectedImage = -1;
        targetCameraY = 0;
        targetCameraZ = -1.4f;
        isFocusing = NO;
        isZooming = NO;
        focusingTime = 0;
        focusDuration = 120;
        isHUDShowing = NO;
        worldMatrix = GLKMatrix4Identity;
        int buttonSize = 50;
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        closeImage = CGRectMake(0, 0, buttonSize, buttonSize);
        closeGallery = CGRectMake(screenBounds.size.width - buttonSize, screenBounds.size.height - buttonSize, buttonSize, buttonSize);
        CGFloat focusRectSize = 160.f;
        focusRect = CGRectMake(frame.size.width/2 - focusRectSize/2, frame.size.height/2 - focusRectSize/2, focusRectSize, focusRectSize);
        
        imageURL = [[NSMutableArray alloc] initWithCapacity:1];
        touchPoint = [[NSMutableArray alloc] initWithCapacity:5];
        imgView = [[UIImageView alloc] initWithFrame:frame];
        imgView.backgroundColor = [UIColor blackColor];
        
        // Create map to associate touch-events with views.
        touchMap = CFDictionaryCreateMutable(NULL, // use the default allocator
                                             0,		// unlimited size
                                             NULL,	// key callbacks - none, just do pointer comparison
                                             NULL); // value callbacks - same.
        
        isImageShowing = NO;
        
        // find the cross product of one triangle, and use that to store a normal vector
        // which we will use for pushing the tiles outward from the sphere

        photoTexCoord[0] = 0;   photoTexCoord[1] = 0;
        photoTexCoord[2] = 1;   photoTexCoord[3] = 0;
        photoTexCoord[4] = 0;   photoTexCoord[5] = 1;
        photoTexCoord[6] = 1;   photoTexCoord[7] = 1;
        
        photoRect = [[NSMutableArray alloc] initWithCapacity:100];
        
        frameDelta = CGPointZero;
        
        [self setupGL];
        [self InitializeCamera];
        
        /* initialize random seed: */
        srand ( (unsigned int)time(NULL) );
        
    }
    return self;
}

- (void) CreateSpherePoints {
    [photoRect removeAllObjects];
    NSUInteger numberOfImages = imageURL.count;
    
    GLfloat const scaleFactor = 0.00118f;
    GLfloat const tileSize = _tileSize * scaleFactor;

    double const width = tileSize + _horizontalPadding;
    double const flat_surface_area = (_numberOfRectangles + 2.0) * width * width;
    _sphereRadius = sqrt(flat_surface_area / (4.0*M_PI));
    
    double columnAngle = atan2(width/2.0, _sphereRadius) * 2.0;
    int const numColumns = floor(M_PI / columnAngle);
    columnAngle = columnAngle + (M_PI - columnAngle * numColumns) / numColumns;
    
    for (int i = 1; i < numColumns; ++i)
    {
        // Calculate the radius of the circle of latitude for the row.
        double longitudeRadius = _sphereRadius * cos(M_PI_2 - columnAngle*i);
        // Calculate the angle between rows.
        double rowAngle = atan2(width/2.0, longitudeRadius) * 2.0;
        // Calculate the number of colums.
        int numRows = floor((2.0*M_PI) / rowAngle);
        // Because step one is an approximation, the number of columns will not fit perfectly, so for presentation add padding to columnAngle.
        rowAngle += (2.0*M_PI - rowAngle * numRows) / numRows;
        
        // For each j in columns, translate -radius along the Z axis, rotate π / 2 + rowAngle * i around the X axis, and rotate columnAngle * j around the Y axis.
        for (int j = 0; j < numRows; ++j)
        {
            PhotoRect *rect = [[PhotoRect alloc] init];
            // For each j in columns, translate -radius along the Z axis, rotate π / 2 + rowAngle * i around the X axis, and rotate columnAngle * j around the Y axis.
            double theta = rowAngle * j;
            double phi = columnAngle * i;
            double const x = cos(theta) * sin(phi);
            double const y = cos(phi);
            double const z = sin(theta) * sin(phi);
            GLKVector3 v = GLKVector3Make(x, y, z);
            
            rect->angle = GLKVector2Make((GLKMathRadiansToDegrees(-theta) + 90.f), (GLKMathRadiansToDegrees(phi) + 90.f));
            rect->tileIndex = (int)photoRect.count;
            rect->textureIndex = (i*numRows + j) % numberOfImages;
            
            int const index = (int)photoRect.count * 4;
            
            // set basic dimensions for photo
            photoVertex[0 + index] = GLKVector3Make(tileSize, -tileSize, 0.f);
            photoVertex[1 + index] = GLKVector3Make(-tileSize, -tileSize, 0.f);
            photoVertex[2 + index] = GLKVector3Make(tileSize, tileSize, 0.f);
            photoVertex[3 + index] = GLKVector3Make(-tileSize, tileSize, 0.f);
        
            // increment angles
            phi += M_PI_2;
            theta += M_PI_2;
            
            float const cos_phi = cos(phi);
            float const sin_phi = sin(phi);
            float const cos_theta = cos(theta);
            float const sin_theta = sin(theta);
            
            // construct rotation matrices
            GLKMatrix3 rotationZY = GLKMatrix3Make(1.f, 0, 0,
                                                   0, cos_phi, -sin_phi,
                                                   0, sin_phi, cos_phi);
            
            GLKMatrix3 rotationXZ = GLKMatrix3Make(cos_theta, 0, sin_theta,
                                                   0, 1.f, 0,
                                                   -sin_theta, 0, cos_theta);
            
            GLKMatrix3 rotationTotal = GLKMatrix3Multiply(rotationXZ, rotationZY);
            
            photoVertex[0 + index] = GLKMatrix3MultiplyVector3(rotationTotal, photoVertex[0 + index]);
            photoVertex[1 + index] = GLKMatrix3MultiplyVector3(rotationTotal, photoVertex[1 + index]);
            photoVertex[2 + index] = GLKMatrix3MultiplyVector3(rotationTotal, photoVertex[2 + index]);
            photoVertex[3 + index] = GLKMatrix3MultiplyVector3(rotationTotal, photoVertex[3 + index]);
            
            photoVertex[0 + index] = GLKVector3Add(photoVertex[0 + index], v);
            photoVertex[1 + index] = GLKVector3Add(photoVertex[1 + index], v);
            photoVertex[2 + index] = GLKVector3Add(photoVertex[2 + index], v);
            photoVertex[3 + index] = GLKVector3Add(photoVertex[3 + index], v);
            
            [photoRect addObject:rect];
        }
    }
    
    // sort by texture index to decrease the number of texture binds when drawing
    [photoRect sortUsingFunction:compareObjects context:NULL];
}

- (void) ShowSelectedImage
{
    if (selectedImage > -1)
    {
        // show image
        PhotoRect *rect = [photoRect objectAtIndex:selectedImage];
        int imageIndex = rect->textureIndex;
        // Create assets library
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        // Try to load asset at mediaURL
        NSURL *theURL = [NSURL URLWithString:[imageURL objectAtIndex:imageIndex]];
        [library assetForURL:theURL resultBlock:^(ALAsset *asset) {
            // If asset exists
            if (asset) {
                UIImage *image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
                imgView.image = image;
                imgView.contentMode = UIViewContentModeScaleAspectFit;
                [self addSubview:imgView];
                [self bringSubviewToFront:imgView];
                isImageShowing = YES;
            } else {
                // Type your code here for non-existing asset
                NSLog(@"Couldn't find photo in library.  Was it deleted?");
            }
        } failureBlock:^(NSError *error) {
            // Type your code here for failure (when user doesn't allow location in your app)
        }];
    }
}

- (void) FocusPhoto
{
    if  (focusingTime < focusDuration)
    {
        azimuth = EaseInOutCubic(focusingTime, startAzimuth, targetAzimuth, focusDuration);
        elevation = EaseInOutCubic(focusingTime, startElevation, targetElevation, focusDuration);
        _camPosition.y = EaseInOutCubic(focusingTime, startCameraY, deltaCameraY, focusDuration);
        _camPosition.z = EaseInOutCubic(focusingTime, startCameraZ, deltaCameraZ, focusDuration);
        focusingTime++;
        
        azimuth = normalize_angle(azimuth);
        elevation = normalize_angle(elevation);
    }
    else
    {
        // we have arrived
        isFocusing = NO;
        isZooming = YES;
        isFocused = YES;
    }
}

- (void) Start
{
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(MainLoop:)];
    [self CreateSpherePoints];
    
    if (displayLink)
    {
        [displayLink setFrameInterval:animationFrameInterval];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void) DrawPhotoBall
{
    glMatrixMode(GL_MODELVIEW);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    glTranslatef(0.f, _camPosition.y, _camPosition.z);
    glRotatef(elevation, 1.f, 0.f, 0.f);
    glRotatef(azimuth, 0.f, 1.f, 0.f);
    
    glTexCoordPointer(2, GL_SHORT,  0, &photoTexCoord[0]);
    int prevTexIndex = -1;    
    for (int i = 0; i < photoRect.count; i++)
    {
        PhotoRect* rect = [photoRect objectAtIndex:i];
        if (rect->textureIndex != prevTexIndex)
        {
            glBindTexture(GL_TEXTURE_2D, texture[rect->textureIndex]);
        }
        prevTexIndex = rect->textureIndex;
        glVertexPointer(3, GL_FLOAT,  0, &photoVertex[i*4]);
        glDrawArrays(GL_TRIANGLE_STRIP, 0,  4);
    }
    
    [self swapBuffers];
}

- (void) MainLoop:(id)sender
{
    if( !isTouching )
    {
        azimuth   += azmDelt;
        azmDelt *= 0.99f;
        elevation   += elvDelt;
        elvDelt *= 0.98f;
    }
    else
    {
        azmDelt = (azimuth  - lastAzimuth);
        elvDelt = (elevation - lastElevation);
    }
    
    azimuth = normalize_angle(azimuth);
    elevation = normalize_angle(elevation);
    
    lastAzimuth  = azimuth;
    lastElevation = elevation;
    
    float thresh = 0.01f;
    if ( fabs( azmDelt ) > thresh || fabs( elvDelt ) > thresh )
    {
        coasting = YES;
    }
    else
    {
        coasting = NO;
    }
    
    if (isFocusing) {
        [self FocusPhoto];
    } else if (isZooming) {
        
    }
    [self DrawPhotoBall];
}

- (void) checkGLError
{
    GLenum error;
    while ((error = glGetError()) != GL_NO_ERROR) {
        printf("glError %d", error);
    }
}

- (void) setupGL
{
	//Enable required OpenGL states
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState  (GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glDisable(GL_BLEND);
    glPointSize(4.f);
    glClearColor(0.f, 0.f, 0.f, 1.0f);
	glDepthMask(GL_TRUE);
	glEnable(GL_DEPTH_TEST);
}

- (void) InitializeCamera
{
	CGRect rect = screenRect;
    GLfloat	size;
    GLfloat	zNear = 0.1f, zFar = 400.f;
    
    //Set the OpenGL projection matrix
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    size = zNear * tanf(GLKMathDegreesToRadians(FIELD_OF_VIEW) / 2.f);
    GLfloat screenRatio = (GLfloat)rect.size.width / (GLfloat)rect.size.height;
    glFrustumf(-size, size, -size / screenRatio, size / screenRatio, zNear, zFar);
    glViewport(0, 0, (GLfloat)rect.size.width, (GLfloat)rect.size.height);
	
	// store the projection matrix
    glGetFloatv(GL_PROJECTION_MATRIX, mat_projection);
    glGetIntegerv(GL_VIEWPORT, mat_viewport);
	
	glMatrixMode(GL_MODELVIEW);
}

- (int) SetupImage:(UIImage*)img withImageURL:(NSString *)imgURL
{
    CGImageRef		brushImage;
    CGContextRef	brushContext;
    CGColorSpaceRef colorSpace;
    GLubyte			*brushData;
    size_t			width, height;
    CGBitmapInfo    bitmapInfo;
    // First create a UIImage object from the data in a image file, and then extract the Core Graphics image
    brushImage = img.CGImage;
    
    // Get the width and height of the image
    width = CGImageGetWidth(brushImage);
    height = CGImageGetHeight(brushImage);
    colorSpace = CGImageGetColorSpace(brushImage);
    
    bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    
    // Make sure the image exists
    if (brushImage)
    {
        // Allocate  memory needed for the bitmap context
        brushData = (GLubyte *)calloc((width * height * 4), sizeof(GLubyte));
        // Use  the bitmatp creation function provided by the Core Graphics framework.
        brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, colorSpace, bitmapInfo);
        //CGColorSpaceRelease(colorSpace);
        
        // After you create the context, you can draw the  image to the context.
        CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), brushImage);
        // You don't need the context at this point, so you need to release it to avoid memory leaks.
        CGContextRelease(brushContext);
        
        glMatrixMode(GL_MODELVIEW);
        // Use OpenGL ES to generate a name for the texture.
        glGenTextures(1, &texture[_numberOfImages]);
        // Bind the texture name.
        glBindTexture(GL_TEXTURE_2D, texture[_numberOfImages]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
        // Release  the image data; it's no longer needed
        free(brushData);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        glGenerateMipmapOES(GL_TEXTURE_2D);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        _numberOfImages++;
        [imageURL addObject:imgURL];
        
		return 1;
	}
	return 0;
}

- (void) coast
{
    if (_camDistance < 1.1f)
    {
        azimuth -= frameDelta.x * 0.08f;
        elevation -= frameDelta.y * 0.06f;
    }
    else
    {
        azimuth += frameDelta.x * 0.04f;
        elevation += frameDelta.y * 0.03f;
    }
}

- (Vector2*)touchPointOGL:(UITouch*)touch
{
	CGPoint location = [touch locationInView:self];
    Vector2 *vec = [[Vector2 alloc] initWithX:(location.x*2.f) Y:(location.y*2.f)];
	return vec;
}

- (PhotoRect*)GetRectFromIndex:(int)index
{
    if (photoRect.count == 0) return nil;
    
    PhotoRect *tile = nil;
    for (int i = (int)photoRect.count - 1; i >= 0; --i)
    {
        tile = [photoRect objectAtIndex:i];
        if (tile->tileIndex == index)
        {
            return [photoRect objectAtIndex:i];
        }
    }
    
    return nil;
}

GLKVector3 getNormal(GLKVector3 a, GLKVector3 b, GLKVector3 c)
{
    GLKVector3 ab = GLKVector3Subtract(b, a);
    GLKVector3 ac = GLKVector3Subtract(c, a);
    GLKVector3 n = GLKVector3CrossProduct(ab, ac);
    
    return n;
}

- (void) Pick:(CGPoint)touchPt
{
    GLKVector3 objPosP = GLKVector3Make(0, 0, 0);
    GLKVector3 objPosQ = GLKVector3Make(0, 0, 0);
    glGetFloatv(GL_MODELVIEW_MATRIX, mat_modelview);		//Get the current Transformation Matrix
    selectedImage = -1;
    
    CGPoint screenXY = CGPointMake(touchPt.x, _screenSize.height - touchPt.y);
    
    // TODO: Add a check that determines if we're inside the globe, and if so, only check the inner tiles
    glhUnProjectf(screenXY.x, screenXY.y, 1.f, mat_modelview, mat_projection, mat_viewport, &objPosP);  // Ray start
    glhUnProjectf(screenXY.x, screenXY.y, 0.f, mat_modelview, mat_projection, mat_viewport, &objPosQ);  // Ray end
    
    
    // if we are inside the sphere, check the inner tiles only
    int i = 0;
    int index = 0;
    _camDistance = GLKVector3Length(_camPosition);
    // Check the outer tiles first
    if (_camDistance > _sphereRadius)
    {
        for (i = 0; i < photoRect.count; ++i)
        {
            if (IntersectSegmentTriangle(objPosP, objPosQ, photoVertex[index+0], photoVertex[index+1], photoVertex[index+2]) ||
                IntersectSegmentTriangle(objPosP, objPosQ, photoVertex[index+1], photoVertex[index+3], photoVertex[index+2]))
            {
                GLKVector3 n = getNormal(photoVertex[index+0], photoVertex[index+1], photoVertex[index+2]);
                n = GLKVector3Normalize(n);
                n = GLKVector3MultiplyScalar(n, -0.05f);   // negative sign projects outward, positive goes inward
                photoVertex[index+0] = GLKVector3Add(n, photoVertex[index+0]);
                photoVertex[index+1] = GLKVector3Add(n, photoVertex[index+1]);
                photoVertex[index+2] = GLKVector3Add(n, photoVertex[index+2]);
                photoVertex[index+3] = GLKVector3Add(n, photoVertex[index+3]);
                
                selectedImage = index/4;
                break;
            }
            index += 4;
        }
    }
    
    // if no outer tiles were selected, look to see if an inner tile was touched
    if (selectedImage == -1)
    {
        glhUnProjectf(screenXY.x, screenXY.y, 0.f, mat_modelview, mat_projection, mat_viewport, &objPosP);  // Ray start
        glhUnProjectf(screenXY.x, screenXY.y, 1.f, mat_modelview, mat_projection, mat_viewport, &objPosQ);  // Ray end
        
        i = 0;
        index = 0;
        for (i = 0; i < photoRect.count; ++i)
        {
            if (IntersectSegmentTriangle(objPosP, objPosQ, photoVertex[index+0], photoVertex[index+1], photoVertex[index+2]) ||
                IntersectSegmentTriangle(objPosP, objPosQ, photoVertex[index+1], photoVertex[index+3], photoVertex[index+2]))
            {
                GLKVector3 n = getNormal(photoVertex[index+0], photoVertex[index+1], photoVertex[index+2]);
                n = GLKVector3Normalize(n);
                n = GLKVector3MultiplyScalar(n, 0.05f);   // negative sign projects outward, positive goes inward
                photoVertex[index+0] = GLKVector3Add(n, photoVertex[index+0]);
                photoVertex[index+1] = GLKVector3Add(n, photoVertex[index+1]);
                photoVertex[index+2] = GLKVector3Add(n, photoVertex[index+2]);
                photoVertex[index+3] = GLKVector3Add(n, photoVertex[index+3]);
                
                selectedImage = index/4;
                break;
            }
            index += 4;
        }
    }
    
    if (selectedImage > -1)
    {
        azmDelt = 0;
        elvDelt = 0;
        startAzimuth = azimuth;
        startElevation = elevation;
        startCameraZ = _camPosition.z;
        startCameraY = _camPosition.y;
        PhotoRect *prect = [self GetRectFromIndex:i];
        targetAzimuth = -prect->angle.x;
        targetElevation = -prect->angle.y - 180.f;
        targetAzimuth = normalize_angle(targetAzimuth);
        targetElevation = normalize_angle(targetElevation);
        
        // calculate the difference between the two angles
        targetAzimuth = angle_diff(GLKMathDegreesToRadians(targetAzimuth), GLKMathDegreesToRadians(azimuth));
        targetElevation = angle_diff(GLKMathDegreesToRadians(targetElevation), GLKMathDegreesToRadians(elevation));
        // convert back to degrees
        targetAzimuth = GLKMathRadiansToDegrees(targetAzimuth);
        targetElevation = GLKMathRadiansToDegrees(targetElevation);
        
        deltaCameraY = targetCameraY - _camPosition.y;
        deltaCameraZ = targetCameraZ - _camPosition.z;
        
        isFocusing = YES;
        focusingTime = 0;
        
        // set the duration based on the amount of rotation we're doing
        float deltaAngle = sqrtf(powf(targetAzimuth, 2) + powf(targetElevation, 2));
        if (deltaAngle > 100.f)
        {
           focusDuration = 100;
        }
        else if (deltaAngle > 10.f)
        {
            focusDuration = 60;
        }
        else
        {
            focusDuration = 30;
        }
    }
}

// Finger Touch Down on the Screen
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    isTouching = YES;
    touchMoved = NO;
    
    for (UITouch *touch in touches)
    {
        Vector2 *pt = [self touchPointOGL:touch];
        [touchPoint addObject:pt];
        CFDictionarySetValue(touchMap, CFBridgingRetain(touch), CFBridgingRetain(pt));
	}

    Vector2 *pt;
    switch (CFDictionaryGetCount(touchMap))
    {
        case 1:
        {
            if (isImageShowing)
            {
                pt = [touchPoint objectAtIndex:0];
                if (CGRectContainsPoint(closeImage, CGPointMake(pt.x, pt.y)))
                {
                    [imgView removeFromSuperview];
                    isImageShowing = NO;
                    isTouchingInterface = YES;
                }
                if (CGRectContainsPoint(closeGallery, CGPointMake(pt.x, pt.y)))
                {
                    [imgView removeFromSuperview];
                    isImageShowing = NO;
                    isTouchingInterface = YES;
                    [self.parent dismissViewControllerAnimated:YES completion:NULL];
                }
            }
            else
            {
                //pt = [touchPoint objectAtIndex:0];
                if( coasting )
                {
                    stopping = YES;
                }
            }
        }
        break;
        case 2:
        {
            Vector2 *ptA = [touchPoint objectAtIndex:0];
            Vector2 *ptB = [touchPoint objectAtIndex:1];
            pinchDistance = GLKVector2Distance(ptA.v, ptB.v);
        }
        break;
    }
}

// Finger Moves across the Screen
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{    
    if (isFocusing || isImageShowing)
    {
        return;
    }
    
    // did we move the image out of focus?
    if (isFocused)
    {
        isFocused = NO;
    }
    
    switch (CFDictionaryGetCount(touchMap))
    {
        case 1:
        {
            for (UITouch* touch in touches)
            {
                Vector2 *lastTouchPoint = (Vector2*)CFDictionaryGetValue(touchMap, CFBridgingRetain(touch));
                Vector2 *currentTouchPoint = [self touchPointOGL:touch];
                GLKVector2 delta = GLKVector2Subtract(currentTouchPoint.v, lastTouchPoint.v);
                lastTouchPoint.x = currentTouchPoint.x;
                lastTouchPoint.y = currentTouchPoint.y;
                CFDictionarySetValue(touchMap, CFBridgingRetain(touch), CFBridgingRetain(lastTouchPoint));
                frameDelta.x = delta.x;
                frameDelta.y = delta.y;
                [self coast];
            }
        }
        break;
        case 2:
        {
            for (UITouch* touch in touches)
            {
                Vector2 *lastTouchPoint = (Vector2*)CFDictionaryGetValue(touchMap, CFBridgingRetain(touch));
                Vector2 *currentTouchPoint = [self touchPointOGL:touch];
                lastTouchPoint.x = currentTouchPoint.x;
                lastTouchPoint.y = currentTouchPoint.y;
                CFDictionarySetValue(touchMap, CFBridgingRetain(touch), CFBridgingRetain(lastTouchPoint));
            }
            float yPinchDistance = pinchDistance;
            Vector2 *ptA = [touchPoint objectAtIndex:0];
            Vector2 *ptB = [touchPoint objectAtIndex:1];
            pinchDistance = GLKVector2Distance(ptA.v, ptB.v);
            float pinchDelta = yPinchDistance - pinchDistance;
            _camPosition.y += 0.0015f*pinchDelta;
            _camPosition.z -= 0.005f*pinchDelta;
            _camPosition.z = CLAMP(_camPosition.z, -3.f, 0.f);
            _camDistance = GLKVector3Length(_camPosition);
        }
        break;
    }
    
    touchMoved = YES;
}

// Finger Lifts off the Screen
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isFocusing || isImageShowing || isTouchingInterface)
    {
        isTouchingInterface = NO;
        for (UITouch *touch in touches)
        {
            NSValue *val = CFDictionaryGetValue(touchMap, CFBridgingRetain(touch));
            CFDictionaryRemoveValue(touchMap, CFBridgingRetain(touch));
            [touchPoint removeObject:val];
        }
        return;
    }

    NSUInteger totalTouches = CFDictionaryGetCount(touchMap);
    
    for (UITouch *touch in touches)
    {
        if( !isImageShowing && !touchMoved && (totalTouches == 1) )
        {
            CGPoint pt = [touch locationInView:self];
            Vector2 *touchPointA = [self touchPointOGL:touch];
            if (isFocused)
            {
                if (CGRectContainsPoint(focusRect, pt))
                {
                    [self ShowSelectedImage];
                }
                else
                {
                    [self Pick:CGPointMake(touchPointA.x, touchPointA.y)];
                }
            }
            else
            {
                [self Pick:CGPointMake(touchPointA.x, touchPointA.y)];
            }
        }
        Vector2 *pt = CFDictionaryGetValue(touchMap, CFBridgingRetain(touch));
        CFDictionaryRemoveValue(touchMap, CFBridgingRetain(touch));
        [touchPoint removeObject:pt];
    }

    totalTouches = CFDictionaryGetCount(touchMap);
	if( totalTouches == 0 )
    {
        isTouching    = NO;
        touchMoved	= NO;
        stopping    = NO;
    }
}

- (void) dealloc
{
    [displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [photoRect removeAllObjects];
    [touchPoint removeAllObjects];
    glDeleteTextures((GLsizei)imageURL.count, &texture[0]);
}


@end
