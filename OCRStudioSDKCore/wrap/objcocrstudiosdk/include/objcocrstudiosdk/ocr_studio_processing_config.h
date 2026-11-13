/**
  Copyright (c) 2024-2026, OCR Studio
  All rights reserved.
*/

#ifndef OBJCOCRSTUDIOSDK_OCR_STUDIO_PROCESSING_CONFIG_H_INCLUDED
#define OBJCOCRSTUDIOSDK_OCR_STUDIO_PROCESSING_CONFIG_H_INCLUDED

#import <Foundation/Foundation.h>

@interface OBJCOCRStudioSDKProcessingConfigRef : NSObject

@end


@class OBJCOCRStudioSDKProcessingConfig;

@interface OBJCOCRStudioSDKProcessingConfig : NSObject

- (nonnull instancetype) initFromJSON:(nonnull NSString *) json_path;

- (nonnull instancetype) initFromBuffer:(nonnull unsigned char *) data
                         withBufferSize:(int) buf_size;

- (nonnull OBJCOCRStudioSDKProcessingConfigRef *) getRef;

@end



#endif // OBJCOCRSTUDIOSDK_OCR_STUDIO_PROCESSING_CONFIG_H_INCLUDED
