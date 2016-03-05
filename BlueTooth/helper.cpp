//
//  helper.cpp
//  BlueTooth
//
//  Created by apple on 16/1/7.
//  Copyright © 2016年 apple. All rights reserved.
//

#include "helper.h"

#include <iostream>
#include <fstream>


using namespace std;
using namespace cv;


float distanceP2P(cv::Point a, cv::Point b){
    float d= sqrt(fabs( pow(a.x-b.x,2) + pow(a.y-b.y,2) )) ;
    return d;
}

float getAngleWithDirection(cv::Point s, cv::Point f, cv::Point e){
    float l1 = distanceP2P(f,s);
    float l2 = distanceP2P(f,e);
    float dot=(s.x-f.x)*(e.x-f.x) + (s.y-f.y)*(e.y-f.y);
    float angle = acos(dot/(l1*l2));
    angle=angle*180/M_PI;
    
    // 计算从s到f到e的旋转方向
    cv::Point f2s = cv::Point(s.x - f.x,s.y-f.y);
    cv::Point f2e = cv::Point(e.x - f.x,e.y - f.y);
    float direction = f2s.x*f2e.y - f2e.x*f2s.y;
    if (direction > 0 ) {
        return angle;
    } else {
        return -angle;
    }
    
}

float getAngle(cv::Point s, cv::Point f, cv::Point e){
    float l1 = distanceP2P(f,s);
    float l2 = distanceP2P(f,e);
    float dot=(s.x-f.x)*(e.x-f.x) + (s.y-f.y)*(e.y-f.y);
    float angle = acos(dot/(l1*l2));
    angle=angle*180/M_PI;
    
    return angle;
}


vector<cv::Point> detectUcurveWithContour(vector<cv::Point> contour)
{
    cv::Rect rect = boundingRect(contour);
    float toleranceMin = rect.height/5;
    //float toleranceMax =  rect.height*0.8;
    
    
    // Step 0: 平滑一下曲线
    for (int i = 1; i < contour.size() - 1; i++) {
        contour[i].x = (contour[i-1].x + contour[i].x + contour[i+1].x)/3;
        contour[i].y = (contour[i-1].y + contour[i].y + contour[i+1].y)/3;
    }
    
    vector<cv::Point> uPoints;
    
    // Step 1：计算每个点与相邻点形成的夹角
    vector<float> angles;
    
    
    int size = int(contour.size());
    
    int step = 5;
    
    for (int i = 0; i < size; i++) {
        int index1 = i - step;
        int index2 = i;
        int index3 = i + step;
        
        index1 = index1 < 0 ? index1 + size : index1;
        index3 = index3 >= size ? index3 - size : index3;
        
        angles.push_back(getAngleWithDirection(contour[index1], contour[index2], contour[index3]));
    }
    
    // Step 2: 计算先变小后变大的点，并记录
    float thresholdAngleMax = 50;
    //float thresholdAngleMin = 0;
    
    for (int i = 0; i < size; i++) {
        int index1 = i - 1;
        int index2 = i;
        int index3 = i+1;
        int index4 = i+step;
        int index5 = i-step;
        index1 = index1 < 0 ? index1+size:index1;
        index3 = index3 >= size? index3-size:index3;
        index5 = index5 < 0 ? index5+size:index5;
        index4 = index4 >= size? index4-size:index4;
        if (angles[index2] < angles[index1] && angles[index2] < angles[index3] && angles[i] > 0 && angles[i] < thresholdAngleMax) {
            
            float dis1 = distanceP2P(contour[i], contour[index4]);
            float dis2 = distanceP2P(contour[index5], contour[i]);
            //NSLog(@"dis:%f,tor:%f",dis,toleranceMin);
            if (dis1 > toleranceMin || dis2 > toleranceMin) {
                uPoints.push_back(contour[i]);
                //NSLog(@"angel:%f",angles[i]);
                
            }
            
        }
    }
    
    return uPoints;
    
}




