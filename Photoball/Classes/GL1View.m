//
//  InteractiveView.m
//  PhotoBall
//
//  Created by William Powers on 5/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GL1View.h"

@implementation PhotoRect


@end

@interface GL1View() {
    GLKVector3 _camPosition;
    GLfloat _camDistance;
    GLfloat _sphereRadius;
    NSUInteger _numberOfImages;
}

@end

@implementation GL1View

//Smoothing. Lower number is Smoother. 1.0 is no smoothing
float const static kSmoothGyro = 0.15f;

static
GLKQuaternion LPFilterQuaternion(const GLKQuaternion smoothVal, const GLKQuaternion rawVal, const double smoothFactor)
{
    return GLKQuaternionMake( rawVal.x*smoothFactor + smoothVal.x*(1.0-smoothFactor),
                             rawVal.y*smoothFactor + smoothVal.y*(1.0-smoothFactor),
                             rawVal.z*smoothFactor + smoothVal.z*(1.0-smoothFactor),
                             rawVal.w*smoothFactor + smoothVal.w*(1.0-smoothFactor));
}
// t: current time, b: start value, c: change in value, d: duration
static float EaseInOutCubic(float t, float const b, float const c, float const d)
{
	if ((t/=d/2) < 1)
    {
        return c/2*t*t*t + b;
    }
    else
    {
        t-=2;
        return c/2*(t*t*t + 2) + b;
    }
}

static float
angle_diff(float a1, float a2)
{
    return fmodf((fmodf((a1 - a2), 2.f*M_PI) + 3.f*M_PI), 2.f*M_PI) - M_PI;
}
static NSComparisonResult compareObjects(id obj1, id obj2, void* context) {
	int value1 = ((PhotoRect*)obj1)->textureIndex;
    int value2 = ((PhotoRect*)obj2)->textureIndex;
	if (value1 < value2) return NSOrderedAscending;
	if (value1 > value2) return NSOrderedDescending;
	return NSOrderedSame;
}

static
void __gluMultMatrixVecd(const float matrix[16], const double in[4], double out[4])
{
	int i;
	
	for (i=0; i<4; i++) {
		out[i] =
		in[0] * matrix[0*4+i] +
		in[1] * matrix[1*4+i] +
		in[2] * matrix[2*4+i] +
		in[3] * matrix[3*4+i];
	}
}

static
int gluProject(const GLKVector3 obj,
               const GLfloat modelMatrix[16],
               const GLfloat projMatrix[16],
               const int viewport[4],
               GLKVector3* win)
{
	double in[4];
	double out[4];
	
	in[0]=obj.x;
	in[1]=obj.y;
	in[2]=obj.z;
	in[3]=1.0;
    // multiply vector by modelview and projection matrix
	__gluMultMatrixVecd(modelMatrix, in, out);
	__gluMultMatrixVecd(projMatrix, out, in);
	if (in[3] == 0.0)
		return(0);
    
    // normalize vector
	in[0] /= in[3];
	in[1] /= in[3];
	in[2] /= in[3];
	/* Map x, y and z to range 0-1 */
	in[0] = in[0] * 0.5 + 0.5;
	in[1] = in[1] * 0.5 + 0.5;
	in[2] = in[2] * 0.5 + 0.5;
	
	/* Map x,y to viewport */
	in[0] = in[0] * viewport[2] + viewport[0];
	in[1] = in[1] * viewport[3] + viewport[1];
	
	win->x = in[0];
	win->y = in[1];
	win->z=in[2];
	
	return(1);
}


- (void)setThumbnailSize:(int)size
{
    _itemWidth = _itemHeight = size;
}

- (void)setThumbnailCount:(int)count
{
    numberOfRectangles = count;
}

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame pixelFormat:GL_RGB565_OES depthFormat:GL_DEPTH_COMPONENT16_OES preserveBackbuffer:NO]))
	{
        GLubyte scale = [[UIScreen mainScreen] scale];
        [self setMultipleTouchEnabled:YES];
        screenRect = CGRectMake(0, 0, frame.size.width*scale, frame.size.height*scale);
        screenSize[0] = screenRect.size.width;
        screenSize[1] = screenRect.size.height;
        animationFrameInterval = 1;
        numberOfRectangles = 200;
        _numberOfImages = 0;
        _itemWidth = 70;
        _itemHeight = 70;
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
        
        //testSlider = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"slider.png"]];
        //[self addSubview:testSlider];
        //testSlider.frame = CGRectMake(0, 400, testSlider.frame.size.width, testSlider.frame.size.height);
        
        // Create map to associate touch-events with views.
        touchMap = CFDictionaryCreateMutable(NULL, // use the default allocator
                                             0,		// unlimited size
                                             NULL,	// key callbacks - none, just do pointer comparison
                                             NULL); // value callbacks - same.
        
        isImageShowing = NO;
        
        // find the cross product of one triangle, and use that to store a normal vector
        // which we will use for pushing the tiles outward from the sphere

        photoTexCoord[0] = 1;
        photoTexCoord[1] = 0;
        photoTexCoord[2] = 0;
        photoTexCoord[3] = 0;
        photoTexCoord[4] = 1;
        photoTexCoord[5] = 1;
        photoTexCoord[6] = 0;
        photoTexCoord[7] = 1;
        
        photoRect = [[NSMutableArray alloc] initWithCapacity:100];
        
        frameDelta = CGPointZero;
        
        [self setupGL];
        [self InitializeCamera];
        
        /*
        motionManager = [[CMMotionManager alloc] init];
        bHasGyro = motionManager.isGyroAvailable;
        
        motionManager.showsDeviceMovementDisplay = YES;
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
         */
        
        /* initialize random seed: */
        srand ( (unsigned int)time(NULL) );
        
    }
    return self;
}

