/**
  Copyright (c) 2024-2026, OCR Studio
  All rights reserved.
*/

#import <objcocrstudiosdk_impl/ocr_studio_string_impl.h>

#include <ocrstudiosdk/ocr_studio_string.h>
#include <ocrstudiosdk/ocr_studio_exception.h>

#include <memory>

@implementation OBJCOCRStudioSDKString {
  std::unique_ptr<ocrstudio::OCRStudioSDKString> internal;
}

- (instancetype) initFromInternalOCRStudioSDKString:(const ocrstudio::OCRStudioSDKString &)string {
  if (self = [super init]) {
    internal.reset(new ocrstudio::OCRStudioSDKString(string));
    ;
  }
  return self;
}

- (const ocrstudio::OCRStudioSDKString&) getInternalOCRStudioSDKString {
    return *internal;
}

- (instancetype) init {
  if (self = [super init]) {
    internal.reset(new ocrstudio::OCRStudioSDKString);
  }
  return self;
}

- (nonnull instancetype) initWithString:(nonnull NSString *)string {
  if (self = [super init]) {
    internal.reset(new ocrstudio::OCRStudioSDKString([string UTF8String]));
  }
  return self;
}

- (NSString *) getString {
  try {
    return [NSString stringWithUTF8String:internal->CStr()];
  } catch (const ocrstudio::OCRStudioSDKException& e) {
    printf("Exception thrown: %s\n", e.Message());
  }
  return nil;
}

@end
