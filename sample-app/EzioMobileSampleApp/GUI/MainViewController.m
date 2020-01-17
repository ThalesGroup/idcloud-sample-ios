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

#import "MainViewController.h"

@interface MainViewController() <UITabBarControllerDelegate>

@property (strong, nonatomic) id<EMSecureString>    lastOTP;
@property (strong, nonatomic) dispatch_source_t     timer;

@end

@implementation MainViewController

// MARK: - Life Cycle

- (void)viewWillAppear:(BOOL)animated
{    
    [super viewWillAppear:animated];
    
    // Transfer title to NVC since we are also in tabs.
    self.tabBarController.title = self.title;
    
    // Used to animate transitions.
    self.tabBarController.delegate = self;
    
    // Realod common as well as inherited values.
    [self reloadGUI];
    
    // This way we can hide keyboard if user will tap outside.
    UITapGestureRecognizer *tapOnVC = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tapOnVC];
    
    // Helper to keep methods cleaner.
    __weak __typeof(self) weakSelf = self;
    _otpResultDisplay = ^(id<EMSecureString> otp, id<EMAuthInput> input, id<EMSecureString> serverChallenge, NSError *error) {
        if (weakSelf) {
            [weakSelf displayOTPResult:otp authInput:input serverChallenge:serverChallenge error:error];
        }
    };
}

- (void)dealloc
{
    [self invalidateTimerAndWipeOTP];
}

// MARK: - MainViewControllerProtocol

- (void)reloadGUI
{
    // Display push token registration status.
    [self updatePushRegistrationStatus];
    
    // No matter what was set. If there is a loading indicator, we should disable everything.
    if (_loadingIndicator.isPresent) {
        [self disableGUI];
    } else {
        // Enable tab options based on SDK state.
        BOOL tokenEnrolled = [CMain sharedInstance].managerToken.tokenDevice != nil;
        NSArray<UITabBarItem *> *items = self.tabBarController.tabBar.items;
        for (NSUInteger index = 0; index < items.count; index++) {
            [items[index] setEnabled:tokenEnrolled ? index != 0 : index == 0];
        }
        
        // Those values are only for token based views.
        if (tokenEnrolled && (_buttonOTPPinOffline || _buttonOTPTouchIdOffline || _buttonOTPFaceIdOffline || _buttonOTPGemaltoFaceIdOffline)) {
            TokenStatus status = [CMain sharedInstance].managerToken.tokenDevice.tokenStatus;
            
            [self setButtonOTPPinEnabled:YES];
            [self setButtonOTPFaceIdEnabled:status.isFaceEnabled];
            [self setButtonOTPTouchIdEnabled:status.isTouchEnabled];
            [self setButtonOTPGemaltoFaceIdEnabled:status.isGemFaceEnabled];
        }
    }
}

- (void)disableGUI
{
    // Not all views does have OTP buttons, but ObjC does not react on nil.
    [self setButtonOTPPinEnabled:NO];
    [self setButtonOTPFaceIdEnabled:NO];
    [self setButtonOTPTouchIdEnabled:NO];
    [self setButtonOTPGemaltoFaceIdEnabled:NO];
    
    // Disable all tab bar items. Disabling just user interaction does not change colour and it's not working in transition.
    for (UITabBarItem *loopItem in self.tabBarController.tabBar.items) {
        [loopItem setEnabled:NO];
    }
}

- (void)hideKeyboard
{
    // Overrload
}

- (void)loadingIndicatorShowWithCaption:(NSString *)caption;
{
    if (!_loadingIndicator || _loadingIndicator.isPresent)
        return;
    
    // Display indicator.
    [_loadingIndicator setCaption:caption];
    [_loadingIndicator loadingBarShow:YES animated:YES];
    
    // If we want to show loading indicator we have to lock rest of the UI.
    [self reloadGUI];
}

- (void)loadingIndicatorHide
{
    if (!_loadingIndicator || !_loadingIndicator.isPresent)
        return;
    
    // Display indicator.
    [_loadingIndicator loadingBarShow:NO animated:YES];
    
    // If we want to show loading indicator we have to lock rest of the UI.
    [self reloadGUI];
}

