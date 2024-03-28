/**
  Copyright (c) 2024-2024, OCR Studio
  All rights reserved.
*/

#import "OCRStudioSDKInstance.h"

@implementation OCRStudioSDKSessionParameters

- (instancetype)init {
    self = [super init];
  if (self) {
    _session_type = @"document_recognition";
    _target_group_type = @"autoselection";
    _target_masks = @[];
    _output_modes = @"field_geometry";
    _session_types = @[];
  }
    return self;
}

- (NSString *)jsonString {
    NSDictionary *dictionary = @{
        @"session_type" : self.session_type ?: [NSNull null],
        @"target_group_type" : self.target_group_type ?: [NSNull null],
        @"target_masks" : self.target_masks ?: @[],
        @"output_modes" : self.output_modes ?: [NSNull null]
//        Example to set custom options
//        @"options": @{@"sessionTimeout": @"5.0"}
    };

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    if (!jsonData) {
        NSLog(@"Error creating JSON object: %@", error);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

- (void)initSessionTypesWith:(nonnull NSArray *)session_types {
  _session_types = session_types;
}

- (bool)hasSessionType:(NSString *)session_type{
  return [_session_types containsObject:session_type];
}

- (void)setSessionType:(NSString *)session_type{
  if ([self hasSessionType:session_type]) {
    _session_type = session_type;
  } else {
    NSLog(@"Error: %@ unavailable in current bundle", session_type);
  }
}

- (void)setTargetGroupType:(NSString *)target_group_type {
  _target_group_type = target_group_type;
}

- (void)setTargetMasks:(NSArray<NSString *>*)target_masks{
  _target_masks = target_masks;
}

- (void)addTargetMask:(NSString *)target_mask{
  if (!_target_masks) {
    _target_masks = [NSArray arrayWithObject:target_mask];
  } else {
    NSMutableArray *updatedTargetMasks = [_target_masks mutableCopy];
    [updatedTargetMasks addObject:target_mask];
    _target_masks = [updatedTargetMasks copy];
  }
}

- (void)clearTargetMasks{
  _target_masks = @[];
}

- (nonnull NSString *)getSessionType{
  return _session_type;
}

- (nonnull NSString *)getTargetGroupType {
  return _target_group_type;
}

- (nonnull NSArray<NSString *>*)getTargetMasks{
  return _target_masks;
}

@end


@interface ProxyFeedbackReporter : NSObject <OBJCOCRStudioSDKDelegate>
@property (weak) OCRStudioSDKInstance* governor;

- (instancetype) initWithGovernor:(__weak OCRStudioSDKInstance *)initGovernor;

- (void) callbackWithMessage:(NSString *)json_message;

@end

@implementation ProxyFeedbackReporter {
  BOOL transferJsonMessage;
}

@synthesize governor;

- (instancetype) initWithGovernor:(__weak OCRStudioSDKInstance *)initGovernor {
  if (self = [super init]) {
    governor = initGovernor;
    [self updateResponceFlags];
  }
  return self;
}

- (void) updateResponceFlags {
  transferJsonMessage = NO;
  if (self.governor.engineDelegate) {
    transferJsonMessage = [self.governor.engineDelegate respondsToSelector:@selector(OCRStudioSDKObtainedMessage:)];
  }
}
- (void) callbackWithMessage:(NSString *)json_message {
  if (transferJsonMessage) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.governor.engineDelegate OCRStudioSDKObtainedMessage:json_message];
    });
  }
}

@end

@interface OCRStudioSDKInstance () {
  ProxyFeedbackReporter* proxyReporter;
}

@property NSString* signature;


@property (weak, nonatomic, nullable, readwrite) id<OCRStudioSDKDelegate> engineDelegate;
@property (weak, nonatomic, nullable, readwrite) id<OCRStudioSDKInitializationDelegate> initializationDelegate;

@property (strong, nullable, readwrite) OBJCOCRStudioSDKInstance* engine; // main configuration of OCRStudioSDK Engine
@property (strong, nullable, readwrite) OBJCOCRStudioSDKSession* session; // current video recognition session


@end

@implementation OCRStudioSDKInstance {
  BOOL delegateReceivesResults;
  BOOL delegateReceivesSingleImageResults;
  
  BOOL delegateReceivesInit;
  BOOL delegateReceivesSessionStarted;
  BOOL delegateReceivesSessionDismissed;
}

@synthesize engine, session, session_params;

- (instancetype) init {
  NSException* exc = [NSException
        exceptionWithName:@"SignatureError"
        reason:@"OCRStudioSDKInstance must be created with signature (use initWithSignature:)"
        userInfo:nil];
  @throw exc;
}

