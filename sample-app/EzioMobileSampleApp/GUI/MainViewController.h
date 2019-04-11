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

#import "LoadingIndicatorView.h"

typedef enum : NSInteger {
    kOffline    = 0,
    kInBand     = 1,
} OTPHandlerType;


/**
 Common class for all example tab pages.
 */
@interface MainViewController : UIViewController <MainViewControllerProtocol, EMFaceAuthVerifierDelegate>

/**
 OOB Server status description
 */
@property (weak, nonatomic)     IBOutlet UILabel                    *labelOOBStatus;
/**
 OOB Server status value (green check once it's registered)
 */
@property (weak, nonatomic)     IBOutlet UILabel                    *labelOOBStatusValue;
/**
 OOB Server status indicator during registration process.
 */
@property (weak, nonatomic)     IBOutlet UIActivityIndicatorView    *activityOOBStatus;


/**
 Button connected with PIN auth input. Can be authentication, transaction sign etc.
 */
@property (weak, nonatomic)     IBOutlet UIButton                   *buttonOTPPinOffline;
@property (weak, nonatomic)     IBOutlet UIButton                   *buttonOTPPinInBand;
/**
 Button connected with System Face ID auth input. Can be authentication, transaction sign etc.
 */
@property (weak, nonatomic)     IBOutlet UIButton                   *buttonOTPFaceIdOffline;
@property (weak, nonatomic)     IBOutlet UIButton                   *buttonOTPFaceIdInBand;
/**
 Button connected with Gemalto Face ID auth input. Can be authentication, transaction sign etc.
 */
@property (weak, nonatomic)     IBOutlet UIButton                   *buttonOTPGemaltoFaceIdOffline;
@property (weak, nonatomic)     IBOutlet UIButton                   *buttonOTPGemaltoFaceIdInBand;
/**
 Button connected with System Touch ID auth input. Can be authentication, transaction sign etc.
 */
@property (weak, nonatomic)     IBOutlet UIButton                   *buttonOTPTouchIdOffline;
@property (weak, nonatomic)     IBOutlet UIButton                   *buttonOTPTouchIdInBand;

/**
 Overlay loading view. Should be on all tabs.
 */
@property (weak, nonatomic)     IBOutlet LoadingIndicatorView       *loadingIndicator;

/**
 OTP Result handler to simple display message box with results.
 */
@property (strong, nonatomic) OTPCompletion otpResultDisplay;

/**
 Pin input helper. Display secure keypad to get or change user pin.

 @param handler Triggered once operation is finished. It's not called when user cancel this operation.
 @param changePin Whenever we should display dialog for change pin option.
 @param unlockOnCancel Whenever method should hide loading bar at the end.
 */
- (void)getPinInputWithCompletionHandler:(EMSecureInputUiOnFinish)handler
                               changePin:(BOOL)changePin
                        unlockUIOnCancel:(BOOL)unlockOnCancel;

/**
 Generate TOTP using most comfortable enabled auth input.
 For example it will prefer Touch ID over Pin if such method is available.
 
 @param serverChallenge Server OCRA Challenge
 @param handler Triggered once operation is done.
 */
- (void)totpWithMostComfortableOne:(id<EMSecureString>)serverChallenge
                           handler:(OTPCompletion)handler;
/**
 Generate TOTP using user PIN.
 
 @param serverChallenge Server OCRA Challenge
 @param handler Triggered once operation is done.
 */
- (void)totpWithPin:(id<EMSecureString>)serverChallenge
            handler:(OTPCompletion)handler;
/**
 Generate TOTP using System Face ID.
 
 @param serverChallenge Server OCRA Challenge
 @param handler Triggered once operation is done.
 */
- (void)totpWithFaceId:(id<EMSecureString>)serverChallenge
               handler:(OTPCompletion)handler;
/**
 Generate TOTP using Touch ID.
 
 @param serverChallenge Server OCRA Challenge
 @param handler Triggered once operation is done.
 */
- (void)totpWithTouchId:(id<EMSecureString>)serverChallenge
                handler:(OTPCompletion)handler;
/**
 Generate TOTP using Gemalto Face ID.
 
 @param serverChallenge Server OCRA Challenge
 @param handler Triggered once operation is done.
 */
- (void)totpWithGemaltoFaceId:(id<EMSecureString>)serverChallenge
                      handler:(OTPCompletion)handler;

@end
