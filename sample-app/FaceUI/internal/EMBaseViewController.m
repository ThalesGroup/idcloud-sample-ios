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

#import "EMBaseViewController.h"
#import "EMFaceMessageHelper.h"
#import "EMFaceManager.h"
#import "EMFaceConstant.h"

@interface EMBaseViewController () <EMFaceAuthUIDelegate>
@end

@implementation EMBaseViewController
+(UIColor *) red         { return [UIColor colorWithRed:226.0/255.0 green:35.0/255.0 blue:0.0/255.0 alpha:1.0];}
+(UIColor *) green { return [UIColor colorWithRed:130.0/255.0 green:188.0/255.0 blue:0.0/255.0 alpha:1.0];}
+(UIColor *) textActive { return [UIColor colorWithRed:64.0/255.0 green:64.0/255.0 blue:64.0/255.0 alpha:1.0];}
+(UIColor *) textInactive { return [UIColor colorWithRed:167.0/255.0 green:169.0/255.0 blue:171.0/255.0 alpha:1.0];}

- (void) setupButton:(UIButton*) button {
    [button setTitleColor:[EMBaseViewController textActive] forState:UIControlStateNormal];
    [button setTitleColor:[EMBaseViewController textInactive] forState:UIControlStateDisabled];
    button.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    button.layer.shadowOpacity = 0.5f;
    button.layer.shadowOffset = CGSizeZero;
    button.layer.shadowRadius = 2.0f;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.timeout = 60;
    UIImage *image = [UIImage imageNamed:navigationBarLogoRessourceName inBundle:[NSBundle faceUIBundle] compatibleWithTraitCollection:nil];
    self.navItem.titleView = [[UIImageView alloc] initWithImage:image];

    [self initialStep];
}

- (void) initialStep {
//    [self setupButton:self.startButton];
//    [self setupButton:self.cancelButton];
    
    [self.startButton setTitle:StartButtonTitle forState:UIControlStateNormal];
    [self.cancelButton setTitle:CancelButtonTitle forState:UIControlStateNormal];
    
    [self setupStartButtonWithHidden:YES andEnable:NO];
    [self setupStatusLabelWithText:@" " andBlinkLabel:@" "];

    self.faceViewContainer.layer.borderColor = [EMBaseViewController red].CGColor;
    self.faceViewContainer.layer.borderWidth = 4.0f;
    
    self.successView.hidden = YES;
}


- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.faceViewContainer.layer.cornerRadius = self.faceViewContainer.bounds.size.width / 2.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) imageDidUpdate:(UIImage *)image {
    [self.overContainer setHidden:NO];
    [self.faceViewContainer setFaceImage:image];
}


- (void) stepDidChange:(EMFaceUIDelegateStep)step {
    switch (step) {
        case EMFaceUIDelegateStepWaitStart: {
            [self configureOverContainerWithHidden:NO andAnimation:NO];
            [self setupStartButtonWithHidden:NO andEnable:YES];
            [self setupStatusLabelWithText:@" " andBlinkLabel:@" "];
            self.faceViewContainer.layer.borderColor = [EMBaseViewController green].CGColor;
            break;
        }
        case EMFaceUIDelegateStepProcessing: {
            [self configureOverContainerWithHidden:NO andAnimation:YES];
            [self setupStartButtonWithHidden:YES andEnable:NO];
            [self setupStatusLabelWithText:@" " andBlinkLabel:@" "];
            self.faceViewContainer.layer.borderColor = [EMBaseViewController green].CGColor;
            break;
        }
            
        case EMFaceUIDelegateStepSuccess: {
            [self configureOverContainerWithHidden:YES andAnimation:NO];
            [self setupStartButtonWithHidden:YES andEnable:NO];
            if (!self.autoDismissWhenComplete) {
                [self displaySuccessView];
            }
            [self setupStatusLabelWithText:@" " andBlinkLabel:@" "];
            break;
        }
        case EMFaceUIDelegateStepError: {
            [self setupStartButtonWithHidden:NO andEnable:NO];
            [self configureOverContainerWithHidden:NO andAnimation:NO];
            [self setupStatusLabelWithText:@" " andBlinkLabel:@" "];
            self.faceViewContainer.layer.borderColor = [EMBaseViewController red].CGColor;
            break;
        }
        case EMFaceUIDelegateStepCancel: {
            [self setupStartButtonWithHidden:YES andEnable:NO];
            [self configureOverContainerWithHidden:YES andAnimation:NO];
            [self setupStatusLabelWithText:@" " andBlinkLabel:@" "];
            break;
        }
        
                
        case EMFaceUIDelegateStepEnrollWaitFace: {
            [self setupStartButtonWithHidden:NO andEnable:NO];
            [self configureOverContainerWithHidden:NO andAnimation:NO];
            self.faceViewContainer.layer.borderColor = [EMBaseViewController red].CGColor;
            [self setupStatusLabelWithText:VerificationFaceOutTitle.uppercaseString andBlinkLabel:@" "];
            break;
        }
            
        case EMFaceUIDelegateStepAddFace: {
            [self setupStartButtonWithHidden:NO andEnable:NO];
            [self configureOverContainerWithHidden:NO andAnimation:NO];
            [self setupStatusLabelWithText:@"" andBlinkLabel:@" "];
            self.faceViewContainer.layer.borderColor = [EMBaseViewController green].CGColor;
            break;
        }
            
        case EMFaceUIDelegateStepBlink: {
            [self setupStartButtonWithHidden:YES andEnable:NO];
            [self configureOverContainerWithHidden:NO andAnimation:NO];
            [self setupStatusLabelWithText:@" " andBlinkLabel:VerificationBlinkTitle.uppercaseString];
            self.faceViewContainer.layer.borderColor = [EMBaseViewController green].CGColor;
            break;
        }
        case EMFaceUIDelegateStepKeepStill: {
            [self setupStartButtonWithHidden:YES andEnable:NO];
            [self configureOverContainerWithHidden:NO andAnimation:NO];
            [self setupStatusLabelWithText:@" " andBlinkLabel:VerificationKeepStillTitle.uppercaseString];
            self.faceViewContainer.layer.borderColor = [EMBaseViewController green].CGColor;
            break;
        }
        default:
            break;
    }
}

- (IBAction)cancelProcess:(id)sender {
}

- (IBAction)startProcess:(id)sender {
}


#pragma private functions
-(void) configureOverContainerWithHidden:(BOOL)isHidden andAnimation:(BOOL)isAnimated
{
    [self.overContainer setHidden:isHidden];
    if (isAnimated) {
        [self.overContainer startAnimating];
    } else {
        [self.overContainer stopAnimating];
    }
}

-(void) setupStartButtonWithHidden:(BOOL)isHidden andEnable:(BOOL)isEnabled
{
    self.startButton.hidden = isHidden;
    self.startButton.enabled = isEnabled;
}

-(void) setupStatusLabelWithText:(NSString *)statusLabel andBlinkLabel:(NSString *)blinkLabel
{
    [self.statusLabel setText:statusLabel];
    [self.blinkLabel setText:blinkLabel];
    
}

-(void) displaySuccessView {
    self.successView.hidden = NO;
    [self.cancelButton setTitle:ContinueButtonTitle forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}
@end
