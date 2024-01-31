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

#import "TokenDevice.h"

@implementation TokenDevice

// MARK: - Life Cycle

+ (instancetype)tokenDeviceWithToken:(id<EMOathToken>)token {
    return [[TokenDevice alloc] initWithToken:token];
}

- (id)initWithToken:(id<EMOathToken>)token {
    // Keep instance of device whole time, so we can use otp lifespan (TOTP) value.
    NSError         *error      = nil;
    EMOathFactory   *factory    = [[EMOathService serviceWithModule:[EMOtpModule otpModule]] oathFactory];
    
    // Create device based on specific ocra suite.
    id<EMMutableSoftOathSettings> oathSettings = [factory mutableSoftOathSettings];
    [oathSettings setOcraSuite:CFG_OTP_OCRA_SUITE()];
    id<EMOathDevice> deviceOath = [factory createSoftOathDeviceWithToken:(id<EMSoftOathToken>)token settings:oathSettings error:&error];
    
    if (deviceOath &&  (self = [super init])) {
        _token      = token;
        _device     = deviceOath;
        _lifespan   = oathSettings.totpTimestepSize;
    }
    
    // This operation can't fail, otherwise some settings or internal state is incorrect.
    assert(!error);
    
    return self;
}

// MARK: - Public API

- (TokenStatus)tokenStatus {
    TokenStatus retValue;
    
    // Check all auth mode states so we can enable / disable proper buttons.
    EMAuthModule                        *authMoule          = [EMAuthModule authModule];
    EMSystemBioFingerprintAuthService   *touchService       = [EMSystemBioFingerprintAuthService serviceWithModule:authMoule];
    EMSystemFaceAuthService             *faceService        = [EMSystemFaceAuthService serviceWithModule:authMoule];
    
    retValue.isTouchSupported                   = [touchService isSupported:nil]    && [touchService isConfigured:nil];
    retValue.isFaceSupported                    = [faceService isSupported:nil]     && [faceService isConfigured:nil];
    retValue.isTouchEnabled                     = retValue.isTouchSupported         ? [_token isAuthModeActive:[touchService authMode]]   : NO;
    retValue.isFaceEnabled                      = retValue.isFaceSupported          ? [_token isAuthModeActive:[faceService authMode]]    : NO;
    
    return retValue;
}

- (void)totpWithAuthInput:(id<EMAuthInput>)authInput
        completionHandler:(OTPCompletion)completionHandler {
    [self totpWithAuthInput:authInput withServerChallenge:nil completionHandler:completionHandler];
}

- (void)totpWithAuthInput:(id<EMAuthInput>)authInput
      withServerChallenge:(id<EMSecureString>)serverChallenge
        completionHandler:(OTPCompletion)completionHandler {
    //    // Detect jailbreak status.
    //    if (EMJailbreakDetectorGetJailbreakStatus() == EMJailbreakStatusJailbroken) {
    //        return;
    //    }
    
    // Calculate OTP and display message box in case of success.
    NSError             *error  = nil;
    id<EMSecureString>  otp     = nil;
    
    if (serverChallenge) {
        // Ocra does require multiauth enabled.
        // Checking EMPinAuthInput protocol is redundant, because if multiauth is not enabled it must be pin anyway.
        BOOL isMultiauth = [_token isMultiAuthModeEnabled];
        if (!isMultiauth && [authInput conformsToProtocol:@protocol(EMPinAuthInput)]) {
            isMultiauth = [_token upgradeToMultiAuthMode:(id<EMPinAuthInput>)authInput error:&error];
        }
        
        // Compute OTP only when activation was successful.
        if (isMultiauth) {
            otp = [_device ocraOtpWithAuthInput:authInput
                        serverChallengeQuestion:serverChallenge
                        clientChallengeQuestion:nil
                                   passwordHash:nil
                                        session:nil
                                          error:&error];
        }
    } else {
        otp = [_device totpWithAuthInput:authInput error:&error];
    }
    
    // Notify listener
    if (completionHandler) {
        completionHandler(otp, authInput, serverChallenge, error);
    }
    
    // Wipe for security reasons.
    [otp wipe];
}

- (void)totpWithFaceId:(OTPCompletion)completionHandler
   withServerChallenge:(id<EMSecureString>)serverChallenge {
    EMSystemFaceAuthService     *service    = [EMSystemFaceAuthService serviceWithModule:[EMAuthModule authModule]];
    EMSystemFaceAuthContainer   *container  = [EMSystemFaceAuthContainer containerWithNativeFaceAuthService:service];
    
    // Trigger system authentication
    [container authenticateUser:_token
                    withMessage:TRANSLATE(@"STRING_BIOMETRICS_VERIFICATION")
                  fallbackTitle:nil
              completionHandler:^(id<EMSystemFaceAuthInput> faceAuthInput, NSData *evaluatedPolicyDomainState, NSError *error) {
                  // Call in UI thread.
                  dispatch_async(dispatch_get_main_queue(), ^{
                      if (faceAuthInput) {
                          [self totpWithAuthInput:faceAuthInput
                              withServerChallenge:serverChallenge
                                completionHandler:completionHandler];
                      } else if (completionHandler && [error code] == EM_STATUS_AUTHENTICATION_CANCELED_USER_FALLBACK) {
                          completionHandler(nil, nil, serverChallenge, nil); // Pin enter fallback.
                      } else if (completionHandler) {
                          completionHandler(nil, nil, nil, error);
                      }
                  });
              }];
}

- (void)totpWithTouchId:(OTPCompletion)completionHandler
    withServerChallenge:(id<EMSecureString>)serverChallenge {
    EMSystemBioFingerprintAuthService   *service    = [EMSystemBioFingerprintAuthService serviceWithModule:[EMAuthModule authModule]];
    EMSystemBioFingerprintContainer     *container  = [EMSystemBioFingerprintContainer containerWithBioFingerprintAuthService:service];
    
    // Trigger system authentication
    [container authenticateUser:_token
                    withMessage:TRANSLATE(@"STRING_BIOMETRICS_VERIFICATION")
                  fallbackTitle:nil
              completionHandler:^(id<EMSystemBioFingerprintAuthInput> bioFpAuthInput, NSData *evaluatedPolicyDomainState, NSError *error) {
                  // Call in UI thread.
                  dispatch_async(dispatch_get_main_queue(), ^{
                      if (bioFpAuthInput) {
                          [self totpWithAuthInput:bioFpAuthInput withServerChallenge:serverChallenge completionHandler:completionHandler];
                      } else if (completionHandler && [error code] == EM_STATUS_AUTHENTICATION_CANCELED_USER_FALLBACK) {
                          completionHandler(nil, nil, serverChallenge, nil); // Pin enter fallback.
                      } else if (completionHandler) {
                          completionHandler(nil, nil, nil, error);
                      }
                  });
              }];
}

@end
