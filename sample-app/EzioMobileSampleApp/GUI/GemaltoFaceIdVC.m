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

#import "GemaltoFaceIdVC.h"

@interface GemaltoFaceIdVC ()

@property (weak, nonatomic) IBOutlet UILabel        *labelFaceIdStatusValue;
@property (weak, nonatomic) IBOutlet UILabel        *labelEntrollerTitle;
@property (weak, nonatomic) IBOutlet UIButton       *buttonEnrollNewFaceId;

@end

@implementation GemaltoFaceIdVC

// MARK: - MainViewControllerProtocol

- (void)reloadGUI
{
    [super reloadGUI];
    
    // Display current gemalto face id status.
    BOOL                enabled = NO;
    GemaloFaceIdState   state   = [CMain sharedInstance].faceIdState;
    switch (state)
    {
        case GemaloFaceIdStateUndefined:
            [_labelFaceIdStatusValue setText:NSLocalizedString(@"GEMALTO_FACE_ID_STATE_UNDEFINED", nil)];
            [_labelFaceIdStatusValue setTextColor:[UIColor redColor]];
            break;
        case GemaloFaceIdStateNotSupported:
            [_labelFaceIdStatusValue setText:NSLocalizedString(@"GEMALTO_FACE_ID_STATE_NOT_SUPPORTED", nil)];
            [_labelFaceIdStatusValue setTextColor:[UIColor redColor]];
            break;
        case GemaloFaceIdStateReadyToUse:
            [_labelFaceIdStatusValue setText:NSLocalizedString(@"GEMALTO_FACE_ID_STATE_READY", nil)];
            [_labelFaceIdStatusValue setTextColor:[UIColor greenColor]];
            enabled = YES;
            break;
        case GemaloFaceIdStateInited:
            [_labelFaceIdStatusValue setText:NSLocalizedString(@"GEMALTO_FACE_ID_STATE_INITED", nil)];
            [_labelFaceIdStatusValue setTextColor:[UIColor orangeColor]];
            enabled = YES;
            break;
        case GemaloFaceIdStateLicensed:
            [_labelFaceIdStatusValue setText:NSLocalizedString(@"GEMALTO_FACE_ID_STATE_LICENSED", nil)];
            [_labelFaceIdStatusValue setTextColor:[UIColor orangeColor]];
            break;
        case GemaloFaceIdStateUnlicensed:
            [_labelFaceIdStatusValue setText:NSLocalizedString(@"GEMALTO_FACE_ID_STATE_UNLICENSED", nil)];
            [_labelFaceIdStatusValue setTextColor:[UIColor redColor]];
            break;
        case GemaloFaceIdStateInitFailed:
            [_labelFaceIdStatusValue setText:NSLocalizedString(@"GEMALTO_FACE_ID_STATE_INIT_FAILED", nil)];
            [_labelFaceIdStatusValue setTextColor:[UIColor redColor]];
            break;
    }
    
    // Hide bottom section if it's not relevant.
    _labelEntrollerTitle.hidden     = state != GemaloFaceIdStateInited && state != GemaloFaceIdStateReadyToUse;
    _buttonEnrollNewFaceId.hidden   = state != GemaloFaceIdStateInited && state != GemaloFaceIdStateReadyToUse;
    
    // Button is only enabled if face id is inited or ready to use.
    [_buttonEnrollNewFaceId setEnabled:enabled && !self.loadingIndicator.isPresent];
    
    if (state == GemaloFaceIdStateInited)
        [_buttonEnrollNewFaceId setTitle:NSLocalizedString(@"GEMALTO_FACE_ID_ENROLL", nil) forState:UIControlStateNormal];
    else
        [_buttonEnrollNewFaceId setTitle:NSLocalizedString(@"GEMALTO_FACE_ID_UNENROLL", nil) forState:UIControlStateNormal];
}

// MARK: - User interface

- (IBAction)onButtonPressedEnrollNewFaceId:(UIButton *)sender
{
    // Do proper action based on current state.
    if ([CMain sharedInstance].faceIdState == GemaloFaceIdStateInited)
        [self enroll];
    else
        [self unenroll];
}

// MARK: - Private Helpers

- (void)enroll
{
    __weak __typeof(self) weakSelf = self;
    [EMFaceManager enrollWithPresentingViewController:self timeout:60 completion:^(EMFaceManagerProcessStatus code) {
        // View is gone. We can exit.
        if (!weakSelf)
            return;
        
        // Display possible errors.
        if (code == EMFaceManagerProcessStatusFail)
            [weakSelf showError:[[EMFaceManager sharedInstance] faceStatusError]];
        
        // Notify others.
        [[CMain sharedInstance] updateGemaltoFaceIdStatus];
        
    }];
}

- (void)unenroll
{
    __weak __typeof(self) weakSelf = self;
    [EMFaceManager unenrollWithCompletion:^(EMFaceManagerProcessStatus code) {
        // View is gone. We can exit.
        if (!weakSelf)
            return;
        
        // Display possible errors.
        if (code == EMFaceManagerProcessStatusFail)
            [weakSelf showError:[[EMFaceManager sharedInstance] faceStatusError]];
        
        // Notify others.
        [[CMain sharedInstance] updateGemaltoFaceIdStatus];
    }];
}

@end
