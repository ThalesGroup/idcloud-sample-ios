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

#import "RootViewController.h"

@interface RootViewController()

@property (nonatomic, strong) UIViewController *currentVC;

@end

@implementation RootViewController

// MARK: - Public API

- (void)switchToViewController:(UIViewController *)newVC {
    if (!_currentVC) {
        self.currentVC = newVC;
        _currentVC.view.frame = self.view.bounds;
        [self addChildViewController:_currentVC];
        [self.view addSubview:_currentVC.view];
        [_currentVC didMoveToParentViewController:self];
    } else {
        if (_currentVC.presentedViewController) {
            // Put two masking screenshots to bottom of view hierarchy, so we can hide whole stack and keep
            // screen to looking same as now. That way animation will looks like direclty from current VC to new one.
            // Also all transition layers will be correctly deallocated.
            [self addScreenshotToMaskTransition:_currentVC.view];
            [self addScreenshotToMaskTransition:_currentVC.presentedViewController.view];
            
            [_currentVC dismissViewControllerAnimated:NO completion:^{
                [self transitionToVC:newVC];
            }];
        } else {
            [self transitionToVC:newVC];
        }
    }
}

// MARK: - Private Helpers

- (void)transitionToVC:(UIViewController *)newVC {
    // Prepare the two view controllers for the change.
    [self.currentVC willMoveToParentViewController:nil];
    [self addChildViewController:newVC];
    
    [self transitionFromViewController:self.currentVC
                      toViewController:newVC
                              duration:.5
                               options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCurlUp
                            animations:nil
                            completion:^(BOOL finished) {
                                [self.currentVC removeFromParentViewController];
                                [newVC didMoveToParentViewController:self];
                                
                                self.currentVC = newVC;
                            }];
}

- (void)addScreenshotToMaskTransition:(UIView *)view {
    UIView *screen = [[UIApplication sharedApplication].delegate.window snapshotViewAfterScreenUpdates:false];
    [view insertSubview:screen atIndex:NSIntegerMax];
}

@end
