//  MIT License
//
//  Copyright (c) 2020 Thales DIS
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

// IMPORTANT: This source code is intended to serve training information purposes only.
//            Please make sure to review our IdCloud documentation, including security guidelines.

#import "EMFaceVerifyManager.h"
#import "EMFaceManager.h"

@interface EMFaceVerifyManager() {
    BOOL didAskToBlink;
    BOOL didBlink;
    BOOL gotFace;
    EMFaceAuthLivenessAction previousAction;
}

    @property EMFaceAuthVerifierSettings *verifSettings;
    @property id<EMFaceAuthVerifier> verifier;
    @property id<EMFaceAuthInput> faceAuthInput;
    @property NSError * faceAuthError;
    @property EMFaceAuthFactory * factory;
@end

@implementation EMFaceVerifyManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[EMFaceVerifyManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _factory = [[EMFaceManager sharedInstance] factory];
        self.verifSettings = [_factory createFaceAuthVerifierSettings];
        [self updateVerifierWithSettings];
    }

    return self;
}

- (void)verifier:(id<EMFaceAuthVerifier>)verifier didUpdateFaceAuthFrameEvent:(id<EMFaceAuthFrameEvent>)frameEvent
{
    [super handleUIWithframeReceived:frameEvent];
    
    EMFaceAuthLivenessAction currentAction =[frameEvent livenessAction];
    
    bool nowHaveFace = [self containsFaceWithFrameEvent:frameEvent];

    if (!nowHaveFace){
        [self stepDidChange:EMFaceUIDelegateStepVerifyWaitFace];
    } else {
        if(currentAction==EMFaceAuthLivenessActionBlink){
            [self stepDidChange:EMFaceUIDelegateStepBlink];
        }else if(currentAction==EMFaceAuthLivenessActionKeepStill){
            [self stepDidChange:EMFaceUIDelegateStepKeepStill];
        } else {
            [self stepDidChange:EMFaceUIDelegateStepProcessing];
        }
    }
}

- (void) verifyWithAuthenticable:(id<EMAuthenticatable>)authenticatable
                        delegate:(id<EMFaceAuthUIDelegate>)delegate
                         timeout:(NSTimeInterval)timeout
                      completion:(void (^)(id<EMFaceAuthInput> authInput,NSError *error))completion;
{
    [self updateVerifierWithSettings];
    [self stepDidChange:EMFaceUIDelegateStepVerifyWaitFace];
    gotFace = NO;
    previousAction = EMFaceAuthLivenessActionNoLiveAction;
    
    self.delegate = delegate;
    [self.verifier setFaceAuthVerifierDelegate:self];
    CGFloat previousBrightness = [[UIScreen mainScreen] brightness];
    [[UIScreen mainScreen] setBrightness:1.0f];
    
    int timeoutMilliSeconds = (int)timeout * 1000;
    
    [self.verifier authenticateUser:authenticatable
                        withTimeOut:timeoutMilliSeconds
                  completionHandler:^(id<EMFaceAuthInput> faceAuthInput, NSError *authError){
                      [self.verifier removeFaceAuthVerifierDelegate];
                      self.delegate = nil;
                      completion(faceAuthInput,authError);
                      [[UIScreen mainScreen] setBrightness:previousBrightness];
                  }];
}

- (void) cancelFaceOperation
{
    [self.verifier cancel];
    [self.verifier removeFaceAuthVerifierDelegate];
    self.delegate = nil;
}

- (void) updateVerifierWithSettings {
    [self.verifSettings setFaceCaptureMode:[[EMFaceSettings sharedInstance] verifierFaceCaptureMode]];
    [self.verifSettings setQualityThreshold:[[EMFaceSettings sharedInstance] qualityThreshold]];
    [self.verifSettings setLivenessThreshold:[[EMFaceSettings sharedInstance] livenessThreshold]];
    [self.verifSettings setMatchingThreshold:[[EMFaceSettings sharedInstance] matchingThreshold]];
    [self.verifSettings setLivenessBlinkTimeout:[[EMFaceSettings sharedInstance] livenessBlinkTimeout]];
    self.verifier = [_factory createFaceAuthVerifierWithSettings:_verifSettings];
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
