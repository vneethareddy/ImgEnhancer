//
//  MAOpenCV.h
//  instaoverlay
//
//  Created by Maximilian Mackh on 11/10/12.
//  Copyright (c) 2012 mackh ag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>

@interface MAOpenCV : NSObject

+ (UIImage *) UIImageFromCVMat: (cv::Mat)cvMat;
+ (UIImage *) convertToRGB: (UIImage *) grayImg;

+ (cv::Mat)cvMatFromPhotoCaptureImage:(UIImage *)image;
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (cv::Mat)cvMatFromGrayUIImage:(UIImage *)image;
+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image;

+ (UIImage*) imageByRotatingImage: (UIImage*) initImage fromImageOrientation: (UIImageOrientation) orientation;

@end
