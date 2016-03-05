


#import "video+OpenCV.h"
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/opencv.hpp>
#import "helper.h"

@interface  CVCamera()<CvVideoCameraDelegate>

@property (nonatomic,strong) CvVideoCamera *videoCamera;
@property (nonatomic, assign) float angle ;
@property (nonatomic, assign) CGFloat power;

@property (nonatomic,strong) UIImageView *tempImage;

@end



@implementation CVCamera

-(NSData *)hexString:(NSString *)hexString {
    int j=0;
    Byte bytes[20];
    ///3ds key的Byte 数组， 128位
    for(int i=0; i<[hexString length]; i++)
    {
        int int_ch;  /// 两位16进制数转化后的10进制数
        
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1-87)*16; //// a 的Ascll - 97
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2-87; //// a 的Ascll - 97
        
        int_ch = int_ch1+int_ch2;
//        NSLog(@"int_ch=%d",int_ch);
        bytes[j] = int_ch;  ///将转化后的数放入Byte数组里
        j++;
    }
    
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:20];
    
    return newData;
}


- (instancetype)initWithCameraView:(UIImageView *)view{
    self = [super init];
    if (self) {
        self.videoCamera = [[CvVideoCamera alloc] initWithParentView:view];
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
        self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoCamera.defaultFPS = 30;
        self.videoCamera.grayscaleMode = NO;
        self.videoCamera.delegate = self;
//        self.fingerTipsNum = -1;
    }
    
    return self;
}
- (void)startCapture{
    [self.videoCamera start];
}

- (void)viewDidLoad {
//    [self.videoCamera start];
}

