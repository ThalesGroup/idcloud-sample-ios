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

#import "EMVerifyViewController.h"
#import "EMFaceVerifyManager.h"
#import "EMFaceMessageHelper.h"
#import "EMFaceManager.h"

@interface EMVerifyViewController (){
}

@end

@implementation EMVerifyViewController{
    UIAlertController *waitingAlert;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [self.overContainer setBorderWith:20.0f];
    [self.overContainer setAnimationDuration:2.f];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self runVerify];
}

- (void) runVerify {
    
    [[EMFaceVerifyManager sharedInstance] verifyWithAuthenticable:self.authenticatable
                                                       delegate:self
                                                        timeout:self.timeout
                                                     completion:(^(id<EMFaceAuthInput> authInput,NSError *error){
        if(!error){
            [self stepDidChange:EMFaceUIDelegateStepSuccess];
            if (self.completionHandler) {
                self.completionHandler(EMFaceManagerProcessStatusSuccess,authInput);
            }
            if (self.autoDismissWhenComplete) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }else{
            EMStatus status = (EMStatus) [error code];
            switch(status){
                case EM_STATUS_AUTHENTICATION_FACIAL_CANCELED: {
                    if (self.completionHandler) {
                        self.completionHandler(EMFaceManagerProcessStatusCancel,nil);
                    }
                    if (self.autoDismissWhenComplete) {
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    break;
                }
                default:
                {
                    [[EMFaceManager sharedInstance] setFaceStatusError:[error localizedDescription]];
                    self.completionHandler(EMFaceManagerProcessStatusFail,nil);
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[EMFaceMessageHelper getErrorMessageForErrorCode:status] preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:RetryButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self runVerify];
                    }]];
                    [alert addAction:[UIAlertAction actionWithTitle:CancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        [self cancelProcess:nil];
                    }]];

                    [self presentViewController:alert animated:true completion:^{}];
                    break;
                }
            }
        }
    })];
}

- (IBAction)startProcess:(id)sender {
    [self runVerify];
}

- (IBAction)cancelProcess:(id)sender {
    [[EMFaceVerifyManager sharedInstance] cancelFaceOperation];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) stepDidChange:(EMFaceUIDelegateStep)step {
    [super stepDidChange:step];
}

- (void)licenseBuilderWillStartFetchingLicenseFromServer:(EMFaceAuthLicenseBuilder *)licenseBuilder
{
    waitingAlert = [UIAlertController alertControllerWithTitle:@"Please Wait"
                                                        message:@"Fetching license from server..."
                                                 preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:waitingAlert animated:YES completion:nil];
}
- (void)licenseBuilder:(EMFaceAuthLicenseBuilder *)licenseBuilder didEndFetchingLicenseWithStatus:(BOOL)status error:(NSError *)error
{
    [waitingAlert dismissViewControllerAnimated:YES completion:nil];
}


@end
