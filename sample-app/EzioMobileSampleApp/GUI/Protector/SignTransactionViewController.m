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

#import "SignTransactionViewController.h"
#import <CommonCrypto/CommonDigest.h>

#import "OTPViewController.h"

@interface SignTransactionViewController () <IdCloudTextFieldDelegate>

@property (nonatomic, weak) IBOutlet IdCloudTextField   *textAmount;
@property (nonatomic, weak) IBOutlet IdCloudTextField   *textBeneficiary;
@property (nonatomic, weak) IBOutlet IdCloudButton      *buttonProcees;

@end

@implementation SignTransactionViewController

// MARK: - Life Cycle

+ (instancetype)viewController {
    return CreateVC(@"Protector", self);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add return button functionality for both textfields.
    [_textAmount        setDelegate:self];
    [_textBeneficiary   setDelegate:self];
    
    // Create chain of textfield that should become responders after each other.
    [_textAmount setResponderChain:_textBeneficiary];
    
    // Disable UI by default. Transition process looks better.
    [self enableGUI:NO];
}

// MARK: - MainViewController

- (void)enableGUI:(BOOL)enabled {
    [super enableGUI:enabled];
    
    [_buttonProcees     setEnabled:enabled && _textAmount.text.length && _textBeneficiary.text.length];
    [_textAmount        setEnabled:enabled];
    [_textBeneficiary   setEnabled:enabled];
}

// MARK: - User Interface

- (IBAction)onButtonPressedProceed:(IdCloudButton *)sender {
    [self totpWithMostComfortableOne:[self serverChallenge] handler:^(id<EMSecureString> otp,
                                                                      id<EMAuthInput> input,
                                                                      id<EMSecureString> serverChallenge,
                                                                      NSError *error) {
        // OTP Calculation was successfull.
        if (otp) {
            // Display result view. OTP Value will be recalculated with given auth input, we can ignore it not.
            OTPViewController *otpVC = [OTPViewController transactionSign:input
                                                          serverChallenge:serverChallenge
                                                                   amount:self.textAmount.text
                                                              beneficiary:self.textBeneficiary.text];
            // Hide current and display new VC.
            UIViewController *parent = self.presentingViewController;
            [self dismissViewControllerAnimated:YES completion:^{
                [parent presentViewController:otpVC animated:YES completion:nil];
            }];
        } else {
            // Something went wrong. Display reason.
            notifyDisplayErrorIfExists(error);
        }
    }];
}

// MARK: - IdCloudTextFieldDelegate

- (void)onTextChanged:(IdCloudTextField *)sender {
    // Process button is enabled only with both textbox filled.
    [self reloadGUI];
}

// MARK: - Private Helpers

- (id<EMSecureString>)serverChallenge {
    return [self ocraChallenge:@[[KeyValue create:@"amount"         value:_textAmount.text],
                                 [KeyValue create:@"beneficiary"    value:_textBeneficiary.text]]];
}

- (id<EMSecureString>)ocraChallenge:(NSArray<KeyValue *> *)values {
    // Use builder to append TLV
    NSMutableData *buffer = [NSMutableData new];

    // Go through all values, calculate and append TLV for each one of them.
    for (NSInteger i = 0; i < values.count; i++) {
        // Convert keyvalue to UTF8 string
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
