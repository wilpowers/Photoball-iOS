//
//  Common.h
//  PhotoBall
//
//  Created by Darkstar on 1/28/14.
//  Copyright (c) 2014 Gyrocade, LLC. All rights reserved.
//

#ifndef PhotoBall_Common_h
#define PhotoBall_Common_h

#import <GLKit/GLKit.h>

#define SWAP_ROWS_DOUBLE(a, b) { double *_tmp = a; (a)=(b); (b)=_tmp; }
#define SWAP_ROWS_FLOAT(a, b) { float *_tmp = a; (a)=(b); (b)=_tmp; }
#define MAT(m,r,c) (m)[(c)*4+(r)]

@interface PhotoRect : NSObject
{
@public
    int textureIndex;
    int tileIndex;
    GLKVector3 pt;
    GLKVector2 angle;
}
@end

float normalize_angle( float angDegrees );
GLKQuaternion LPFilterQuaternion(const GLKQuaternion smoothVal, const GLKQuaternion rawVal, const double smoothFactor);
// t: current time, b: start value, c: change in value, d: duration
float EaseInOutCubic(float t, float const b, float const c, float const d);
float angle_diff(float a1, float a2);
NSComparisonResult compareObjects(id obj1, id obj2, void* context);
int IntersectSegmentTriangle(GLKVector3 p, GLKVector3 q, GLKVector3 a, GLKVector3 b, GLKVector3 c);
int glhUnProjectf(float winx, float winy, float winz, float *modelview, float *projection, int *viewport, GLKVector3 *objectCoordinate);
void MultiplyMatrices4by4OpenGL_FLOAT(float *result, float *matrix1, float *matrix2);
void MultiplyMatrixByVector4by4OpenGL_FLOAT(float *resultvector, const float *matrix, const float *pvector);
//This code comes directly from GLU except that it is for float
int glhInvertMatrixf2(float *m, float *out);

#endif
