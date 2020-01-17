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

#import "ProvisionVC.h"
#import "QRCodeReaderVC.h"
#import "LoadingIndicatorView.h"


@interface ProvisionVC () <QRCodeReaderDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel        *labelDomainValue;

@property (weak, nonatomic) IBOutlet UITextField    *textUserId;
@property (weak, nonatomic) IBOutlet UITextField    *textRegCode;

@property (weak, nonatomic) IBOutlet UIButton       *buttonEnrollQr;
@property (weak, nonatomic) IBOutlet UIButton       *buttonEnrollManually;

@end

@implementation ProvisionVC

// MARK: - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Add return button functionality for both textfields.
    [_textUserId    setDelegate:self];
    [_textRegCode   setDelegate:self];
    
    _labelDomainValue.text  = C_CFG_OOB_DOMAIN();
}

// MARK: - MainViewControllerProtocol

- (void)reloadGUI
{
    [super reloadGUI];
    
    if (self.loadingIndicator.isPresent) {
        [self disableGUI];
    } else {
        // Enable provision button only when both user id and registration code are provided.
        [_buttonEnrollManually  setEnabled:_textUserId.text.length && _textRegCode.text.length];
        [_buttonEnrollQr        setEnabled:YES];
        [_textUserId            setEnabled:YES];
        [_textRegCode           setEnabled:YES];
    }
}

- (void)disableGUI
{
    [super disableGUI];
    
    [_textRegCode           setEnabled:NO];
    [_textUserId            setEnabled:NO];
    [_buttonEnrollManually  setEnabled:NO];
    [_buttonEnrollQr        setEnabled:NO];
}

- (void)hideKeyboard
{ 
    // Hide keyboard if user will tap on View.
    [_textUserId resignFirstResponder];
    [_textRegCode resignFirstResponder];
}

// MARK: - Helpers

- (void)enrollWithUserId:(NSString *)userId andRegistrationCode:(id<EMSecureString>)regCode
{
    CMain *main = [CMain sharedInstance];
    
    // Disable whole UI and display loading indicator.
    [self loadingIndicatorShowWithCaption:NSLocalizedString(@"LOADING_MESSAGE_ENROLLING", nil)];
    
    // Do provisioning and wait for response.
    __weak __typeof(self) weakSelf = self;
    [main.managerToken provisionWithUserId:userId
                          registrationCode:regCode
                         completionHandler:^(id<EMOathToken> token, NSError *error)
     {
        // From this point we don't need regCode.
        [regCode wipe];
        
        // View is gone. We can exit.
        if (!weakSelf) {
            return;
        }
        
        // Hide loading indicator and reload gui.
        [weakSelf loadingIndicatorHide];
        
        // Token was created. Switch tabs.
        if (token) {
            [weakSelf.textUserId setText:nil];
            [weakSelf.textRegCode setText:nil];
            [main switchTabToCurrentState:YES];
        }
        else // Token was not created? Display error.
            [weakSelf showNSErrorIfExists:error];
    }];
}

// MARK: - User interface

- (IBAction)onButtonPressedEnrollQr:(UIButton *)sender
{
    // Display QR code reader with current view as delegate.
    QRCodeReaderVC *qrReaderVC = [[CMain sharedInstance] getViewController:[StoryItem itemQrReader]];
    [qrReaderVC init:self customTag:0];
    
    [self.navigationController pushViewController:qrReaderVC animated:YES];
}
- (IBAction)onButtonPressedEnrollManually:(UIButton *)sender
{
    [self enrollWithUserId:_textUserId.text andRegistrationCode:[_textRegCode.text secureString]];
}
- (IBAction)onTextChangedUserId:(UITextField *)sender
{
    // Provision button is enabled only with both text-boxes filled.
    [self reloadGUI];
}
- (IBAction)onTextChangedRegCode:(UITextField *)sender
{
    // Provision button is enabled only with both text-boxes filled.
    [self reloadGUI];
}

// MARK: - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Hide current keyboard.
    [textField resignFirstResponder];
    
    // Jump to next one.
    if ([textField isEqual:_textUserId]) {
        [_textRegCode becomeFirstResponder];
    }
    
    // All actions are allowed
    return YES;
}


// MARK: - QRCodeReaderDelegate

- (void)onQRCodeProvided:(QRCodeReaderVC *)sender qrCode:(id<EMSecureByteArray>)qrCode
{
    // Try to parse data from provided QR Code. Actual operation is synchronous. We can use self in block directly.
    [[CMain sharedInstance].managerQRCode parseQRCode:qrCode
                                    completionHandler:^(BOOL successful, NSString *userId, id<EMSecureString> regCode, NSError *error)
     {
        // Parsing was successful.
        if (successful) {
            [self enrollWithUserId:userId andRegistrationCode:regCode];
        } else {
            // Update states and check for errors.
            [self showNSErrorIfExists:error];
            [self reloadGUI];
        }
    }];
}

@end
