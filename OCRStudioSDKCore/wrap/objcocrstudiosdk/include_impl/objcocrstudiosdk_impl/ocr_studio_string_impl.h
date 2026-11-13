/**
  Copyright (c) 2024-2026, OCR Studio
  All rights reserved.
*/

#ifndef OBJCOCRSTUDIOSDK_IMPL_OCR_STUDIO_STRING_H_INCLUDED
#define OBJCOCRSTUDIOSDK_IMPL_OCR_STUDIO_STRING_H_INCLUDED

#import <objcocrstudiosdk/ocr_studio_string.h>

#include <ocrstudiosdk/ocr_studio_string.h>


@interface OBJCOCRStudioSDKString (Internal)

- (instancetype) initFromInternalOCRStudioSDKString:(const ocrstudio::OCRStudioSDKString &)string;
- (const ocrstudio::OCRStudioSDKString &) getInternalOCRStudioSDKString;

@end

#endif // OBJCOCRSTUDIOSDK_IMPL_OCR_STUDIO_STRING_H_INCLUDED