- (void)updatePushRegistrationStatus
{
    // This view is common even for settings which does not have status information.
    if (!_labelOOBStatus) {
        return;
    }
    
    // Push token was already registered
    if ([CMain sharedInstance].managerPush.isPushTokenRegistered) {
        _labelOOBStatus.text        = NSLocalizedString(@"PUSH_STATUS_REGISTERED", nil);
        _labelOOBStatusValue.hidden = NO;
        _activityOOBStatus.hidden   = YES;
        [_activityOOBStatus stopAnimating];
    } else {
        _labelOOBStatus.text        = NSLocalizedString(@"PUSH_STATUS_PENDING", nil);
        _labelOOBStatusValue.hidden = YES;
        _activityOOBStatus.hidden   = NO;
        [_activityOOBStatus startAnimating];
    }
}

- (void)updateFaceIdSupport
{
    // Performance is not an issue. Call unified method to reload GUI.
    [self reloadGUI];
}

- (void)approveOTP:(NSString *)message
withServerChallenge:(id<EMSecureString>)serverChallenge
 completionHandler:(void (^)(id<EMSecureString>))handler
{
    // Mandatory parameter.
    assert(handler);
    if (!handler) {
        return;
    }
    
    // All auth types does have same handler at the and. This will allow to save some code.
    __weak __typeof(self) weakSelf = self;
    OTPCompletion helpHandler = ^(id<EMSecureString> otp, id<EMAuthInput> input,
                                  id<EMSecureString> serverChallenge, NSError *error) {
        if (otp) {
            handler(otp);
        } else if (weakSelf) {
            [weakSelf loadingIndicatorHide];
            [weakSelf showNSErrorIfExists:error];
        }
        
        [input wipe];
    };
    
    // Prepare simple dialog with two actions.
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"PUSH_APPROVE_QUESTION", nil)
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // First is for approving. In that case we need to calculate OTP.
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"PUSH_APPROVE_QUESTION_APPROVE", nil)
                                              style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                      {
        // View is gone. We can exit.
        if (!weakSelf) {
            return;
        }
        
        [weakSelf totpWithMostComfortableOne:serverChallenge handler:helpHandler];
    }]];
    
    // Second is deny action. For such message we don't need to calculate OTP.
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"PUSH_APPROVE_QUESTION_DENY", nil)
                                              style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        handler(nil);
    }]];
    
    // Display message box and lock thread to wait for response.
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)displayOTPResult:(id<EMSecureString>)otp
               authInput:(id<EMAuthInput>)input
         serverChallenge:(id<EMSecureString>)serverChallenge
                   error:(NSError *)error
{
    if (otp && !error) {
        __weak __typeof(self) weakSelf = self;
        
        // First store current OTP (so we can use recalculate feature)
        [self setLastOTP:otp];
        
        // Display popup with OTP value.
        UIAlertController *otpController =  [UIAlertController alertControllerWithTitle:NSLocalizedString(@"OTP_VALUE_CAPTION", nil)
                                                                                message:[self getOTPDescription:input serverChallenge:serverChallenge]
                                                                         preferredStyle:UIAlertControllerStyleAlert];
        [otpController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"COMMON_MESSAGE_OK", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
            // View is gone. We can exit.
            if (!weakSelf) {
                return;
            }
            
            [weakSelf invalidateTimerAndWipeOTP];
            [input wipe];
        }]];
        [self presentViewController:otpController animated:YES completion:nil];
        
        // Schedule lifespan display.
        if (!_timer) {
            // NSTimer does support blocks from iOS 10. Use old way which works everywhere.
            _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
            dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1ull * NSEC_PER_SEC, 0);
            dispatch_source_set_event_handler(_timer, ^{
                // View is gone. We can exit.
                if (!weakSelf) {
                    return;
                }
                
                if (otpController) {
                    [otpController setMessage:[weakSelf getOTPDescription:input serverChallenge:serverChallenge]];
                }
                
            });
            dispatch_resume(_timer);
        }
    } else {
        [self showNSErrorIfExists:error];
    }
}

// MARK: - Auth Solver