GLKVector3 rotatePointXZ(GLKVector3 pt, double t)
{
    GLKVector3 newPt;
    
    newPt.x = pt.x*cos(t) - pt.z*sin(t);
    newPt.z = pt.x*sin(t) + pt.z*cos(t);
    newPt.y = pt.y;
    
    return newPt;
}

GLKVector3 rotatePointZY(GLKVector3 pt, double p)
{
    GLKVector3 newPt;
    
    newPt.z = pt.z*cos(p) - pt.y*sin(p);
    newPt.y = pt.z*sin(p) + pt.y*cos(p);
    newPt.x = pt.x;
    
    return newPt;
}

- (void) CreateSpherePoints
{
    PhotoRect *rect;
    [photoRect removeAllObjects];
    NSUInteger numberOfImages = imageURL.count;
    
    GLfloat scaleFactor = 0.00118f;
    GLfloat itemWidth = _itemWidth * scaleFactor;
    GLfloat itemHeight = _itemHeight * scaleFactor;

    double width = itemWidth + _horizontalPadding;
    double height = itemHeight + _verticalPadding;
    double flat_surface_area = (numberOfRectangles + 2) * width * height;
    _sphereRadius = sqrt(flat_surface_area / (4.0 * M_PI));
    double rowAngle = 2.0 * atan(((height / 2.0) / _sphereRadius));
    int numRows = floor(M_PI / rowAngle);
    rowAngle = rowAngle + (M_PI - rowAngle * numRows) / numRows;
    
    for (int i = 1; i < numRows; ++i)
    {
        // Calculate the radius of the circle of latitude for the row.
        double latitudeRadius = _sphereRadius * cos(M_PI/2.0 - rowAngle*i);
        // Calculate the angle between columns.
        double columnAngle = atan((width/2.0 / latitudeRadius)) * 2.0;
        // Calculate the number of colums.
        int numColumns = floor((2.0*M_PI) / columnAngle);
        // Because step one is an approximation, the number of columns will not fit perfectly, so for presentation add padding to columnAngle.
        columnAngle += (2.0*M_PI - columnAngle * numColumns) / numColumns;
        // For each j in columns, translate -radius along the Z axis, rotate π / 2 + rowAngle * i around the X axis, and rotate columnAngle * j around the Y axis.
        for (int j = 0; j < numColumns; ++j)
        {
            rect = [[PhotoRect alloc] init];
            // For each j in columns, translate -radius along the Z axis, rotate π / 2 + rowAngle * i around the X axis, and rotate columnAngle * j around the Y axis.
            double theta = columnAngle * j;
            double phi = rowAngle * i;
            rect->angle = GLKVector2Make((GLKMathRadiansToDegrees(-theta) + 90.f), (GLKMathRadiansToDegrees(phi) + 90.f));
            double x = cos(theta) * sin(phi);
            double y = cos(phi);
            double z = sin(theta) * sin(phi);
            
            NSUInteger index = photoRect.count * 4;
            
            photoVertex[0 + index].x = itemWidth;
            photoVertex[0 + index].y = -itemHeight;
            
            photoVertex[1 + index].x = -itemWidth;
            photoVertex[1 + index].y = -itemHeight;
            
            photoVertex[2 + index].x = itemWidth;
            photoVertex[2 + index].y = itemHeight;
        
            photoVertex[3 + index].x = -itemWidth;
            photoVertex[3 + index].y = itemHeight;
            
            // rotate around the x axis
            photoVertex[0 + index] = rotatePointZY(photoVertex[0 + index], phi + M_PI_2);
            photoVertex[1 + index] = rotatePointZY(photoVertex[1 + index], phi + M_PI_2);
            photoVertex[2 + index] = rotatePointZY(photoVertex[2 + index], phi + M_PI_2);
            photoVertex[3 + index] = rotatePointZY(photoVertex[3 + index], phi + M_PI_2);
            
            // rotate around the y axis (y is what we think of z: pointing into screen)
            photoVertex[0 + index] = rotatePointXZ(photoVertex[0 + index], theta + M_PI_2);
            photoVertex[1 + index] = rotatePointXZ(photoVertex[1 + index], theta + M_PI_2);
            photoVertex[2 + index] = rotatePointXZ(photoVertex[2 + index], theta + M_PI_2);
            photoVertex[3 + index] = rotatePointXZ(photoVertex[3 + index], theta + M_PI_2);
            
            photoVertex[0 + index] = GLKVector3Add(photoVertex[0 + index], GLKVector3Make(x, y, z));
            photoVertex[1 + index] = GLKVector3Add(photoVertex[1 + index], GLKVector3Make(x, y, z));
            photoVertex[2 + index] = GLKVector3Add(photoVertex[2 + index], GLKVector3Make(x, y, z));
            photoVertex[3 + index] = GLKVector3Add(photoVertex[3 + index], GLKVector3Make(x, y, z));
            
            rect->textureIndex = (i + j) % numberOfImages;
            [photoRect addObject:rect];
        }
    }
    
    // sort by texture index to decrease the number of texture binds when drawing
    [photoRect sortUsingFunction:compareObjects context:NULL];
}

