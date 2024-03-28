/**
  Copyright (c) 2024-2024, OCR Studio
  All rights reserved.
*/

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIView.h>

#import "OCRStudioSDKVideoPreviewView.h"

@interface OCRStudioSDKCameraManager : NSObject

@property (atomic) CGSize currentVideoSize;

- (nonnull instancetype) init;
- (nonnull instancetype) initWithCaptureDevicePosition:(AVCaptureDevicePosition)position
                                        WithBestDevice:(BOOL)bestDevice;
- (nonnull instancetype) initWithBestDevice:(BOOL)bestDevice;

- (CGSize) videoSize;

- (void) setSampleBufferDelegate:(nonnull id<AVCaptureVideoDataOutputSampleBufferDelegate>)delegate;
- (void) configurePreview:(nonnull OCRStudioSDKVideoPreviewView *)view;

- (void) startCaptureSession;
- (void) stopCaptureSession;

- (void) focusAtPoint:(CGPoint)point
    completionHandler:(nullable void(^)(void))completionHandler;
- (BOOL) isAdjustingFocus;

- (void) changeSessionPreset:(nonnull AVCaptureSessionPreset)preset;
- (void) updateCaptureSessionPreset;

- (void) turnTorchOnWithLevel:(float)level;
- (void) turnTorchOff;
- (BOOL) isTorchOn;
- (nullable AVCaptureDevice*) getCaptureDevice;

typedef enum {
  sUltrawide,
  sWide,
  sTelephoto
} ZoomState;

@end