- (void)getPinInputWithCompletionHandler:(EMSecureInputUiOnFinish)handler
                               changePin:(BOOL)changePin
                        unlockUIOnCancel:(BOOL)unlockOnCancel
{
    // Get secure keypad builder.
    id<EMSecureInputBuilderV2> builder = [[EMSecureInputService serviceWithModule:[EMUIModule uiModule]] secureInputBuilderV2];
    
    // Configure secure keypad behaviour and visual.
    [builder setOkButtonBehavior:EMSecureInputUiOkButtonAlwaysEnabled];
    [builder setButtonPressedVisibility:YES];
    [builder showNavigationBar:YES];
    [builder validateUiConfiguration];
    
    // We are using the same method also for change pin.
    if (changePin) {
        [builder setFirstLabel:NSLocalizedString(@"SECURE_KEY_PAD_OLD_PIN", nil)];
        [builder setSecondLabel:NSLocalizedString(@"SECURE_KEY_PAD_NEW_PIN", nil)];
    }
    
    // Save current state of loading bar.
    BOOL isLoadingPresent = _loadingIndicator.isPresent;
    __weak __typeof(self) weakSelf = self;
    
    // Build keypad and add handler.
    id<EMSecureInputUi> secureInput = [builder buildWithScrambling:NO
                                                isDoubleInputField:changePin
                                                          isDialog:NO
                                                     onFinishBlock:^(id<EMPinAuthInput> firstPin, id<EMPinAuthInput> secondPin)
                                       {
        // Wipe pin-pad builder for security purpose.
        // This part is also important because of builder life cycle, otherwise this block will never be triggered!
        [builder wipe];
        
        // View is gone. We can exit.
        if (!weakSelf) {
            return;
        }
        
        // Return loading bar if it should be there.
        if (isLoadingPresent && unlockOnCancel) {
            [weakSelf.loadingIndicator loadingBarShow:YES animated:NO];
        }
        
        // Dismiss the keypad and delete the secure input UI.
        [weakSelf.navigationController popViewControllerAnimated:YES];
        
        // Notify handler.
        if (handler) {
            handler(firstPin, secondPin);
        }
    }];
    
    // Loading must be turned off, because back button on secure input does not trigger finish block.
    if (unlockOnCancel) {
        [_loadingIndicator loadingBarShow:NO animated:NO];
    }
    
    // Push in secure input UI view controller to the current view controller
    [self.navigationController pushViewController:secureInput.viewController animated:YES];
}

// SAMPLE: TOTP - How to generate TOTP based on SDK state
- (void)totpWithMostComfortableOne:(id<EMSecureString>)serverChallenge
                           handler:(OTPCompletion)handler
{
    // Check all auth mode states so we can pick proper auth mode.
    TokenStatus status  = [CMain sharedInstance].managerToken.tokenDevice.tokenStatus;
    
    if (status.isFaceEnabled) {
        [self totpWithFaceId:serverChallenge handler:handler];
    } else if (status.isGemFaceEnabled) {
        [self totpWithGemaltoFaceId:serverChallenge handler:handler];
    } else if (status.isTouchEnabled) {
        [self totpWithTouchId:serverChallenge handler:handler];
    } else {
        [self totpWithPin:serverChallenge handler:handler];
    }
}

- (void)totpWithPin:(id<EMSecureString>)serverChallenge
            handler:(OTPCompletion)handler
{
    [self getPinInputWithCompletionHandler:^(id<EMPinAuthInput> firstPin, id<EMPinAuthInput> secondPin) {
        // Generate OTP with provided pin.
        [[CMain sharedInstance].managerToken.tokenDevice totpWithAuthInput:firstPin
                                                       withServerChallenge:serverChallenge
                                                         completionHandler:handler];
    } changePin:NO unlockUIOnCancel:YES];
}

- (void)totpWithFaceId:(id<EMSecureString>)serverChallenge
               handler:(OTPCompletion)handler
{
    
    __weak __typeof(self) weakSelf = self;
    [[CMain sharedInstance].managerToken.tokenDevice totpWithFaceId:^(id<EMSecureString> otp, id<EMAuthInput> input,
                                                                      id<EMSecureString> newServerChallenge, NSError *error) {
        // View is gone. We can exit.
        if (!weakSelf) {
            return;
        }
        
        // Pin fallback
        if (!otp && !error) {
            [weakSelf totpWithPin:newServerChallenge handler:handler];
        } else {
            handler(otp, input, newServerChallenge, error);
        }
        
    } withServerChallenge:serverChallenge];
}

