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

#import "ProvisionerViewController.h"
#import "IdCloudQrCodeReader.h"

@interface ProvisionerViewController() <IdCloudQrCodeReaderDelegate, IdCloudTextFieldDelegate>

@property (nonatomic, weak) IBOutlet IdCloudTextField   *textUserId;
@property (nonatomic, weak) IBOutlet IdCloudTextField   *textRegCode;

@property (nonatomic, weak) IBOutlet UIButton           *buttonEnrollManually;
@property (nonatomic, weak) IBOutlet UIButton           *buttonEnrollQr;

@end

@implementation ProvisionerViewController

// MARK: - Life Cycle

+ (instancetype)viewController {
    return CreateVC(@"Protector", self);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add return button functionality for both textfields.
    [_textUserId    setDelegate:self];
    [_textRegCode   setDelegate:self];
    
    // Create chain of textfield that should become responders after each other.
    [_textUserId    setResponderChain:_textRegCode];
    
    // Disable UI by default. Transition process looks better.
    [self enableGUI:NO];
}

// MARK: - MainViewController

- (void)enableGUI:(BOOL)enabled {
    [super enableGUI:enabled];
    
    // Enable provision buttxzon only when both user id and registration code are provided.
    [_buttonEnrollManually  setEnabled:enabled && _textUserId.text.length && _textRegCode.text.length];
    [_buttonEnrollQr        setEnabled:enabled];
    [_textUserId            setEnabled:enabled];
    [_textRegCode           setEnabled:enabled];
}

// MARK: - User interface

- (IBAction)onButtonPressedEnrollManually:(UIButton *)sender {
    [self enrollWithUserId:_textUserId.text andRegistrationCode:[_textRegCode.text secureString]];
}

- (IBAction)onButtonPressedEnrollQr:(UIButton *)sender {
    // Display QR code reader with current view as delegate.
    [self presentViewController:[IdCloudQrCodeReader readerWithDelegate:self] animated:YES completion:nil];
}

// MARK: - Private Helpers

- (void)enrollWithUserId:(NSString *)userId
     andRegistrationCode:(id<EMSecureString>)regCode {
    CMain *main = CMain.sharedInstance;
    
    // Disable whole UI and display loading indicator.
    [self loadingIndicatorShowWithCaption:TRANSLATE(@"STRING_LOADING_ENROLLING")];
    
    // Do provisioning and wait for response.
    [main.managerToken provisionWithUserId:userId
                          registrationCode:regCode
                         completionHandler:^(id<EMOathToken> token, NSError *error)
     {
         // From this point we don't need regCode.
         [regCode wipe];
         
         // Hide loading indicator and reload gui.
         [self loadingIndicatorHide];
         
         // Token was created. Switch tabs.
         if (token) {
             [self.textUserId setText:nil];
             [self.textRegCode setText:nil];
             [main updateRootViewController];
         } else {
             // Token was not created? Display error.
             notifyDisplayErrorIfExists(error);
         }
     }];
}

- (void)enrollWithQrCode:(id<EMSecureByteArray>)qrCode {
    // Try to parse data from provided QR Code. Actual operation is synchronous. We can use self in block directly.
    QRCodeManager *manager = CMain.sharedInstance.managerQRCode;
    [manager parseQRCode:qrCode
       completionHandler:^(BOOL successful, NSString *userId, id<EMSecureString> regCode, NSError *error) {
           // Wipe sensitive data.
           [qrCode wipe];
           
           // Parsing was successful.
           if (successful) {
               [self enrollWithUserId:userId andRegistrationCode:regCode];
           } else {
               notifyDisplayErrorIfExists(error);
               [self reloadGUI];
           }
       }];
}

// MARK: - IdCloudQrCodeReaderDelegate

- (void)onQRCodeProvided:(IdCloudQrCodeReader *)sender
                  qrCode:(id<EMSecureByteArray>)qrCode {
    
    // Hide QR Code Reader and continue after animation.
    // We might speed up this process by not waiting for animation, but this looks better.
    [sender dismissViewControllerAnimated:YES completion:^{
        [self enrollWithQrCode:qrCode];
    }];
}

// MARK: - IdCloudTextFieldDelegate

- (void)onTextChanged:(IdCloudTextField *)sender {
    // Provision button is enabled only with both textbox filled.
    [self reloadGUI];
}


@end
