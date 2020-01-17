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

#import "TokenDetail_SettingsVC.h"

@interface TokenDetail_SettingsVC ()

@property (weak, nonatomic) IBOutlet UILabel    *labelDomainValue;
@property (weak, nonatomic) IBOutlet UILabel    *labelUserIdValue;

@property (weak, nonatomic) IBOutlet UIButton   *buttonToggleFaceId;
@property (weak, nonatomic) IBOutlet UIButton   *buttonToggleTouchId;
@property (weak, nonatomic) IBOutlet UIButton   *buttonToggleGemaltoFaceId;
@property (weak, nonatomic) IBOutlet UIButton   *buttonChangePin;
@property (weak, nonatomic) IBOutlet UIButton   *buttonDeleteToken;
@property (weak, nonatomic) IBOutlet UIButton   *buttonPrivacyPolicy;

@end

@implementation TokenDetail_SettingsVC

// MARK: - MainViewControllerProtocol

- (void)reloadGUI
{
    [super reloadGUI];
    
    // Get current device.
    TokenDevice *device = [CMain sharedInstance].managerToken.tokenDevice;
    
    _labelDomainValue.text  = C_CFG_OOB_DOMAIN();   // Domain is fixed from config.
    _labelUserIdValue.text  = device.token.name;    // We use user id as token name in sample app.
    
    // Non of the button is enabled with loading in place.
    BOOL enabled = !self.loadingIndicator.isPresent;
    
    // Check all auth mode states so we can enable / disable proper buttons.
    TokenStatus status = device.tokenStatus;
    
    // Buttons can do both. Enable and disable modes.
    [_buttonToggleTouchId setTitle:status.isTouchEnabled ? NSLocalizedString(@"AUTH_MODE_TOUCH_ID_DISABLE", nil) : NSLocalizedString(@"AUTH_MODE_TOUCH_ID_ENABLE", nil)
                          forState:UIControlStateNormal];
    [_buttonToggleFaceId setTitle:status.isFaceEnabled ? NSLocalizedString(@"AUTH_MODE_FACE_ID_DISABLE", nil) : NSLocalizedString(@"AUTH_MODE_FACE_ID_ENABLE", nil)
                         forState:UIControlStateNormal];
    [_buttonToggleGemaltoFaceId setTitle:status.isGemFaceEnabled ? NSLocalizedString(@"AUTH_MODE_GEM_FACE_ID_DISABLE", nil) : NSLocalizedString(@"AUTH_MODE_GEM_FACE_ID_ENABLE", nil)
                                forState:UIControlStateNormal];
    
    [_buttonChangePin               setEnabled:enabled];
    [_buttonDeleteToken             setEnabled:enabled];
    [_buttonToggleTouchId           setEnabled:status.isTouchSupported && enabled];
    [_buttonToggleFaceId            setEnabled:status.isFaceSupported && enabled];
    [_buttonToggleGemaltoFaceId     setEnabled:status.isGemFaceSupported && enabled];
    
    [_buttonPrivacyPolicy           setHidden:!C_CFG_PRIVACY_POLICY_URL()];
}

- (void)disableGUI
{
    [super disableGUI];
    
    [_buttonToggleFaceId        setEnabled:NO];
    [_buttonToggleTouchId       setEnabled:NO];
    [_buttonToggleGemaltoFaceId setEnabled:NO];
    [_buttonChangePin           setEnabled:NO];
    [_buttonDeleteToken         setEnabled:NO];
}

// MARK: - User Interface

- (IBAction)onButtonPressedToggleFaceId:(UIButton *)sender
{
    TokenStatus             status      = [CMain sharedInstance].managerToken.tokenDevice.tokenStatus;
    EMSystemFaceAuthService *service    = [EMSystemFaceAuthService serviceWithModule:[EMAuthModule authModule]];

    if (status.isFaceEnabled) {
        [self disableAuthMode:[service authMode]];
    } else {
        [self enableAuthMode:[service authMode]];
    }
}

- (IBAction)onButtonPressedToggleTouchId:(UIButton *)sender
{
    TokenStatus                         status      = [CMain sharedInstance].managerToken.tokenDevice.tokenStatus;
    EMSystemBioFingerprintAuthService   *service    = [EMSystemBioFingerprintAuthService serviceWithModule:[EMAuthModule authModule]];
    
    if (status.isTouchEnabled) {
        [self disableAuthMode:[service authMode]];
    } else {
        [self enableAuthMode:[service authMode]];
    }
}

- (IBAction)onButtonPressedToggleGemaltoFaceId:(UIButton *)sender
{
    TokenStatus         status      = [CMain sharedInstance].managerToken.tokenDevice.tokenStatus;
    EMFaceAuthService   *service    = [[EMFaceManager sharedInstance] service];
    
    if (status.isGemFaceEnabled) {
        [self disableAuthMode:[service authMode]];
    } else {
        [self enableAuthMode:[service authMode]];
    }
}