- (void)processImage:(cv::Mat &)image
{
    [self handDetectionWithImage:image];
}
-(void)handDetectionWithImage:(cv::Mat &)image{
    
    cv::Mat HLSimage;
    cv::Mat blurImage;
    // Step 1.1:模糊处理
    //medianBlur(image, blurImage, 5);
    // Step 1.2:转换为HLS颜色
    cvtColor(image, HLSimage, CV_BGR2HLS);
    // Step 1.3:根据皮肤颜色范围获取皮肤区域：
    
    
    int imageRow = HLSimage.rows;
    int imageCol = HLSimage.cols;
    
    for (int row = 0; row < imageRow; row++) {
        for (int col = 0; col < imageCol; col++) {
            uchar H = HLSimage.at<cv::Vec3b>(row,col)[0];
            uchar L = HLSimage.at<cv::Vec3b>(row,col)[1];
            uchar S = HLSimage.at<cv::Vec3b>(row,col)[2];
            double LS_ratio = ((double) L) / ((double) S);
            bool skin_pixel = (S >= 50) && (LS_ratio > 0.5) && (LS_ratio < 3.0) && ((H <= 14) || (H >= 165));
            if (!skin_pixel) {
                HLSimage.at<cv::Vec3b>(row,col)[0] = 0;
                HLSimage.at<cv::Vec3b>(row,col)[1] = 0;
                HLSimage.at<cv::Vec3b>(row,col)[2] = 0;
                
            }
        }
    }
    // Step 1.4: 转换为RGB
    cv::Mat skinImage;
    cvtColor(HLSimage, skinImage, CV_HLS2RGB);
    
    // Step 1.5: 对皮肤区域进行二值及平滑处理
    cv::Mat gray;
    cvtColor(skinImage, gray, CV_RGB2GRAY);
    cv::Mat binary;
    threshold(gray, binary, 50, 255, cv::THRESH_BINARY);
    
    // Step 2.1:转换为YUV
    cv::Mat yuvImage;
    cvtColor(image, yuvImage, CV_BGR2YUV);
    // Step 2.2:取出U分量
    std::vector<cv::Mat> yuvImages;
    split(yuvImage, yuvImages);
    
    cv::Mat& uImage = yuvImages[1];
    
    // Step 2.3: 形态学梯度操作
    cv::Mat structure_element(5, 5, CV_8U, cvScalar(1));
    morphologyEx(uImage, uImage, cv::MORPH_GRADIENT, structure_element);
    threshold(uImage, uImage, 10, 255, cv::THRESH_BINARY_INV|cv::THRESH_OTSU);
    medianBlur(binary, binary, 5);
    //morphologyEx( binary, binary, MORPH_CLOSE,Mat());
    //morphologyEx( binary, binary, MORPH_OPEN,Mat());
    
    for (int row = 0; row < imageRow; row++) {
        for (int col = 0; col < imageCol; col++) {
            binary.at<uchar>(row,col) = uImage.at<uchar>(row,col) & binary.at<uchar>(row,col);
        }
    }
    
    // Step 3.1：寻找轮廓
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    findContours( binary, contours, hierarchy,
                 CV_RETR_TREE, CV_CHAIN_APPROX_NONE );
    
    // Step 3.2：找到最大轮廓
    int indexOfBiggestContour = -1;
    int sizeOfBiggestContour = 0;
    for (int i = 0; i < contours.size(); i++){
        if(contours[i].size() > sizeOfBiggestContour){
            sizeOfBiggestContour = int(contours[i].size());
            indexOfBiggestContour = i;
        }
    }
    
    // Step 3.3：检查轮廓，获取手的信息
    if(indexOfBiggestContour > -1 && sizeOfBiggestContour > 400)
    {
        
        // 获取轮廓多边形
        approxPolyDP(cv::Mat(contours[indexOfBiggestContour]), contours[indexOfBiggestContour], 1.5, true);
        // 获取轮廓矩形框
        cv::Rect rect = boundingRect(cv::Mat(contours[indexOfBiggestContour]));
        cv::RotatedRect rotatedRect = fitEllipse(cv::Mat(contours[indexOfBiggestContour]));
        
        _angle = rotatedRect.angle;
        _power = rotatedRect.size.height/rotatedRect.size.width;
        //NSLog(@"power:%f angle:%f\n",power,angle);
        
        //ellipse(image, rotatedRect, Scalar(0,0,200));
        cv::Point2f rect_points[4];
        rotatedRect.points( rect_points );
        for( int j = 0; j < 4; j++ )
            line( image, rect_points[j], rect_points[(j+1)%4], cvScalar(0,0,200), 1, 8 );
        
        cv::Mat temp = binary;
        
        cv::Rect saveRect;
        
        if (rect.width > rect.height) {
            saveRect = cv::Rect(rect.x,rect.y -(rect.width/2 - rect.height/2),rect.width,rect.width);
        } else {
            saveRect = cv::Rect(rect.x - (rect.height/2 - rect.width/2),rect.y,rect.height,rect.height);
        }
        
        //tempRect = CGRectMake(saveRect.x, saveRect.y, saveRect.width, saveRect.height);
        
        
        
        if (saveRect.x >= 0 && saveRect.y >= 0 && saveRect.x+saveRect.width <= temp.cols && saveRect.y+saveRect.height <= temp.rows) {
            
            cv::Mat ROIImage;
            ROIImage = temp(saveRect);
            CvSize size(96,96);
            resize(ROIImage, ROIImage, size);
            
            //            _tempImage = [self UIImageFromCVMat:ROIImage];
            rectangle(image, saveRect.tl(), saveRect.br(), cvScalar(0,0,200));
            
        }
        
        // 在image中画出轮廓
        drawContours(image, contours, indexOfBiggestContour, cvScalar(255,100,100));
        
        
        // 检测手指
        
        std::vector<cv::Point> uPoints;
        uPoints = detectUcurveWithContour(contours[indexOfBiggestContour]);
        for (int i = 0; i < uPoints.size(); i++) {
            circle(image,uPoints[i], 3, cvScalar(100,255,255), 2);
        }
        _fingerTipsNum = (int)uPoints.size();
//        NSLog(@"%d",_fingerTipsNum);
         [[NSNotificationCenter defaultCenter] postNotificationName:@"fingerNumber" object:self];
    }
}





@end











