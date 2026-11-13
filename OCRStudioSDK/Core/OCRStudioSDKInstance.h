/**
  Copyright (c) 2024-2026, OCR Studio
  All rights reserved.
*/

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#import <objcocrstudiosdk/ocr_studio_result.h>
#import <objcocrstudiosdk/ocr_studio_instance.h>
#import <objcocrstudiosdk/ocr_studio_image.h>

@protocol OCRStudioSDKDelegate <NSObject>
@optional
- (void) OCRStudioSDKObtainedResult:(nonnull OBJCOCRStudioSDKResult *)result
            fromFrameWithBuffer:(nonnull CMSampleBufferRef)buffer;
- (void) OCRStudioSDKObtainedMessage:(nonnull NSString *)json_message;
- (void) OCRStudioSDKObtainedSingleImageResult:(nonnull OBJCOCRStudioSDKResult *)result;
- (void) OCRStudioSDKObtainedFaceComparisonResult:(nonnull OBJCOCRStudioSDKResult *)result;
- (void) OCRStudioSDKSessionEnded;
@end

@protocol OCRStudioSDKInitializationDelegate <NSObject>
@optional
- (void) OCRStudioSDKInitialized;
- (void) OCRStudioSDKVideoSessionStarted;
- (void) OCRStudioSDKVideoSessionDismissed;
@end

@interface OCRStudioSDKSessionParameters : NSObject

@property (nonatomic, readonly, copy, nullable) NSString *sessionType;
@property (nonatomic, readonly, copy, nullable) NSString *targetGroupType;
@property (nonatomic, readonly, copy, nullable) NSArray<NSString *> *targetMasks;
@property (nonatomic, readonly, copy, nullable) NSArray<NSString *> *outputModes;
@property (nonatomic, readonly, strong, nullable) NSMutableDictionary *options;
@property (nonatomic, readonly) BOOL isTwoSideAvailable;
@property (nonatomic, readonly) BOOL isTwoSideEnabled;

- (nonnull NSString *)jsonString;

- (void)setSessionType:(nonnull NSString *)sessionType;

- (void)setTargetGroupType:(nonnull NSString *)targetGroupType;
- (void)setTargetMasks:(nonnull NSArray<NSString *>*)targetMasks;
- (void)addTargetMask:(nonnull NSString *)targetMask;
- (void)clearTargetMasks;

- (nonnull NSString *)getSessionType;
- (nonnull NSString *)getTargetGroupType;
- (nonnull NSArray<NSString *>*)getTargetMasks;

- (void)setOptionWithName:(nonnull NSString *)name
                        to:(nonnull NSString *)value;
- (void)removeOptionWithName:(nonnull NSString *)name;
- (void)clearOptions;

- (void)setTwoSidesAvailability:(BOOL)isTwoSideAvailable;
- (BOOL)getTwoSidesAvailability;

- (void)setWithTwoSides:(BOOL)isTwoSideEnabled;
- (BOOL)getWithTwoSides;

@end

@interface OCRStudioSDKInstance : NSObject

@property (weak, nonatomic, nullable, readonly) id<OCRStudioSDKDelegate> engineDelegate;
@property (weak, nonatomic, nullable, readonly) id<OCRStudioSDKInitializationDelegate> initializationDelegate;

@property (strong, nullable, readonly) OBJCOCRStudioSDKInstance* engine; // main configuration of OCRStudioSDK Engine
@property (strong, nullable, readonly) OBJCOCRStudioSDKSession* session; // current video recognition session
@property (strong, nullable)  OCRStudioSDKSessionParameters* session_params; // current session params
@property (strong, nullable) OBJCOCRStudioSDKProcessingConfig* processingConfig; // session config

@property BOOL engineInitialized;
@property BOOL videoSessionRunning;
@property BOOL sessionEnded;
@property (nonatomic, strong, nullable) NSString * currentInstruction;

- (nonnull instancetype) initWithSignature:(nonnull NSString *)signature;
- (void) setEngineDelegate:(nullable __weak id<OCRStudioSDKDelegate>)delegate;
- (void) setInitializationDelegate:(nullable __weak id<OCRStudioSDKInitializationDelegate>)delegate;

- (void) initializeEngine:(nonnull NSString *)configPath;

- (void) initVideoSession;

- (void) dismissVideoSession;
- (void) dismissVideoSessionRunning;

- (void) processFrame:(nonnull CMSampleBufferRef)sampleBuffer
      withOrientation:(UIDeviceOrientation)deviceOrientation;

- (void) processFrame:(nonnull CMSampleBufferRef)sampleBuffer
      withOrientation:(UIDeviceOrientation)deviceOrientation
               andRoi:(CGRect)roi;

- (nonnull OBJCOCRStudioSDKResult *) processSingleImage:(nonnull OBJCOCRStudioSDKImageRef *)image;
- (nonnull OBJCOCRStudioSDKResult *) processSingleImageFromFile:(nonnull NSString *)filePath;
- (nonnull OBJCOCRStudioSDKResult *) processSingleImageFromUIImage:(nonnull UIImage *)image
                                                         rotations:(int)rotations;

- (nonnull OBJCOCRStudioSDKResult *) processData:(nonnull NSString *)data;
- (nonnull OBJCOCRStudioSDKResult *) processSelfie:(nonnull UIImage *)image;

- (nonnull OBJCOCRStudioSDKResult *) compareFacesFromDocument:(nonnull OBJCOCRStudioSDKImageRef *)photo
                                                    andSelfie:(nonnull OBJCOCRStudioSDKImageRef *)image;

@end