- (IBAction)onButtonPressedChangePin:(id)sender
{
    __weak __typeof(self) weakSelf = self;
    // Get both old and new pin from secure keypad.
    [self getPinInputWithCompletionHandler:^(id<EMPinAuthInput> firstPin, id<EMPinAuthInput> secondPin) {
        // View is gone. We can exit.
        if (!weakSelf) {
            [firstPin wipe];
            [secondPin wipe];
            return;
        }
        
        // Try to change pin with given inputs.
        NSError *error = nil;
        if ([[CMain sharedInstance].managerToken.tokenDevice.token changePinWithAuthInput:firstPin newPin:secondPin error:&error]) {
            [weakSelf showMessageWithCaption:NSLocalizedString(@"PIN_CHANGE_CAPTION", nil)
                                 description:NSLocalizedString(@"PIN_CHANGE_DESCRIPTION", nil)];
        } else {
            [weakSelf showNSErrorIfExists:error];
        }
        
        [firstPin wipe];
        [secondPin wipe];
    } changePin:YES unlockUIOnCancel:NO];
}

- (IBAction)onButtonPressedDeleteToken:(UIButton *)sender
{
    // Disable whole UI and display loading indicator.
    [self loadingIndicatorShowWithCaption:NSLocalizedString(@"LOADING_MESSAGE_REMOVING", nil)];
    
    // Try to unregister and remove token.
    __weak __typeof(self) weakSelf = self;
    [[CMain sharedInstance].managerToken deleteTokenWithCompletionHandler:^(BOOL success, NSError *error) {
        // View is gone. We can exit.
        if (!weakSelf) {
            return;
        }
        
        // Hide loading bar and reload GUI
        [weakSelf loadingIndicatorHide];
        
        // If removal was successful, we can display main provisioning view.
        if (success) {
            [[CMain sharedInstance] switchTabToCurrentState:YES];
        } else {
            // Display possible errors.
            [weakSelf showNSErrorIfExists:error];
        }
    }];
}
- (IBAction)onButtonPressedPrivacyPolicy:(UIButton *)sender
{
    if (C_CFG_PRIVACY_POLICY_URL()) {
        [[UIApplication sharedApplication] openURL:C_CFG_PRIVACY_POLICY_URL()];
    }
}

// MARK: - Private Helpers

- (void)disableAuthMode:(id<EMAuthMode>)mode
{
    TokenDevice *device = [CMain sharedInstance].managerToken.tokenDevice;
    
    // This should not happen due GUI lock, but it's good practice to check anyway.
    if (![device.token isAuthModeActive:mode]) {
        [self reloadGUI];
        return;
    }
    
    NSError *error = nil;
    [device.token deactivateAuthMode:mode error:&error];
    
    // Some errors are not critical and we don't want to display them.
    // Check whenever operation was successful by checking mode state.
    if (error && [device.token isAuthModeActive:mode]) {
        [self showNSErrorIfExists:error];
    } else {
        [self reloadGUI];
    }
}

// SAMPLE: AUTH Mode - Enable different auth mode support
- (void)enableAuthMode:(id<EMAuthMode>)mode
{
    TokenDevice *device = [CMain sharedInstance].managerToken.tokenDevice;
    
    // This should not happen due GUI lock, but it's good practice to check anyway.
    if ([device.token isAuthModeActive:mode]) {
        [self reloadGUI];
        return;
    }
    
    __weak __typeof(self) weakSelf = self;
    
    // We must enable multiauth mode before activating any specific one.
    // Since we need pin for both of those operations this method will ask for it and return one directly.
    [self enableMultiauthWithCompletionHandler:^(id<EMPinAuthInput> firstPin, id<EMPinAuthInput> secondPin) {
        // View is gone. We can exit.
        if (!weakSelf) {
            return;
        }
        
        // Try to activate selected mode.
        NSError *error = nil;
        [device.token activateAuthMode:mode usingActivatedInput:firstPin error:&error];;
        
        // Some errors are not critical and we don't want to display them.
        // Check whenever operation was successful by checking mode state.
        if (error && ![device.token isAuthModeActive:mode]) {
            [weakSelf showNSErrorIfExists:error];
        } else {
            [weakSelf reloadGUI];
        }
    }];
}

- (void)enableMultiauthWithCompletionHandler:(EMSecureInputUiOnFinish)handler
{
    TokenDevice *device = [CMain sharedInstance].managerToken.tokenDevice;
    
    // Check whenever multiauthmode is already enabled.
    __block BOOL isEnabled = [device.token isMultiAuthModeEnabled];
    
    // In both cases we will need auth pin, because it's used for
    // multiauth upgrade as well as enabling specific authmodes.
    __weak __typeof(self) weakSelf = self;
    [self getPinInputWithCompletionHandler:^(id<EMPinAuthInput> firstPin, id<EMPinAuthInput> secondPin) {
        // View is gone. We can exit.
        if (!weakSelf) {
            [firstPin wipe];
            [secondPin wipe];
            return;
        }
        
        // If multiauth is not enabled and we do have pin, we can try to upgrade it.
        NSError *error = nil;
        if (!isEnabled && firstPin) {
            isEnabled = [device.token upgradeToMultiAuthMode:firstPin error:&error];
        }
        
        // Display whenever something went wrong and reload GUI.
        [weakSelf showNSErrorIfExists:error];
        [weakSelf reloadGUI];
        
        // Notify handler
        if (handler) {
            handler(firstPin, secondPin);
        }
        
        [firstPin wipe];
        [secondPin wipe];
    } changePin:NO unlockUIOnCancel:YES];
}

@end
