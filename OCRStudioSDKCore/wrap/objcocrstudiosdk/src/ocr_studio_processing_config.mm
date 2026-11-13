/**
  Copyright (c) 2024-2026, OCR Studio
  All rights reserved.
*/

#import <objcocrstudiosdk_impl/ocr_studio_processing_config_impl.h>
#import <objcocrstudiosdk_impl/ocr_studio_proxy_impl.h>

#include <ocrstudiosdk/ocr_studio_exception.h>

#include <memory>

@implementation OBJCOCRStudioSDKProcessingConfig {
    std::unique_ptr<ocrstudio::OCRStudioSDKProcessingConfig> internal;
}

- (instancetype) initFromInternalOCRStudioSDKProcessingConfig:(ocrstudio::OCRStudioSDKProcessingConfig *)config {
  if (self = [super init]) {
    internal.reset(config);
  }
  return self;
}

- (const ocrstudio::OCRStudioSDKProcessingConfig &) getInternalOCRStudioSDKProcessingConfig {
  return *internal;
}

- (instancetype) initFromJSON:(NSString *) json_path {
  try {
    
    if (self = [super init]) {
      internal.reset(ocrstudio::OCRStudioSDKProcessingConfig::CreateFromJSON([json_path UTF8String]));
    }
    return self;
  } catch (const ocrstudio::OCRStudioSDKException& e){
      printf("Exception thrown: %s\n", e.Message());
      return nil;
  }
}


- (instancetype) initFromBuffer:(nonnull unsigned char *) data
                 withBufferSize:(int) buf_size {
  try {
    
    if (self = [super init]) {
      internal.reset(ocrstudio::OCRStudioSDKProcessingConfig::CreateFromBuffer(data, buf_size));
    }
    return self;
  } catch (const ocrstudio::OCRStudioSDKException& e){
      printf("Exception thrown: %s\n", e.Message());
      return nil;
  }
}

- (OBJCOCRStudioSDKProcessingConfigRef *) getRef {
  return [[OBJCOCRStudioSDKProcessingConfigRef alloc]
          initFromInternalOCRStudioSDKProcessingConfigPointer:internal.get()];
}

@end

@implementation OBJCOCRStudioSDKProcessingConfigRef {
  ocrstudio::OCRStudioSDKProcessingConfig* ptr;
}

- (instancetype) initFromInternalOCRStudioSDKProcessingConfigPointer:(ocrstudio::OCRStudioSDKProcessingConfig *) configptr
                                        {
  if (self = [super init]) {
    ptr = configptr;
  }
  return self;
}

- (ocrstudio::OCRStudioSDKProcessingConfig *) getInternalOCRStudioSDKProcessingConfigPointer {
  return ptr;
}

@end
