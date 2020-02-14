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
#import "IdCloudAutorotationVC.h"

@interface IdCloudAutorotationVC ()

@property (nonatomic, assign) BOOL                          viewShouldRestore;
@property (nonatomic, assign) BOOL                          viewAutorotationRestore;
@property (nonatomic, assign) UIInterfaceOrientationMask    viewRotationMaskRestore;

@end

@implementation IdCloudAutorotationVC

// MARK: - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    _viewShouldRestore      = NO;
    _viewAutorotation       = NO;
    _viewRotationMask       = UIInterfaceOrientationMaskPortrait;
    _viewPreferedRotation   = UIInterfaceOrientationPortrait;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (_viewShouldRestore) {
        _viewAutorotation       = _viewAutorotationRestore;
        _viewRotationMask       = _viewRotationMaskRestore;
    }
}

- (BOOL)shouldAutorotate {
    return _viewAutorotation;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return _viewRotationMask;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return _viewPreferedRotation;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

// MARK:  - Public API

- (void)rotate:(UIInterfaceOrientation)orientation {
    // Save current settings. Will be returned after rotation in viewWillTransitionToSize.
    _viewAutorotationRestore    = _viewAutorotation;
    _viewRotationMaskRestore    = _viewRotationMask;
    _viewShouldRestore          = YES;
    
    // Allow rotation.
    _viewAutorotation   = YES;
    _viewRotationMask   = UIInterfaceOrientationMaskAll;
    
    // Force rotation.
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:orientation] forKey:@"orientation"];
    [UINavigationController attemptRotationToDeviceOrientation];
}


@end
