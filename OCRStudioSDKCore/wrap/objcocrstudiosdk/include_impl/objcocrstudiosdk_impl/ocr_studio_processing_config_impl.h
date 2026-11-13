/**
  Copyright (c) 2024-2026, OCR Studio
  All rights reserved.
*/

#ifndef OBJCOCRSTUDIOSDK_IMPL_OCR_STUDIO_PROCESSING_CONFIG_H_INCLUDED
#define OBJCOCRSTUDIOSDK_IMPL_OCR_STUDIO_PROCESSING_CONFIG_H_INCLUDED

#include <ocrstudiosdk/ocr_studio_processing_config.h>

#import <objcocrstudiosdk/ocr_studio_processing_config.h>


@interface OBJCOCRStudioSDKProcessingConfig (Internal)

- (instancetype) initFromInternalOCRStudioSDKProcessingConfig:(ocrstudio::OCRStudioSDKProcessingConfig *) config;
- (const ocrstudio::OCRStudioSDKProcessingConfig &) getInternalOCRStudioSDKProcessingConfig;

@end

@interface OBJCOCRStudioSDKProcessingConfigRef (Internal)

- (instancetype) initFromInternalOCRStudioSDKProcessingConfigPointer:(ocrstudio::OCRStudioSDKProcessingConfig *) configptr;
- (ocrstudio::OCRStudioSDKProcessingConfig *) getInternalOCRStudioSDKProcessingConfigPointer;


@end


#endif // OBJCOCRSTUDIOSDK_IMPL_OCR_STUDIO_IMAGE_H_INCLUDED
