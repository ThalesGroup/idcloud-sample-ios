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

#import "OTPViewController.h"
#import "RootViewController.h"

@interface OTPViewController ()

@property (nonatomic, weak)     IBOutlet UILabel            *labelOTPType;
@property (nonatomic, weak)     IBOutlet UILabel            *labelOTPValue;
@property (nonatomic, weak)     IBOutlet IdCloudCountDown   *countDownValidity;
@property (nonatomic, weak)     IBOutlet UIButton           *buttonBack;
@property (nonatomic, weak)     IBOutlet IdCloudButton      *buttonVerifyOnline;

@property (nonatomic, strong)   id<EMAuthInput>             authInput;
@property (nonatomic, strong)   id<EMSecureString>          serverChallenge;

@property (nonatomic, strong)   NSTimer                     *otpTimer;

@property (nonatomic, copy)     NSString                    *amount;
@property (nonatomic, copy)     NSString                    *beneficiary;

@end

@implementation OTPViewController

// MARK: - Life Cycle

+ (instancetype)authentication:(id<EMAuthInput>)input {
    return [OTPViewController transactionSign:input serverChallenge:nil amount:nil beneficiary:nil];
}

+ (instancetype)transactionSign:(id<EMAuthInput>)input
                serverChallenge:(id<EMSecureString>)serverChallenge
                         amount:(NSString *)amount
                    beneficiary:(NSString *)beneficiary {
    OTPViewController *retValue = CreateVC(@"Protector", self);
    
    retValue.authInput              = input;
    retValue.serverChallenge        = serverChallenge;
    retValue.amount                 = amount;
    retValue.beneficiary            = beneficiary;
    
    return retValue;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_serverChallenge) {
        _labelOTPType.text = TRANSLATE(@"STRING_OTP_TYPE_TRANSACTION_SIGN");
    } else {
        _labelOTPType.text = TRANSLATE(@"STRING_OTP_TYPE_AUTHENTICATION");
    }
    
    // Schedule timer for periodical check of OTP lifetime
    if (!_otpTimer) {
        self.otpTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                         target:self
                                                       selector:@selector(onTimerTick:)
                                                       userInfo:nil
                                                        repeats:YES];
    }
    
    // Load current value.
    [self updateOTPValue:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Invalidate timer so view can properly deallocated.
    [_otpTimer invalidate];
    self.otpTimer = nil;
    
    // Stop animation. It's no longer needed.
    [_countDownValidity stopCounter];
}

- (void)dealloc {
    [_authInput wipe];
    self.authInput = nil;
    
    [_serverChallenge wipe];
    self.serverChallenge = nil;
}

// MARK: - MainViewController

- (void)enableGUI:(BOOL)enabled {
    [super enableGUI:enabled];
    
    [_buttonBack            setEnabled:enabled];
    [_buttonVerifyOnline    setEnabled:enabled];
}

// MARK: - User Interface

- (IBAction)onButtonPressedVerifyOnline:(IdCloudButton *)sender {
    // Display loading indicator
    [self loadingIndicatorShowWithCaption:TRANSLATE(@"STRING_LOADING_VALIDATING")];
    
    TokenDevice *tokenDevice = CMain.sharedInstance.managerToken.tokenDevice;
    [tokenDevice totpWithAuthInput:_authInput
               withServerChallenge:_serverChallenge
                 completionHandler:^(id<EMSecureString> otp, id<EMAuthInput> input, id<EMSecureString> serverChallenge, NSError *error) {
                     HttpManager *manager = CMain.sharedInstance.managerHttp;
                     if (serverChallenge) {
                         [manager sendSignRequest:otp.stringValue
                                           amount:self.amount
                                      beneficiary:self.beneficiary
                                completionHandler:^(BOOL success, NSString *message) {
                                    [self handleResult:success message:message];
                                }];
                     } else {
                         [manager sendAuthRequest:otp.stringValue
                                completionHandler:^(BOOL success, NSString *message) {
                                    [self handleResult:success message:message];
                                }];
                     }
                 }];
}

// MARK: - Timer tick

- (void)onTimerTick:(NSTimer *)sender {
    // Current OTP value is no longer valid. Calculate new one.
    NSInteger lastOtpLifespan = CMain.sharedInstance.managerToken.tokenDevice.device.lastOtpLifespan;
    if (lastOtpLifespan <= 0) {
        [self updateOTPValue:YES];
    }
}

// MARK: - Private Helpers

- (void)updateOTPValue:(BOOL)animated {
    // Re-calculate OTP
    TokenDevice *tokenDevice = CMain.sharedInstance.managerToken.tokenDevice;
    [tokenDevice totpWithAuthInput:_authInput
               withServerChallenge:_serverChallenge
                 completionHandler:^(id<EMSecureString> otp, id<EMAuthInput> input, id<EMSecureString> serverChallenge, NSError *error) {
                     if (otp) {
                         // Animate OTP value change.
                         if (animated) {
                             CATransition *animation    = [CATransition animation];
                             animation.timingFunction   = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                             animation.type             = kCATransitionPush;
                             animation.duration         = .5;
                             [self.labelOTPValue.layer addAnimation:animation forKey:nil];
                         }
                         
                         // Get mutable copy of OTP. We might want to format it based on size.
                         NSMutableString *otpValue = [otp.stringValue mutableCopy];
                         
                         // Format longer OTP's
                         if (otpValue.length > 4) {
                             [otpValue insertString:@" " atIndex:otpValue.length / 2];
                         }
                         self.labelOTPValue.text = otpValue;
                         
                         // Update count down timer.
                         [self.countDownValidity startCounter:tokenDevice.lifespan
                                                      current:tokenDevice.device.lastOtpLifespan];
                     } else {
                         // Display possible issues.
                         notifyDisplayErrorIfExists(error);
                     }
                 }];
}

- (void)handleResult:(BOOL)success message:(NSString *)message {    
    // On succesfull authentication or transaction sign go back to home screen.
    if (success) {
        [self dismissViewControllerAnimated:YES completion:^{
            notifyDisplay(message, NotifyTypeInfo);
        }];
    } else {
        [self loadingIndicatorHide];
        notifyDisplay(message, success ? NotifyTypeInfo : NotifyTypeError);
    }
}

@end
