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

#import "BaseViewController.h"
#import "IdCloudSecureKeypadViewController.h"

@interface BaseViewController()

@property (nonatomic, weak) IBOutlet UILabel                *labelDomain;
@property (nonatomic, weak) IBOutlet UILabel                *labelTokenName;

@property (nonatomic, strong) IdCloudLoadingIndicator       *loadingIndicator;
@property (nonatomic, strong) IdCloudIncomingMessage        *incomingMessage;

@end

@implementation BaseViewController

// MARK: - Life Cycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Realod common as well as inherited values.
    [self reloadGUI];
    
    // Get informations about incoming push notificaitons.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onIncomingMessage:)
                                                 name:C_NOTIFICATION_ID_INCOMING_MESSAGE
                                               object:nil];
    
    if (!_loadingIndicator) {
        self.loadingIndicator = [IdCloudLoadingIndicator loadingIndicator];
        [self.view addSubview:_loadingIndicator];
    }
    if (!_incomingMessage) {
        self.incomingMessage = [self createIncomingMessageView];
        [self.view addSubview:_incomingMessage];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
        
    // Stop getting information about notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// MARK: - Loading Indicator

- (void)loadingIndicatorShowWithCaption:(NSString *)caption {
    // Loading indicator is already present or not configured for view at all.
    if (!_loadingIndicator || _loadingIndicator.isPresent) {
        return;
    }
    
    // Display loading indicator.
    [_loadingIndicator setCaption:caption];
    [_loadingIndicator loadingBarShow:YES animated:YES];
    
    // We want to lock UI behind it.
    [self reloadGUI];
}

- (void)loadingIndicatorHide {
    // Loading indicator is already hidden or not configured for view at all.
    if (!_loadingIndicator || !_loadingIndicator.isPresent) {
        return;
    }
    
    // Hide loading indicator.
    [_loadingIndicator loadingBarShow:NO animated:YES];
    
    // We want to un-lock UI behind it.
    [self reloadGUI];
}

- (BOOL)overlayViewVisible {
    return _loadingIndicator.isPresent || _incomingMessage.isPresent;
}

// MARK: - Incoming Messages

- (__kindof IdCloudIncomingMessage *)createIncomingMessageView {
    // Not relevant in all view controllers.
    // Only those who need to handle messages directly does implement this method.
    return nil;
}

// MARK: - Dialogs

- (void)displayOnCancelDialog:(NSString *)caption
                      message:(NSString *)message
                     okButton:(NSString *)okButton
                 cancelButton:(NSString *)cancelButton
            completionHandler:(void (^)(BOOL))handler {
    // Main alert builder.
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:caption
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // Add ok button with handler.
    [alert addAction:[UIAlertAction actionWithTitle:okButton
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                handler(YES);
                                            }]];
    
    // Add cancel button with handler.
    [alert addAction:[UIAlertAction actionWithTitle:cancelButton
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                handler(NO);
                                            }]];
    
    // Present dialog.
    [self presentViewController:alert animated:true completion:nil];
    
}

// MARK: - Common Helpers

- (void)reloadGUI {
    // Transfer title to NVC since we are also in tabs.
    _labelDomain.text = [NSString stringWithFormat:TRANSLATE(@"STRING_DOMAIN"), CFG_OOB_DOMAIN()];
    if (_labelTokenName) {
        TokenDevice *tokenDevice = CMain.sharedInstance.managerToken.tokenDevice;
        _labelTokenName.text = tokenDevice ? tokenDevice.token.name : @"";
    }
    
    [self enableGUI:![self overlayViewVisible]];
}

- (void)enableGUI:(BOOL)enabled {
    // Override
}

// MARK: - Auth Solvers

- (void)getPinInputWithCompletionHandler:(EMSecureInputUiOnFinish)handler
                               changePin:(BOOL)changePin
                        unlockUIOnCancel:(BOOL)unlockOnCancel
                         allowBackButton:(BOOL)allowBackButton {
    
    // Save current state of loading bar.
    BOOL isLoadingPresent = _loadingIndicator.isPresent;
    
    EMSecureInputUiOnFinish helper = ^(id<EMPinAuthInput> firstPin, id<EMPinAuthInput> secondPin) {
        // Return loading bar if it should be there.
        if (isLoadingPresent && unlockOnCancel) {
            [self.loadingIndicator loadingBarShow:YES animated:NO];
        }
        
        // Notify handler.
        if (handler) {
            handler(firstPin, secondPin);
        }
    };
    
    IdCloudSecureKeypadViewController *pinKeypad;
    if (changePin) {
        pinKeypad = [IdCloudSecureKeypadViewController changePinWithCaptionFirst:TRANSLATE(@"STRING_PIN_CHANGE_LABEL_FIRST")
                                                                   captionSecond:TRANSLATE(@"STRING_PIN_CHANGE_LABEL_SECOND")
                                                                      backButton:allowBackButton
                                                               completionHandler:helper];
    } else {
        pinKeypad = [IdCloudSecureKeypadViewController pinEntryWithCaption:TRANSLATE(@"STRING_PIN_CHANGE_LABEL_ENTERY_PIN")
                                                                backButton:allowBackButton
                                                         completionHandler:helper];
    }
    
    // In some cases we want to keep loading bar in place even if user cancel pin operation.
    if (unlockOnCancel) {
        [_loadingIndicator loadingBarShow:NO animated:NO];
    }
    
    [self presentViewController:pinKeypad animated:YES completion:nil];
}

