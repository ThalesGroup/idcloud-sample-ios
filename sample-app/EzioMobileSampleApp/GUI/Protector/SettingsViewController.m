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

#import "SettingsViewController.h"
#import "SideMenuViewController.h"

@interface SettingsViewController ()

@property (nonatomic, weak) IBOutlet IdCloudButton  *buttonFaceId;
@property (nonatomic, weak) IBOutlet IdCloudButton  *buttonChangePin;
@property (nonatomic, weak) IBOutlet IdCloudButton  *buttonDeleteToken;
@property (nonatomic, weak) IBOutlet UIButton       *buttonPrivacyPolicy;

@property (nonatomic, weak) IBOutlet UISwitch       *switchFaceId;
@property (nonatomic, weak) IBOutlet UISwitch       *switchTouchId;

@property (nonatomic, weak) IBOutlet UILabel        *labelVersion;

@end

@implementation SettingsViewController

// MARK: - Life Cycle

+ (instancetype)viewController {
    return CreateVC(@"Protector", self);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Display current protector version.
    _labelVersion.text = [NSString stringWithFormat:TRANSLATE(@"STRING_SETTINGS_VERSION"), @"1",  [EMCore version]];
}

// MARK: - MainViewController

- (void)enableGUI:(BOOL)enabled {
    [super enableGUI:enabled];
    
    // Get current token status.
    TokenStatus status = CMain.sharedInstance.managerToken.tokenDevice.tokenStatus;
    
    // Biometric is enabled if system Face Id is supported.
    [_buttonFaceId         setEnabled:enabled && (status.isTouchSupported || status.isFaceSupported)];
    [_switchFaceId         setEnabled:enabled && (status.isTouchSupported || status.isFaceSupported)];
    [_switchFaceId         setOn:status.isTouchEnabled || status.isFaceEnabled];
    
    [_buttonChangePin       setEnabled:enabled];
    [_buttonDeleteToken     setEnabled:enabled];
    
    [_buttonPrivacyPolicy   setEnabled:enabled];
    [_buttonPrivacyPolicy   setHidden:!CFG_PRIVACY_POLICY_URL()];
    
    SideMenuViewController *sideMenu = (SideMenuViewController *)self.parentViewController;
    [sideMenu setUserInteractionEnabled:enabled];
}

// MARK: - User Interface

- (IBAction)onButtonPressedFaceId:(UIButton *)sender {
    [self toggleFaceId];
}

- (IBAction)onSwitchPressedFaceId:(UISwitch *)sender {
    // Do not allow to automatically switch value.
    // Switch peration might not be sucessfull. Wait for finish and reload.
    sender.on = !sender.on;
    [self toggleFaceId];
}

- (IBAction)onButtonPressedChangePin:(UIButton *)sender {
    [self changePin_step1_getAndVerifyPin];
}

- (IBAction)onButtonPressedDeleteToken:(UIButton *)sender {
    [self displayOnCancelDialog:TRANSLATE(@"STRING_TOKEN_REMOVE_CAPTION")
                        message:TRANSLATE(@"STRING_TOKEN_REMOVE_MESSAGE")
                       okButton:TRANSLATE(@"STRING_COMMON_DELETE")
                   cancelButton:TRANSLATE(@"STRING_COMMON_CANCEL")
              completionHandler:^(BOOL result) {
        if (result) {
            // Disable whole UI and display loading indicator.
            [self loadingIndicatorShowWithCaption:TRANSLATE(@"STRING_LOADING_REMOVING")];
            
            // Try to unregister and remove token.
            [CMain.sharedInstance.managerToken deleteTokenWithCompletionHandler:^(BOOL success, NSError *error) {
                // If removal was successful, we can display main provisioning view.
                if (success) {
                    [CMain.sharedInstance updateRootViewController];
                } else {
                    // Hide loading bar and reload GUI
                    [self loadingIndicatorHide];
                    // Display possible errors.
                    notifyDisplayErrorIfExists(error);
                }
            }];
        }
    }];
}

- (IBAction)onButtonPressedPrivacyPolicy:(UIButton *)sender {
    if (CFG_PRIVACY_POLICY_URL()) {
        [[UIApplication sharedApplication] openURL:CFG_PRIVACY_POLICY_URL() options:@{} completionHandler:nil];
    }
}

// MARK: - Private helpers

- (BOOL)disableAuthMode:(id<EMAuthMode>)mode {
    TokenDevice *device = CMain.sharedInstance.managerToken.tokenDevice;
    
    // This should not happen due GUI lock, but it's good practice to check anyway.
    if (![device.token isAuthModeActive:mode]) {
        [self reloadGUI];
        return YES;
    }
    
    NSError *error = nil;
    [device.token deactivateAuthMode:mode error:&error];
    
    // Some errors are not critical and we don't want to display them.
    // Check whenever operation was successful by checking mode state.
    if (error && [device.token isAuthModeActive:mode]) {
        notifyDisplayErrorIfExists(error);
        return NO;
    } else {
        [self reloadGUI];
    }
    
    return YES;
}

