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

#import "TokenDetail_TransactionVC.h"
#import <CommonCrypto/CommonDigest.h>

@interface TokenDetail_TransactionVC () <UITextFieldDelegate>

@property (weak, nonatomic)     IBOutlet UITextField    *textAmount;
@property (weak, nonatomic)     IBOutlet UITextField    *textBeneficiary;
@property (strong, nonatomic)   OTPCompletion           sendTransactionRequest;

@end

@implementation TokenDetail_TransactionVC

// MARK: - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Helper to keep methods cleaner.
    __weak __typeof(self) weakSelf = self;
    _sendTransactionRequest = ^(id<EMSecureString> otp, id<EMAuthInput> input, id<EMSecureString> serverChallenge, NSError *error) {
        if (weakSelf) {
            [[CMain sharedInstance].managerHttp sendSignRequest:otp
                                                      authInput:input
                                                serverChallenge:serverChallenge
                                                          error:error
                                                         amount:weakSelf.textAmount.text
                                                    beneficiary:weakSelf.textBeneficiary.text];
        }
    };
    
    // Add return button functionality for both textfields.
    [_textAmount setDelegate:self];
    [_textBeneficiary setDelegate:self];
}

// MARK: - MainViewControllerProtocol

- (void)reloadGUI
{
    [super reloadGUI];
    
    if (!self.loadingIndicator.isPresent) {
        [_textAmount        setEnabled:YES];
        [_textBeneficiary   setEnabled:YES];
    }
}

- (void)disableGUI
{
    [super disableGUI];
    
    [_textAmount        setEnabled:NO];
    [_textBeneficiary   setEnabled:NO];
}

- (void)hideKeyboard
{
    // Hide keyboard if user will tap on View.
    [_textAmount        resignFirstResponder];
    [_textBeneficiary   resignFirstResponder];
}


// MARK: - User Interface

- (IBAction)onButtonPressedOTPPin:(UIButton *)sender
{
    [self totpWithPin:[self serverChallenge] handler:[self handlerType:sender]];
}

- (IBAction)onButtonPressedOTPFaceId:(UIButton *)sender
{
    [self totpWithFaceId:[self serverChallenge] handler:[self handlerType:sender]];
}

- (IBAction)onButtonPressedOTPGemaltoFaceId:(UIButton *)sender
{
    [self totpWithGemaltoFaceId:[self serverChallenge] handler:[self handlerType:sender]];
}

- (IBAction)onButtonPressedOTPTouchId:(UIButton *)sender
{
    [self totpWithTouchId:[self serverChallenge] handler:[self handlerType:sender]];
}

// MARK: - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Hide current keyboard.
    [textField resignFirstResponder];
    
    // All actions are allowed
    return YES;
}

// MARK: - Private Helpers

- (OTPCompletion)handlerType:(UIButton *)sender
{
    return sender.tag == kOffline ? self.otpResultDisplay : _sendTransactionRequest;
}

- (id<EMSecureString>)serverChallenge
{
    return [self ocraChallenge:@[[KeyValue create:@"amount" value:_textAmount.text],
                                 [KeyValue create:@"beneficiary" value:_textBeneficiary.text]]];
}

- (id<EMSecureString>)ocraChallenge:(NSArray<KeyValue *> *)values
{
    // Use builder to append TLV
    NSMutableData *buffer = [NSMutableData new];
    
    // Go through all values, calculate and append TLV for each one of them.
    for (NSInteger i = 0; i < values.count; i++) {
        // Convert key-value to UTF8 string
        NSData *keyValueUTF8 = [values[i] keyValueUTF8];
        
        // TLV tag DF71 from first item.
        Byte tlvTag1 = 0xDF;
        Byte tlvTag2 = 0x71 + i;
        Byte tlvLength = (Byte)keyValueUTF8.length;
        
        [buffer appendBytes:&tlvTag1 length:1];
        [buffer appendBytes:&tlvTag2 length:1];
        [buffer appendBytes:&tlvLength length:1];
        [buffer appendData:keyValueUTF8];
    }
    
    // Calculate digest
    NSMutableData *retValue = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(buffer.bytes, (CC_LONG)buffer.length, retValue.mutableBytes);

    return [[retValue hexStringRepresentation] secureString];
}

@end
