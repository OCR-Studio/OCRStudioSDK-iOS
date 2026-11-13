/**
  Copyright (c) 2024-2026, OCR Studio
  All rights reserved.
*/

/**
 * @file ocr_studio_processing_config.h
 * @brief ocrstudiosdk CONFIG
 */

#pragma once
#ifndef OCRSTUDIOSDK_OCR_STUDIO_PROCESSING_CONFIG_H_INCLUDED
#define OCRSTUDIOSDK_OCR_STUDIO_PROCESSING_CONFIG_H_INCLUDED

#include <ocrstudiosdk/ocr_studio_export.h>

namespace ocrstudio {


/**
 * @brief Class representing the config for interactive processing
 */
class OCR_STUDIO_SDK_DLL_EXPORT OCRStudioSDKProcessingConfig {
public:
  /// Default destructor
  virtual ~OCRStudioSDKProcessingConfig() = default;

  /**
   * @brief Creates a processing config from file
   * @param json_path - path to an config file (json)
   * @return Pointer to a new OCRStudioSDKProcessingConfig, the ownership is relinquished.
   */
  static OCRStudioSDKProcessingConfig* CreateFromJSON(
      const char* json_path);

  /**
   * @brief Creates a processing config from a buffer
   * @param data - pointer to a buffer
   * @param size - size of the buffer
   * @return Pointer to a new OCRStudioSDKProcessingConfig, the ownership is relinquished.
   */
  static OCRStudioSDKProcessingConfig* CreateFromBuffer(
      const unsigned char* data,
      unsigned long        size);

};


} // namespace ocrstudio

#endif // OCRSTUDIOSDK_OCR_STUDIO_PROCESSING_CONFIG_H_INCLUDED
