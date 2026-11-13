/**
  Copyright (c) 2024-2026, OCR Studio
  All rights reserved.
*/

#import "OCRStudioSDKInstance.h"

@implementation OCRStudioSDKSessionParameters

- (instancetype)init {
    self = [super init];
  if (self) {
    _sessionType = @"document_recognition";
    _targetGroupType = @"default";
    _targetMasks = @[];
    _outputModes = @[@"field_geometry"]; // @"text_line_iterator" @"character_alternatives"
    _options = @{};
    _isTwoSideAvailable = NO;
    _isTwoSideEnabled = NO;
  }
    return self;
}

- (NSString *)jsonString {
  NSDictionary *dictionary = @{
    @"session_type" : self.sessionType ?: [NSNull null],
    @"target_group_type" : self.targetGroupType ?: [NSNull null],
    @"target_masks" : self.targetMasks ?: @[],
    @"output_modes" : self.outputModes ?: @[],
    @"options": self.options ?: @{}
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

- (void)setSessionType:(NSString *)sessionType{
  _sessionType = sessionType;
}

- (void)setTargetGroupType:(NSString *)targetGroupType {
  _targetGroupType = targetGroupType;
}

- (void)setTargetMasks:(NSArray<NSString *>*)targetMasks{
  _targetMasks = targetMasks;
}

- (void)addTargetMask:(NSString *)targetMask{
  if (!_targetMasks) {
    _targetMasks = [NSArray arrayWithObject:targetMask];
  } else {
    NSMutableArray *updatedTargetMasks = [_targetMasks mutableCopy];
    [updatedTargetMasks addObject:targetMask];
    _targetMasks = [updatedTargetMasks copy];
  }
}

- (void)clearTargetMasks{
  _targetMasks = @[];
}

- (nonnull NSString *)getSessionType{
  return _sessionType;
}

- (nonnull NSString *)getTargetGroupType {
  return _targetGroupType;
}

- (nonnull NSArray<NSString *>*)getTargetMasks{
  return _targetMasks;
}

- (void)setOptionWithName:(nonnull NSString *)name
                       to:(nonnull NSString *)value {
  if (!self.options) {
    _options = [NSMutableDictionary dictionary];
  }
  _options[name] = value;
}
- (void)removeOptionWithName:(nonnull NSString *)name {
  [_options removeObjectForKey:name];
}

- (void)clearOptions{
  _options = [NSMutableDictionary dictionary];
}

- (void)setTwoSidesAvailability:(BOOL)isTwoSideAvailable {
  _isTwoSideAvailable = isTwoSideAvailable;
}
- (BOOL)getTwoSidesAvailability {
  return _isTwoSideAvailable;
}

- (void)setWithTwoSides:(BOOL)isTwoSideEnabled {
  if (!_isTwoSideAvailable && isTwoSideEnabled) {
    NSLog(@"Two Side Mode does not available");
    return;
  }
  _isTwoSideEnabled = isTwoSideEnabled;
}
- (BOOL)getWithTwoSides {
  return _isTwoSideEnabled;
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
    [self updateResponseFlags];
  }
  return self;
}

- (void) updateResponseFlags {
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
  
  NSData *jsonData = [json_message dataUsingEncoding:NSUTF8StringEncoding];
  if (jsonData) {
    NSError *error;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (!error) {
      NSDictionary *data = jsonDict[@"data"];
      if ([jsonDict[@"type"]  isEqual: @"instruction"]) {
        self.governor.currentInstruction = data[@"instruction"];
        NSLog(@"instruction: %@", data[@"instruction"]);
      }
      if ([jsonDict[@"type"]  isEqual: @"session_end"]) {
        self.governor.sessionEnded = YES;
        NSLog(@"session_end");
      }
    }
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
  BOOL delegateReceivesFaceComparisonResults;
  
  BOOL delegateReceivesInit;
  BOOL delegateReceivesSessionStarted;
  BOOL delegateReceivesSessionDismissed;
  
  BOOL delegateReceivesSessionEnded;
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
    self.sessionEnded = NO;
    
    // Initializing proxy reporter
    __weak __typeof(self) weakSelf = self;
    proxyReporter = [[ProxyFeedbackReporter alloc] initWithGovernor:weakSelf];
    
    // Initializing delegates cache
    delegateReceivesResults = NO;
    delegateReceivesSingleImageResults = NO;
    delegateReceivesFaceComparisonResults = NO;
    
    delegateReceivesInit = NO;
    delegateReceivesSessionStarted = NO;
    delegateReceivesSessionDismissed = NO;
    
    delegateReceivesSessionEnded = NO;
  }
  return self;
}

- (void) setEngineDelegate:(nullable __weak id<OCRStudioSDKDelegate>)delegate {
  _engineDelegate = delegate;
  delegateReceivesResults = NO;
  delegateReceivesSingleImageResults = NO;
  delegateReceivesFaceComparisonResults = NO;
  if (self.engineDelegate) {
    delegateReceivesResults =
        [self.engineDelegate respondsToSelector:@selector(OCRStudioSDKObtainedResult:fromFrameWithBuffer:)];
    delegateReceivesSingleImageResults =
        [self.engineDelegate respondsToSelector:@selector(OCRStudioSDKObtainedSingleImageResult:)];
    delegateReceivesFaceComparisonResults = 
        [self.engineDelegate respondsToSelector:@selector(OCRStudioSDKObtainedFaceComparisonResult:)];
    
    [proxyReporter updateResponseFlags];
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

- (void) initializeEngine:(nonnull NSString*) configPath {
  self.engine = [[OBJCOCRStudioSDKInstance alloc] initFromPath:configPath
                                 withJsonInstanceInitParams:@"{\"enable_lazy_initialization\": true,\"enable_delayed_initialization\": false}"];
  
  self.session_params = [[OCRStudioSDKSessionParameters alloc] init];
  
  self.session = nil;
  self.videoSessionRunning = NO;
  
  self.engineInitialized = YES;
  
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"KYC_config" ofType:@"json"];
  if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    self.processingConfig = [[OBJCOCRStudioSDKProcessingConfig alloc] initFromJSON: filePath];
    [self.session_params setTwoSidesAvailability:YES];
  } else {
      NSLog(@"KYC_config not found");
    [self.session_params setTwoSidesAvailability:NO];
  }
  
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

  NSLog(@"video session params %@", session_params.jsonString);
  
  @synchronized (self.session) {
    [self.session reset];
    self.session = [self.engine
                    createSession: self.signature
                    withJsonSessionParams: session_params.jsonString
                    withDelegate: proxyReporter];
    if (session_params.isTwoSideEnabled) {
      [self.session registerConfig: [self.processingConfig getRef]];
    }
    NSLog(@"Session description:");
    NSLog(@"%@", [self.session description]);
    NSLog(@"With two side:%@", session_params.isTwoSideEnabled ? @"YES" : @"NO");

    self.videoSessionRunning = YES;
    self.sessionEnded = NO;
      
    if (delegateReceivesSessionStarted) {
      [self.initializationDelegate OCRStudioSDKVideoSessionStarted];
    }
  }
}

- (void) dismissVideoSession {
  @synchronized (self.session) {
    self.videoSessionRunning = NO;
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
  session = [self.engine createSession:self.signature
                 withJsonSessionParams:self.session_params.jsonString
                          withDelegate:nil];
  [session processImage:image];
  OBJCOCRStudioSDKResultRef* currentResult = [session currentResult];
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

- (nonnull OBJCOCRStudioSDKResult*) processSingleImageFromUIImage:(nonnull UIImage *)image
                                                        rotations:(int)rotations {
  OBJCOCRStudioSDKImage* proxyImage = [[OBJCOCRStudioSDKImage alloc] initFromUIImage:image];
  OBJCOCRStudioSDKImageRef* imageRef = [proxyImage getMutableRef];
  if (rotations > 0) {
    [imageRef rotateByNinety:rotations];
  }
  return [self processSingleImage:imageRef];
}

- (nonnull OBJCOCRStudioSDKResult*) processData:(nonnull NSString *)data {
  [session processData:data];
  OBJCOCRStudioSDKResultRef* currentResult = [session currentResult];
  OBJCOCRStudioSDKResult* result = [currentResult clone];
  return result;
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