- (instancetype) initWithSignature:(NSString *)inputSignature {
  if (self = [super init]) {
    // Storing signature
    self.signature = inputSignature;
    
    self.engineInitialized = NO;
    self.videoSessionRunning = NO;
      
    // Initializing proxy reporter
    __weak __typeof(self) weakSelf = self;
    proxyReporter = [[ProxyFeedbackReporter alloc] initWithGovernor:weakSelf];
    
    // Initializing delegates cache
    delegateReceivesResults = NO;
    delegateReceivesSingleImageResults = NO;
    
    delegateReceivesInit = NO;
    delegateReceivesSessionStarted = NO;
    delegateReceivesSessionDismissed = NO;
      
    
  }
    
  return self;
}

- (void) setEngineDelegate:(nullable __weak id<OCRStudioSDKDelegate>)delegate {
  _engineDelegate = delegate;
  delegateReceivesResults = NO;
  delegateReceivesSingleImageResults = NO;
  if (self.engineDelegate) {
    delegateReceivesResults =
        [self.engineDelegate respondsToSelector:@selector(OCRStudioSDKObtainedResult:fromFrameWithBuffer:)];
    delegateReceivesSingleImageResults =
        [self.engineDelegate respondsToSelector:@selector(OCRStudioSDKObtainedSingleImageResult:)];
    
    [proxyReporter updateResponceFlags];
  }
}

- (void) setInitializationDelegate:(nullable __weak id<OCRStudioSDKInitializationDelegate>)delegate {
  _initializationDelegate = delegate;
  delegateReceivesInit = NO;
  delegateReceivesSessionStarted = NO;
  delegateReceivesSessionDismissed = NO;
  if (self.initializationDelegate) {
    delegateReceivesInit =
        [self.initializationDelegate respondsToSelector:@selector(OCRStudioSDKInitialized)];
    delegateReceivesSessionStarted =
        [self.initializationDelegate respondsToSelector:@selector(OCRStudioSDKVideoSessionStarted)];
    delegateReceivesSessionDismissed =
        [self.initializationDelegate respondsToSelector:@selector(OCRStudioSDKVideoSessionDismissed)];
  }
}

- (void) initializeEngine:(nonnull NSString*) bundlePath {
  self.engine = [[OBJCOCRStudioSDKInstance alloc] initFromPath:bundlePath
                                 withJsonInstanceInitParams:nil];
  
    self.session_params = [[OCRStudioSDKSessionParameters alloc] init];
  
  self.session = nil;
  self.videoSessionRunning = NO;
  
  self.engineInitialized = YES;
  
  if (delegateReceivesInit) {
    [self.initializationDelegate OCRStudioSDKInitialized];
  }
}

- (void) initVideoSession {
  if (!self.engineInitialized) {
    NSException* exc = [NSException
          exceptionWithName:@"OCRStudioSDKInstanceError"
          reason:@"OCRStudioSDKInstance cannot initialize video session while engine is not yet initialized"
          userInfo:nil];
    @throw exc;
  }

  NSLog(@"session params %@", session_params.jsonString);

  
  @synchronized (self.session) {
    self.session = [self.engine
      createSession: self.signature
      withJsonSessionParams: session_params.jsonString
      withDelegate: proxyReporter];

    NSLog(@"Session description:");
    NSLog(@"%@", [self.session description]);
    
    self.videoSessionRunning = YES;
  }

  if (delegateReceivesSessionStarted) {
    [self.initializationDelegate OCRStudioSDKVideoSessionStarted];
  }
}

- (void) dismissVideoSession {
  @synchronized (self.session) {
    self.videoSessionRunning = NO;
    self.session = nil;
  }

  if (delegateReceivesSessionDismissed) {
    [self.initializationDelegate OCRStudioSDKVideoSessionDismissed];
  }
}

- (void) dismissVideoSessionRunning {
  @synchronized (self.session) {
    self.videoSessionRunning = NO;
  }
}

#pragma mark - frame processing

int getRotationsByOrientation(UIDeviceOrientation orientation) {
  int rotations = 0;
  if (orientation == UIDeviceOrientationPortrait) {
    rotations = 1;
  } else if (orientation == UIDeviceOrientationLandscapeRight) {
    rotations = 2;
  } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
    rotations = 3;
  }
  return rotations;
}

- (void) processFrameImage:(OBJCOCRStudioSDKImageRef *)image
                fromBuffer:(CMSampleBufferRef)buffer {
  if (self.videoSessionRunning) {
    OBJCOCRStudioSDKResult* result = nil;
    
    @synchronized (self.session) {
      [self.session processImage:image];
      
      OBJCOCRStudioSDKResultRef* currentResult = [self.session currentResult];
      result = [currentResult clone];
    }
    
    if (self.videoSessionRunning) { // sending callbacks only if the session is still running here
    // processing is performed on video queue so forcing main queue
      if ([NSThread isMainThread]) {
        if (delegateReceivesResults) {
          [self.engineDelegate OCRStudioSDKObtainedResult:result fromFrameWithBuffer:buffer];
        }
      } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
          if (delegateReceivesResults) {
            [self.engineDelegate OCRStudioSDKObtainedResult:result fromFrameWithBuffer:buffer];
          }
        });
      }
    }
  }
}

