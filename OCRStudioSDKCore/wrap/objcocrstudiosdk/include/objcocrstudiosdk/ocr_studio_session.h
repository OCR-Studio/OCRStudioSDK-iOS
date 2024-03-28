/**
  Copyright (c) 2024-2024, OCR Studio
  All rights reserved.
*/

#ifndef OBJCOCRSTUDIOSDK_OCR_STUDIO_SESSION_H_INCLUDED
#define OBJCOCRSTUDIOSDK_OCR_STUDIO_SESSION_H_INCLUDED

#import <objcocrstudiosdk/ocr_studio_image.h>
#import <objcocrstudiosdk/ocr_studio_result.h>

#import <Foundation/Foundation.h>

@interface OBJCOCRStudioSDKSession : NSObject

- (nonnull NSString *) description;

- (void) processImage:(nonnull OBJCOCRStudioSDKImageRef *)image;

- (nonnull OBJCOCRStudioSDKResultRef *) currentResult;

- (void) reset;

@end

#endif // OBJCOCRSTUDIOSDK_OCR_STUDIO_SESSION_H_INCLUDED
