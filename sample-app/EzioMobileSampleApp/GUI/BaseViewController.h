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

#import "IdCloudLoadingIndicator.h"
#import "IdCloudIncomingMessage.h"
#import "IdCloudNotification.h"

@interface BaseViewController : IdCloudAutorotationVC

// MARK: - Loading Indicator

/**
 Display overlay loading indicatior.
 
 @param caption Message displayed inside indicator
 */
- (void)loadingIndicatorShowWithCaption:(NSString *)caption;

/**
 Hide loading indicator.
 */
- (void)loadingIndicatorHide;


// MARK: - Incoming Messages

/**
 Create instance of incoming message handler.
 Not all base VC does need it. So we can implement this mehtod only in relevant places.

 @return New instace of incoming message dialog handler.
 */
- (__kindof IdCloudIncomingMessage *)createIncomingMessageView;


// MARK: - Dialogs

- (void)displayOnCancelDialog:(NSString *)caption
                      message:(NSString *)message
                     okButton:(NSString *)okButton
                 cancelButton:(NSString *)cancelButton
            completionHandler:(void (^)(BOOL))handler;

// MARK: - Common Helpers

/**
 Reaload all GUI information as well as enable/disable elements.
 */
- (void)reloadGUI;

/**
 Enable or disable all user interaction elements.
 */
- (void)enableGUI:(BOOL)enabled;

/**
 Whenever is some overlay currently displayed.

 @return YES if loading indicator / incoming message or any other overlay is visible on screen.
 */
- (BOOL)overlayViewVisible;

// MARK: - Auth Solvers

/// Display secure keypad to get pin from user and verify it against server.
/// @param handler Triggered once operation is finished. It's not called when user cancel this operation.
/// @param unlockOnCancel Whenever method should hide loading bar at the end.
/// @param allowBackButton Whenever secure keypad should include back button.
- (void)getPinInputVerifiedWithCompletionHandler:(PinAuthInputCompletion)handler
                                unlockUIOnCancel:(BOOL)unlockOnCancel
                                 allowBackButton:(BOOL)allowBackButton;

/**
 Pin input helper. Display secure keypad to get or change user pin.
 
 @param handler Triggered once operation is finished. It's not called when user cancel this operation.
 @param changePin Whenever we should display dialog for change pin option.
 @param unlockOnCancel Whenever method should hide loading bar at the end.
 @param allowBackButton Whenever secure keypad should include back button.
 */
- (void)getPinInputWithCompletionHandler:(EMSecureInputUiOnFinish)handler
                               changePin:(BOOL)changePin
                        unlockUIOnCancel:(BOOL)unlockOnCancel
                         allowBackButton:(BOOL)allowBackButton;

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

// MARK: - Incoming messages

- (void)onIncomingMessage:(NSNotification *)notify;

- (void)approveIncomingMessage:(NSString *)message
           withServerChallenge:(id<EMSecureString>)serverChallenge
             completionHandler:(void (^)(id<EMSecureString>))handler;


@end