- (void)totpWithMostComfortableOne:(id<EMSecureString>)serverChallenge
                           handler:(OTPCompletion)handler {
    // Check all auth mode states so we can pick proper auth mode.
    TokenStatus status  = CMain.sharedInstance.managerToken.tokenDevice.tokenStatus;
    
    if (status.isFaceEnabled) {
        [self totpWithFaceId:serverChallenge handler:handler];
    } else if (status.isTouchEnabled) {
        [self totpWithTouchId:serverChallenge handler:handler];
    } else {
        [self totpWithPin:serverChallenge handler:handler];
    }
}

- (void)totpWithPin:(id<EMSecureString>)serverChallenge
            handler:(OTPCompletion)handler {
    [self getPinInputWithCompletionHandler:^(id<EMPinAuthInput> firstPin, id<EMPinAuthInput> secondPin) {
        // Generate otp with provided pin.
        [CMain.sharedInstance.managerToken.tokenDevice totpWithAuthInput:firstPin
                                                     withServerChallenge:serverChallenge
                                                       completionHandler:handler];
    } changePin:NO unlockUIOnCancel:YES allowBackButton:YES];
}

- (void)totpWithFaceId:(id<EMSecureString>)serverChallenge
               handler:(OTPCompletion)handler {
    
    [CMain.sharedInstance.managerToken.tokenDevice totpWithFaceId:^(id<EMSecureString> otp, id<EMAuthInput> input,
                                                                    id<EMSecureString> newServerChallenge, NSError *error) {
        // Pin fallback
        if (!otp && !error) {
            [self totpWithPin:newServerChallenge handler:handler];
        } else {
            handler(otp, input, newServerChallenge, error);
        }
    } withServerChallenge:serverChallenge];
}

- (void)totpWithTouchId:(id<EMSecureString>)serverChallenge
                handler:(OTPCompletion)handler {
    [CMain.sharedInstance.managerToken.tokenDevice totpWithTouchId:^(id<EMSecureString> otp, id<EMAuthInput> input,
                                                                     id<EMSecureString> newServerChallenge, NSError *error) {
        // Pin fallback
        if (!otp && !error) {
            [self totpWithPin:newServerChallenge handler:handler];
        } else {
            handler(otp, input, newServerChallenge, error);
        }
    } withServerChallenge:serverChallenge];
}

// MARK: - Incoming messages

- (void)onIncomingMessage:(NSNotification *)notify {
    notifyDisplay(TRANSLATE(@"STRING_MESSAGING_INCOMING_MESSAGE"), NotifyTypeInfo);
    [self reloadGUI];
}

- (void)approveIncomingMessage:(NSString *)message
           withServerChallenge:(id<EMSecureString>)serverChallenge
             completionHandler:(void (^)(id<EMSecureString>))handler {
    // Mandatory parameter.
    assert(handler);
    if (!handler) {
        return;
    }
    
    // All auth types does have same handler at the and. This will allow to save some code.
    OTPCompletion helpHandler = ^(id<EMSecureString> otp, id<EMAuthInput> input,
                                  id<EMSecureString> serverChallenge, NSError *error) {
        if (otp) {
            handler(otp);
        } else {
            [self loadingIndicatorHide];
            notifyDisplayErrorIfExists(error);
        }
        
        [input wipe];
    };
    
    // Prepare simple dialog with two actions.
    [_incomingMessage showWithCaption:message approveHandler:^{
        [self.incomingMessage hide:YES];
        [self totpWithMostComfortableOne:serverChallenge handler:helpHandler];
        
        // We want to un-lock UI behind it.
        [self reloadGUI];
    } rejectHandler:^{
        [self.incomingMessage hide:YES];
        handler(nil);
        
        // We want to un-lock UI behind it.
        [self reloadGUI];
    } animated:YES];
    
    // We want to lock UI behind it.
    [self reloadGUI];
}

// MARK: - User Interface

- (IBAction)onButtonPressedBack:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
