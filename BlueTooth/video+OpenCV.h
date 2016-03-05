


//
//  video+OpenCV.h
//  BlueTooth
//
//  Created by apple on 16/1/7.
//  Copyright © 2016年 apple. All rights reserved.


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface  CVCamera:NSObject

- (instancetype)initWithCameraView:(UIImageView *)view;
- (void)startCapture;
-(NSData *)hexString:(NSString *)hexString;

@property (nonatomic, assign) int fingerTipsNum;

@end