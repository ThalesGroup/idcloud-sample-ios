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

#import "HomeViewController.h"
#import "AppDelegate.h"
#import "SettingsViewController.h"
#import "SignTransactionViewController.h"
#import "OTPViewController.h"
#import "SideMenuViewController.h"

@interface HomeViewController ()

@property (nonatomic, weak) IBOutlet IdCloudButton  *buttonAuthentication;
@property (nonatomic, weak) IBOutlet IdCloudButton  *buttonSignTransaction;
@property (nonatomic, weak) IBOutlet IdCloudButton  *buttonPullMessage;
@property (nonatomic, weak) IBOutlet UIButton       *buttonSettings;

@end

@implementation HomeViewController

// MARK: - Life Cycle

+ (instancetype)viewController {
    return CreateVC(@"Protector", self);
}

// MARK: - MainViewController

- (void)reloadGUI {
    [super reloadGUI];

    // Update atributed title on pull message button.
    NSAttributedString          *pullAttribs    = [_buttonPullMessage attributedTitleForState:UIControlStateNormal];
    NSMutableAttributedString   *newText        = [[NSMutableAttributedString alloc] initWithAttributedString:pullAttribs];
    if ([CMain.sharedInstance.managerPush isIncomingMessageInQueue]) {
        [newText.mutableString setString:TRANSLATE(@"STRING_MESSAGING_BUTTON_OPEN")];
    } else {
        [newText.mutableString setString:TRANSLATE(@"STRING_MESSAGING_BUTTON_PULL")];
    }
    [_buttonPullMessage setAttributedTitle:newText forState:UIControlStateNormal];
}

- (void)enableGUI:(BOOL)enabled {
    [super enableGUI:enabled];
    
    [_buttonAuthentication  setEnabled:enabled];
    [_buttonSignTransaction setEnabled:enabled];
    [_buttonPullMessage     setEnabled:enabled];
    [_buttonSettings        setEnabled:enabled];
    
    IdCloudSideMenu *sideMenu = (IdCloudSideMenu *)self.parentViewController;
    [sideMenu setUserInteractionEnabled:enabled];
}

- (__kindof IdCloudIncomingMessage *)createIncomingMessageView {
    return [IdCloudIncomingMessage incomingMessage];
}

// MARK: - User Interface

- (IBAction)onButtonPressedSettings:(UIButton *)sender {
    IdCloudSideMenu *sideMenu = (IdCloudSideMenu *)self.parentViewController;
    [sideMenu menuDisplay];
}

- (IBAction)onButtonPressedAuthentication:(IdCloudButton *)sender {
    [self totpWithMostComfortableOne:nil handler:^(id<EMSecureString> otp, id<EMAuthInput> input, id<EMSecureString> serverChallenge, NSError *error) {
        // OTP Calculation was successfull.
        if (otp) {
            // Display result view. OTP Value will be recalculated with given auth input, we can ignore it now.
            [self presentViewController:[OTPViewController authentication:input] animated:YES completion:nil];
        } else {
            // Something went wrong. Display reason.
            notifyDisplayErrorIfExists(error);
        }
    }];
}

- (IBAction)onButtonPressedSignTransaction:(IdCloudButton *)sender {
    [self presentViewController:[SignTransactionViewController viewController] animated:YES completion:nil];
}

- (IBAction)onButtonPressedPullMessage:(IdCloudButton *)sender {
    // Whole fetch flow goes through same flow as incoming push notification.
    [CMain.sharedInstance.managerPush fetchMessagesWithHandler:self];
}

// MARK: - Incoming messages

- (void)onIncomingMessage:(NSNotification *)notify {
    // Incoming push notification on main screen while is still visible and no loading bar is in front
    // can be processed automatically.
    // Do not call super. That will display toast notification.
    if (![self overlayViewVisible]) {
        [CMain.sharedInstance.managerPush fetchMessagesWithHandler:self];
    }
}


@end