//Calculate the Elevation and Azimuth angles
- (void) CalcElevationAzimuth
{
    if (bHasGyro)
    {
        CMDeviceMotion *d = motionManager.deviceMotion;
        CMQuaternion quat = d.attitude.quaternion;
        GLKQuaternion gyroQuat = GLKQuaternionMake(quat.x, quat.y, quat.z, quat.w);
        smGyroQuat = LPFilterQuaternion(smGyroQuat, gyroQuat, kSmoothGyro);
        GLKQuaternion qInverse = GLKQuaternionInvert(smGyroQuat);
        worldMatrix = GLKMatrix4MakeWithQuaternion(qInverse);
        worldMatrix.m[14] = zoomFactor;
    }
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
    }
    else
    {
        // we have arrived
        isFocusing = NO;
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
    
    //[self CalcElevationAzimuth];
    
    if (isFocusing)
    {
        [self FocusPhoto];
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

- (void) Pick:(CGPoint)touchPt
{
    GLKVector3 windowPos = GLKVector3Make(0, 0, 0);
    glGetFloatv(GL_MODELVIEW_MATRIX, mat_modelview);		//Get the current Transformation Matrix
    float greatestZ = 10;
    selectedImage = -1;
    for (int i = 0; i < photoRect.count; ++i)
    {
        PhotoRect *prect = [photoRect objectAtIndex:i];
        gluProject(prect->pt, mat_modelview, mat_projection, mat_viewport, &windowPos );
        CGRect rect = CGRectMake(windowPos.x - 20.f, screenSize[1] - windowPos.y - 20.f, 40.f, 40.f);
        if (CGRectContainsPoint(rect, touchPt))
        {
            // use z-sorting to determine which rect is closest
            if (windowPos.z < greatestZ)
            {
                selectedImage = i;
                greatestZ = windowPos.z;
            }
        }
    }
    if (selectedImage >= 0)
    {
        azmDelt = 0;
        elvDelt = 0;
        startAzimuth = azimuth;
        startElevation = elevation;
        startCameraZ = _camPosition.z;
        startCameraY = _camPosition.y;
        PhotoRect *prect = [photoRect objectAtIndex:selectedImage];
        targetAzimuth = -prect->angle.x;
        targetElevation = -prect->angle.y - 180.f;
        targetAzimuth = angle_diff(GLKMathDegreesToRadians(targetAzimuth), GLKMathDegreesToRadians(azimuth));
        targetAzimuth = GLKMathRadiansToDegrees(targetAzimuth);
        targetElevation = angle_diff(GLKMathDegreesToRadians(targetElevation), GLKMathDegreesToRadians(elevation));
        targetElevation = GLKMathRadiansToDegrees(targetElevation);
        deltaCameraY = targetCameraY - _camPosition.y;
        deltaCameraZ = targetCameraZ - _camPosition.z;
        isFocusing = YES;
        focusingTime = 0;
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
            Vector2 *touchPointA = [self touchPointOGL:touch];
            if (isFocused)
            {
                if (CGRectContainsPoint(focusRect, CGPointMake(touchPointA.x, touchPointA.y)))
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

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEnded:touches withEvent:event];
}


- (void) dealloc
{
    [displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [photoRect removeAllObjects];
    [touchPoint removeAllObjects];
    glDeleteTextures((GLsizei)imageURL.count, &texture[0]);
}


@end
