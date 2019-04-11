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

#import "EMEnrollViewController.h"
#import "EMFaceEnrollManager.h"
#import "EMFaceMessageHelper.h"

@interface EMEnrollViewController()<EMFaceAuthLicenseBuilderDelegate> {
}


@end

@implementation EMEnrollViewController{
    UIAlertController *waitingAlert;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [self.overContainer setBorderWith:24.0f];
    [self.overContainer setAnimationDuration:5.f];
}

- (void) stepDidChange:(EMFaceUIDelegateStep)step {
    [super stepDidChange:step];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self doEnroll];
}

- (void)doEnroll
{
    if ([[EMFaceManager sharedInstance] isInitialized]) {
        [[EMFaceEnrollManager sharedInstance] startEnrollmentWithDelegate:self timeout:self.timeout completionHandler:^(EMStatus status){
            switch (status) {
                case EM_STATUS_AUTHENTICATION_FACIAL_SUCCESS:
                    NSLog(@"Executing success handler");
                    self.completionHandler(EMFaceManagerProcessStatusSuccess);
                    break;
                case EM_STATUS_AUTHENTICATION_FACIAL_CANCELED:
                    self.completionHandler(EMFaceManagerProcessStatusCancel);
                    break;
                default: {
                    [[EMFaceManager sharedInstance] setFaceStatusError:[EMFaceBaseManager faceStatusToNSString:status]];
                    self.completionHandler(EMFaceManagerProcessStatusFail);
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[EMFaceMessageHelper getErrorMessageForErrorCode:status] preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:RetryButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                         [self performSelector:@selector(doEnroll) withObject:nil afterDelay:1.0f];
                    }]];
                    [alert addAction:[UIAlertAction actionWithTitle:CancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        [self cancelProcess:nil];
                    }]];

                    [self presentViewController:alert animated:true completion:^{
                        [self stepDidChange:EMFaceUIDelegateStepWaitStart];
                    }];
                    break;
                }
            }
            
        }];
    } else {
        [self performSelector:@selector(doEnroll) withObject:nil afterDelay:1.0f];
    }
}

- (IBAction)startProcess:(id)sender
{
    [[EMFaceEnrollManager sharedInstance] userIsReady];
}

- (IBAction)cancelProcess:(id)sender
{
    [[EMFaceEnrollManager sharedInstance] cancelFaceOperation];
    [self dismissViewControllerAnimated:YES completion:nil];
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
