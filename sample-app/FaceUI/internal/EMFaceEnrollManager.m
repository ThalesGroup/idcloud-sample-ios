//  MIT License
//
//  Copyright (c) 2019 Thales DIS
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

// IMPORTANT: This source code is intended to serve training information purposes only. Please make sure to review our IdCloud documentation, including security guidelines.

#import "EMFaceEnrollManager.h"
#import "EMFaceManager.h"

@interface EMFaceEnrollManager() {
    int indexOfFrameReceived;
    int nbOfFrameUse;
    BOOL gotFace;
    BOOL userIsReady;
}

@property id<EMFaceAuthEnroller> enroller;
@property EMFaceAuthEnrollerSettings* enrollerSettings;
@property EMFaceAuthFactory* factory;

@end

@implementation EMFaceEnrollManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[EMFaceEnrollManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
       _factory = [[EMFaceManager sharedInstance] factory];
        self.enrollerSettings = [_factory createFaceAuthEnrollerSettings];
        [self updateEnrollerWithSettings];
        userIsReady = NO;
        gotFace = NO;
    }
    return self;
}


- (void)enroller:(id<EMFaceAuthEnroller>)enroller didUpdateFaceAuthFrameEvent:(id<EMFaceAuthFrameEvent>)frameEvent
{
    [super handleUIWithframeReceived:frameEvent];
    
        if(![self containsFaceWithFrameEvent:frameEvent]){
            [[self delegate] stepDidChange:EMFaceUIDelegateStepEnrollWaitFace];
        }else if([self containsFaceWithFrameEvent:frameEvent]){
            if(!userIsReady){
                [[self delegate] stepDidChange:EMFaceUIDelegateStepWaitStart];
            } else {
                [[self delegate] stepDidChange:EMFaceUIDelegateStepAddFace];
            }
        }

}

- (void)startEnrollmentWithDelegate:(id) sender timeout:(NSTimeInterval)timeout completionHandler:(void (^)(EMStatus status)) handler
{
    [self updateEnrollerWithSettings];
    userIsReady = NO;

    self.delegate = sender;
    [self.enroller setFaceAuthEnrollerDelegate:self];
    
    CGFloat previousBrightness = [[UIScreen mainScreen] brightness];
    [[UIScreen mainScreen] setBrightness:1.0f];
    
    /* Timeout is in milliseconds */
    int timeoutMilliseconds = (int)timeout * 1000;
    
    [self.enroller enroll:timeoutMilliseconds withCompletion:(^(BOOL success,id<EMFaceAuthEnroller> callbackEnroller,NSError *error){
        [[UIScreen mainScreen] setBrightness:previousBrightness];
        if( success){
            [[self delegate] stepDidChange:EMFaceUIDelegateStepSuccess];
            handler(EM_STATUS_AUTHENTICATION_FACIAL_SUCCESS);
        }else{
             [[self delegate] stepDidChange:EMFaceUIDelegateStepError];
            handler((EMStatus)[error code]);
        }
         [callbackEnroller removeFaceAuthEnrollerDelegate];
    })];
}

- (void) cancelFaceOperation {
    [self.enroller cancel];
    [[self delegate] stepDidChange:EMFaceUIDelegateStepCancel];
    [self.enroller removeFaceAuthEnrollerDelegate];
}

/* Start and End of Capturing Process */
- (void)enrollerDidStartCapturing:(id<EMFaceAuthEnroller>)enroller{
        [self stepDidChange:EMFaceUIDelegateStepEnrollWaitFace];
    
}

/* End of Capturing Process */
- (void)enrollerDidEndCapturing:(id<EMFaceAuthEnroller>)enroller{
    [self stepDidChange:EMFaceUIDelegateStepProcessing];
    userIsReady = NO;
}


/* Confirm if face to be added */
- (BOOL)enroller:(id<EMFaceAuthEnroller>)enroller shouldAddFaceEvent:(id<EMFaceAuthFrameEvent>)frameEvent withIndex:(NSUInteger)index{
    
    BOOL shouldCapture = [self containsFaceWithFrameEvent:frameEvent] && userIsReady;
    if (shouldCapture) {
        return YES;
    }
    
    userIsReady = NO;
    
    return NO;
}

/*  Unenrolled */
- (void) unenrollWithCompletionHandler:(void(^)(BOOL success, NSError *error))completion{
    [self.enroller unenrollWithCompletion:^(BOOL unenrollSuccess,NSError *error){
        completion(unenrollSuccess,error);
        self->userIsReady = NO;
    }];
}


-(void)userIsReady{
    userIsReady = YES;
}

- (void) updateEnrollerWithSettings {
    [self.enrollerSettings setQualityThreshold:[[EMFaceSettings sharedInstance] qualityThreshold]];
    [self.enrollerSettings setLivenessThreshold:[[EMFaceSettings sharedInstance] livenessThreshold]];
    [self.enrollerSettings setNumberOfFramesToEnroll:[[EMFaceSettings sharedInstance] numberOfFramesToEnroll]];
    [self.enrollerSettings setCountdownToCapture:0];
    self.enroller = [_factory createFaceAuthEnrollerWithSettings:_enrollerSettings];
}


#pragma mark - EMFaceAuthLicenseBuilderDelegate

- (BOOL)licenseBuilderShouldFetchLicenseFromServer:(EMFaceAuthLicenseBuilder *)licenseBuilder
{
    return YES;
}

- (void)licenseBuilderWillStartFetchingLicenseFromServer:(EMFaceAuthLicenseBuilder *)licenseBuilder
{
    [(id<EMFaceAuthLicenseBuilderDelegate>)self.delegate licenseBuilderWillStartFetchingLicenseFromServer:licenseBuilder];
}
- (void)licenseBuilder:(EMFaceAuthLicenseBuilder *)licenseBuilder didEndFetchingLicenseWithStatus:(BOOL)status error:(NSError *)error
{
    [(id<EMFaceAuthLicenseBuilderDelegate>)self.delegate licenseBuilder:licenseBuilder didEndFetchingLicenseWithStatus:status error:error];
}


@end
