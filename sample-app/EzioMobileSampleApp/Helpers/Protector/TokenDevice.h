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

typedef struct
{
    // Whever is Sytem Touch ID supported by device and SDK
    BOOL isTouchSupported;
    // Whever is System Face ID supported by device and SDK
    BOOL isFaceSupported;
    // Whever is Protector Face ID supported by device and SDK
    BOOL isProtectorFaceSupported;
    
    // Whever is Sytem Touch ID supported and enabled
    BOOL isTouchEnabled;
    // Whever is System Face ID supported and enabled
    BOOL isFaceEnabled;
    // Whever is Protector Face ID supported and enabled
    BOOL isProtectorFaceEnabled;
    
    // Whever is Protector Face ID template enrolled
    BOOL isProtectorFaceTemplateEnrolled;
}TokenStatus;

/**
 Helepr class to handle token related operations.
 */
@interface TokenDevice : NSObject

/**
 Oath token
 */
@property (nonatomic, strong, readonly) id<EMOathToken>     token;
/**
 Oath device with preconfigured suite
 */
@property (nonatomic, strong, readonly) id<EMOathDevice>    device;
/**
 Maximum device / otp lifespan.
 */
@property (nonatomic, assign, readonly) NSInteger           lifespan;

/**
 Return current token auth options state.
 */
@property (nonatomic, assign, readonly) TokenStatus         tokenStatus;

/**
 Create new instance of TokenDevice

 @param token Enrolled oath token
 @return New instance
 */
+ (instancetype)tokenDeviceWithToken:(id<EMOathToken>)token;

/**
 Generate OTP with any supported auth input.
 
 @param authInput Any supported auth input like pin, face or touch id.
 @param completionHandler Triggered once operation is finished
 */
- (void)totpWithAuthInput:(id<EMAuthInput>)authInput
        completionHandler:(OTPCompletion)completionHandler;

/**
 Generate OTP with any supported auth input.

 @param authInput Any supported auth input like pin, face or touch id.
 @param serverChallenge OCRA Server challenge
 @param completionHandler Triggered once operation is finished
 */
- (void)totpWithAuthInput:(id<EMAuthInput>)authInput
      withServerChallenge:(id<EMSecureString>)serverChallenge
        completionHandler:(OTPCompletion)completionHandler;

//
/**
 Generate OTP with Face Id.

 @param completionHandler Triggered once operation is finished
 @param serverChallenge OCRA Server challenge
 */
- (void)totpWithFaceId:(OTPCompletion)completionHandler
   withServerChallenge:(id<EMSecureString>)serverChallenge;

/**
 Generate OTP with Protector Face Id.
 
 @param completionHandler Triggered once operation is finished
 @param serverChallenge OCRA Server challenge
 @param viewController Parent view controller to display verifier in.
 */
- (void)totpWithProtectorFaceId:(OTPCompletion)completionHandler
            withServerChallenge:(id<EMSecureString>)serverChallenge
       presentingViewController:(UIViewController *)viewController;

/**
 Generate OTP with Touch Id.
 
 @param completionHandler Triggered once operation is finished
 @param serverChallenge OCRA Server challenge
 */
- (void)totpWithTouchId:(OTPCompletion)completionHandler
    withServerChallenge:(id<EMSecureString>)serverChallenge;

@end