- (void) processFrame:(CMSampleBufferRef)sampleBuffer
      withOrientation:(UIDeviceOrientation)deviceOrientation {
  if (self.videoSessionRunning) {
    int rotations = getRotationsByOrientation(deviceOrientation);
    
    OBJCOCRStudioSDKImage* imageSource = [[OBJCOCRStudioSDKImage alloc] initFromSampleBuffer:sampleBuffer];
    
    OBJCOCRStudioSDKImageRef* image = [imageSource getMutableRef];
    if (rotations > 0) {
      [image rotateByNinety:rotations];
    }
     
    [self processFrameImage:image fromBuffer:sampleBuffer];
  }
}

- (void) processFrame:(CMSampleBufferRef)sampleBuffer
      withOrientation:(UIDeviceOrientation)deviceOrientation
               andRoi:(CGRect)roi {
  if (self.videoSessionRunning) {
    int rotations = getRotationsByOrientation(deviceOrientation);
    
    OBJCOCRStudioSDKImage* imageSource = [[OBJCOCRStudioSDKImage alloc] initFromSampleBuffer:sampleBuffer];
    
    OBJCOCRStudioSDKImageRef* image = [imageSource getMutableRef];
    if (rotations > 0) {
      [image rotateByNinety:rotations];
    }

    OBJCOCRStudioSDKImage* croppedImage = [image shallowCopyCroppedByRect:roi.origin.x
                                                                 withY:roi.origin.y
                                                             withWidth:roi.size.width
                                                            withHeight:roi.size.height];
    [self processFrameImage:[croppedImage getRef] fromBuffer:sampleBuffer];
  }
}

- (nonnull OBJCOCRStudioSDKResult*) processSingleImage:(nonnull OBJCOCRStudioSDKImageRef *)image {
  NSLog(@"%@", session_params.jsonString);
  OBJCOCRStudioSDKSession* imageSession = [self.engine createSession:self.signature
                                            withJsonSessionParams:self.session_params.jsonString
                                                     withDelegate:nil];
  [imageSession processImage:image];
  OBJCOCRStudioSDKResultRef* currentResult = [imageSession currentResult];
  OBJCOCRStudioSDKResult* result = [currentResult clone];
  
  // processing is performed on video queue so forcing main queue
  if ([NSThread isMainThread]) {
    if (delegateReceivesSingleImageResults) {
      [self.engineDelegate OCRStudioSDKObtainedSingleImageResult:result];
    }
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      if (delegateReceivesResults) {
        [self.engineDelegate OCRStudioSDKObtainedSingleImageResult:result];
      }
    });
  }
  
  return result;
}

- (nonnull OBJCOCRStudioSDKResult*) processSingleImageFromFile:(nonnull NSString *)filePath {
  OBJCOCRStudioSDKImage* image = [[OBJCOCRStudioSDKImage alloc] initFromFile:filePath
                                                        withPageNumber:0
                                                          withMaxWidth:15000
                                                         withMaxHeight:15000];
  return [self processSingleImage:[image getRef]];
}

- (nonnull OBJCOCRStudioSDKResult*) processSingleImageFromUIImage:(nonnull UIImage *)image {
  OBJCOCRStudioSDKImage* proxyImage = [[OBJCOCRStudioSDKImage alloc] initFromUIImage:image];
  return [self processSingleImage:[proxyImage getRef]];
}

- (OBJCOCRStudioSDKResult *) compareFacesFromDocument:(nonnull OBJCOCRStudioSDKImageRef *)photo
                                              andSelfie:(nonnull OBJCOCRStudioSDKImageRef *)image {
  @try {
    
    NSDictionary *face_session_params = @{@"session_type": @"face_matching", @"target_group_type": @"default"};
    NSString *face_session_params_json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:face_session_params options:0 error:nil] encoding:NSUTF8StringEncoding];
    
    OBJCOCRStudioSDKSession* face_session = [engine createSession:self.signature
                                         withJsonSessionParams:face_session_params_json
                                                  withDelegate:nil];
    [face_session processImage:photo];
    [face_session processImage:image];
    return [[face_session currentResult] clone];
  } @catch (NSException *exception) {
    NSLog(@"Exception thrown while comparing faces: %@", exception);
    return nil;
  };
}

@end