- (void)enableAuthMode:(id<EMAuthMode>)mode allowBackButton:(BOOL)allowBackButton {
    TokenDevice *device = CMain.sharedInstance.managerToken.tokenDevice;
    
    // This should not happen due GUI lock, but it's good practice to check anyway.
    if ([device.token isAuthModeActive:mode]) {
        [self reloadGUI];
        return;
    }
    
    // We must enable multiauth mode before activating any specific one.
    // Since we need pin for both of those operations this metod will ask for it and return one directly.
    [self enableMultiauthWithCompletionHandler:^(id<EMPinAuthInput> firstPin, id<EMPinAuthInput> secondPin) {
        
        // Try to activate selected mode.
        NSError *error = nil;
        [device.token activateAuthMode:mode usingActivatedInput:firstPin error:&error];
        
        // Some errors are not critical and we don't want to display them.
        // Check whenever operation was successful by checking mode state.
        if (error && ![device.token isAuthModeActive:mode]) {
            notifyDisplayErrorIfExists(error);
        } else {
            [self reloadGUI];
        }
    } allowBackButton:allowBackButton];
}

- (void)enableMultiauthWithCompletionHandler:(EMSecureInputUiOnFinish)handler allowBackButton:(BOOL)allowBackButton {
    TokenDevice *device = CMain.sharedInstance.managerToken.tokenDevice;
    
    // Check whenever multiauthmode is already enabled.
    __block BOOL isEnabled = [device.token isMultiAuthModeEnabled];
    
    // In both cases we will need auth pin, becuase it's used for
    // multiauth upgrade as well as enabling specific authmodes.
    __weak __typeof(self) weakSelf = self;
    
    [self getPinInputWithCompletionHandler:^(id<EMPinAuthInput> firstPin, id<EMPinAuthInput> secondPin) {
        // If multiauth is not enabled and we do have pin, we can try to upgrade it.
        NSError *internalError = nil;
        if (!isEnabled && firstPin) {
            isEnabled = [device.token upgradeToMultiAuthMode:firstPin error:&internalError];
        }
        
        // Display whenever something went wrong and relaod GUI.
        notifyDisplayErrorIfExists(internalError);
        [weakSelf reloadGUI];
        
        // Notify handler
        if (handler) {
            handler(firstPin, nil);
        }
        
        [firstPin wipe];
    } changePin:NO unlockUIOnCancel:YES allowBackButton:allowBackButton];
}

// MARK: - Change Pin

- (void)changePin_step1_getAndVerifyPin {
    [self getPinInputWithCompletionHandler:^(id<EMPinAuthInput> firstPin, id<EMPinAuthInput> secondPin) {
        [self changePin_step2_changePin:firstPin];
    } changePin:NO unlockUIOnCancel:NO allowBackButton:YES];
}

- (void)changePin_step2_changePin:(id<EMPinAuthInput>)originalPin {
    // Get new pins.
    [self getPinInputWithCompletionHandler:^(id<EMPinAuthInput> firstPin, id<EMPinAuthInput> secondPin) {
        // Make sure that both pins are same.
        if ([firstPin isEqual:secondPin]) {
            NSError *error = nil;
            if ([CMain.sharedInstance.managerToken.tokenDevice.token changePinWithAuthInput:originalPin newPin:firstPin error:&error]) {
                notifyDisplay(TRANSLATE(@"STRING_PIN_CHANGE_SUCCESSFULLY"), NotifyTypeInfo);
            } else {
                NSString *errDesc = [self getPinRuleErrorDescription:error];
                notifyDisplay(errDesc, NotifyTypeError);
            }
        } else {
            notifyDisplay(TRANSLATE(@"STRING_PIN_CHANGE_FAILED_DIFFERENT"), NotifyTypeError);
        }
    } changePin:YES unlockUIOnCancel:NO allowBackButton:YES];
}

- (NSString *)getPinRuleErrorDescription:(NSError *)error {
    NSString *retValue = TRANSLATE(@"STRING_PIN_RULE_ERROR_UNKNOWN");
    
    switch (error.code) {
        case EMPinNumericSeriesError:
            retValue = TRANSLATE(@"STRING_PIN_RULE_ERROR_SERIES");
            break;
        case EMPinNonDigitsError:
            retValue = TRANSLATE(@"STRING_PIN_RULE_ERROR_NON_DIGIT");
            break;
        case EMPinPalindromeError:
            retValue = TRANSLATE(@"STRING_PIN_RULE_ERROR_PALINDROME");
            break;
        case EMPinSameDigitsError:
            return TRANSLATE(@"STRING_PIN_RULE_ERROR_UNIFORM");
            break;
        case EMPinTooShortError:
            retValue = TRANSLATE(@"STRING_PIN_RULE_ERROR_LENGTH");
            break;
        case EMPinEqualsOldPinError:
            retValue = TRANSLATE(@"STRING_PIN_RULE_ERROR_IDENTICAL");
            break;
        case EMPinRuleErrorDomainError: {
            NSString *desc = error.userInfo[NSUnderlyingErrorKey];
            if (desc) {
                retValue = desc;
            }
            break;
        }
    }
    
    return retValue;
}

// MARK: - Biometrics

- (void)toggleFaceId {
    // Get current token status.
    TokenStatus     status  = CMain.sharedInstance.managerToken.tokenDevice.tokenStatus;
    
    if (status.isFaceSupported) {
        // System Face Id
        id<EMAuthMode> faceMode = [[EMSystemFaceAuthService serviceWithModule:[EMAuthModule authModule]] authMode];
        if (status.isFaceEnabled) {
            [self disableAuthMode:faceMode];
        } else {
            [self enableAuthMode:faceMode allowBackButton:YES];
        }
    } else if (status.isTouchSupported) {
        id<EMAuthMode>  mode    = [[EMSystemBioFingerprintAuthService serviceWithModule:[EMAuthModule authModule]] authMode];
        if (status.isTouchEnabled) {
            [self disableAuthMode:mode];
        } else {
            [self enableAuthMode:mode allowBackButton:YES];
        }
    }
}

@end
