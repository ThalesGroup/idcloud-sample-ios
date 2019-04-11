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

#import "TokenDetail_AuthenticationVC.h"

@interface TokenDetail_AuthenticationVC()
@property (strong, nonatomic) OTPCompletion sendAuthRequest;
@end

@implementation TokenDetail_AuthenticationVC

// MARK: - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Helper to keep methods cleaner.
    _sendAuthRequest = ^(id<EMSecureString> otp, id<EMAuthInput> input, id<EMSecureString> serverChallenge, NSError *error) {
        [[CMain sharedInstance].managerHttp sendAuthRequest:otp authInput:input serverChallenge:serverChallenge error:error];
    };
}

// MARK: - User Interface

- (IBAction)onButtonPressedOTPPin:(UIButton *)sender
{
    [self totpWithPin:nil handler:[self handlerType:sender]];
}

- (IBAction)onButtonPressedOTPFaceId:(UIButton *)sender
{
    [self totpWithFaceId:nil handler:[self handlerType:sender]];
}

- (IBAction)onButtonPressedOTPGemaltoFaceId:(UIButton *)sender
{
    [self totpWithGemaltoFaceId:nil handler:[self handlerType:sender]];
}

- (IBAction)onButtonPressedOTPTouchId:(UIButton *)sender
{
    [self totpWithTouchId:nil handler:[self handlerType:sender]];
}

// MARK: - Private Helpers

- (OTPCompletion)handlerType:(UIButton *)sender
{
    return sender.tag == kOffline ? self.otpResultDisplay : _sendAuthRequest;
}

@end