- (void)totpWithTouchId:(id<EMSecureString>)serverChallenge
                handler:(OTPCompletion)handler
{
    __weak __typeof(self) weakSelf = self;
    [[CMain sharedInstance].managerToken.tokenDevice totpWithTouchId:^(id<EMSecureString> otp, id<EMAuthInput> input,
                                                                       id<EMSecureString> newServerChallenge, NSError *error) {
        // View is gone. We can exit.
        if (!weakSelf) {
            return;
        }
        
        // Pin fallback
        if (!otp && !error) {
            [weakSelf totpWithPin:newServerChallenge handler:handler];
        } else {
            handler(otp, input, newServerChallenge, error);
        }
    } withServerChallenge:serverChallenge];
}

- (void)totpWithGemaltoFaceId:(id<EMSecureString>)serverChallenge
                      handler:(OTPCompletion)handler
{
    [[CMain sharedInstance].managerToken.tokenDevice totpWithGemaltoFaceId:handler
                                                       withServerChallenge:serverChallenge
                                                  presentingViewController:self];
}

// MARK: - Private Helpers

- (void)invalidateTimerAndWipeOTP
{
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
    
    [self setLastOTP:nil];
}

- (void)setLastOTP:(id<EMSecureString>)otp
{
    if (_lastOTP) {
        [_lastOTP wipe];
    }
    
    _lastOTP = otp ? [otp copy] : nil;
}

- (NSString *)getOTPDescription:(id<EMAuthInput>)input serverChallenge:(id<EMSecureString>)serverChallenge
{
    // Read last OTP lifespan from device.
    NSInteger lifeSpan = [CMain sharedInstance].managerToken.tokenDevice.device.lastOtpLifespan;
    
    // In case that OTP is not valid anymore. Generate new one using last auth input.
    if (lifeSpan <= 0) {
        [[CMain sharedInstance].managerToken.tokenDevice totpWithAuthInput:input
                                                       withServerChallenge:serverChallenge
                                                         completionHandler:^(id<EMSecureString> otp, id<EMAuthInput> newInput,
                                                                             id<EMSecureString> newServerChallenge, NSError *error) {
            self.lastOTP = otp;
        }];
        lifeSpan = [CMain sharedInstance].managerToken.tokenDevice.device.lastOtpLifespan;
    }
    
    return [NSString stringWithFormat:NSLocalizedString(@"OTP_VALUE_DESCRIPTION_VALID", nil), _lastOTP.stringValue, (long)lifeSpan];
}

- (void)setButtonOTPPinEnabled:(BOOL)enabled
{
    [_buttonOTPPinOffline   setEnabled:enabled];
    [_buttonOTPPinInBand    setEnabled:enabled];
}

- (void)setButtonOTPFaceIdEnabled:(BOOL)enabled
{
    [_buttonOTPFaceIdOffline    setEnabled:enabled];
    [_buttonOTPFaceIdInBand     setEnabled:enabled];
}

- (void)setButtonOTPTouchIdEnabled:(BOOL)enabled
{
    [_buttonOTPTouchIdOffline   setEnabled:enabled];
    [_buttonOTPTouchIdInBand    setEnabled:enabled];
}

- (void)setButtonOTPGemaltoFaceIdEnabled:(BOOL)enabled
{
    [_buttonOTPGemaltoFaceIdOffline setEnabled:enabled];
    [_buttonOTPGemaltoFaceIdInBand  setEnabled:enabled];
}

// MARK: - EMFaceAuthVerifierDelegate

- (void)verifier:(id<EMFaceAuthVerifier>)verifier didUpdateFaceAuthFrameEvent:(id<EMFaceAuthFrameEvent>)frameEvent
{
    // In case we want to display some frames during face scanning process.
}

// MARK: - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    // Add animation to tab switch.
    return [[CMain sharedInstance] animateTabChange:tabBarController toViewController:viewController];
}

@end
