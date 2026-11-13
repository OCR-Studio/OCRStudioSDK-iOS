/**
  Copyright (c) 2024-2026, OCR Studio
  All rights reserved.
*/

#ifndef OBJCOCRSTUDIOSDK_OCR_STUDIO_STRING_H_INCLUDED
#define OBJCOCRSTUDIOSDK_OCR_STUDIO_STRING_H_INCLUDED

#import <Foundation/Foundation.h>

@interface OBJCOCRStudioSDKString : NSObject

- (nonnull instancetype) init;
- (nonnull instancetype) initWithString:(nonnull NSString *)string;
- (nonnull NSString *) getString;

@end

#endif // OBJCOCRSTUDIOSDK_OCR_STUDIO_STRING_H_INCLUDED
