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

#import "IdCloudLoadingIndicator.h"

#define kIndicatorSize 125.f

@interface IdCloudLoadingIndicator()

@property (nonatomic, weak) IBOutlet IdCloudBackground          *background;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView    *indicator;
@property (nonatomic, weak) IBOutlet UILabel                    *labelCaption;

@end

@implementation IdCloudLoadingIndicator

// MARK: - Life Cycle

+ (instancetype)loadingIndicator {
    return [[IdCloudLoadingIndicator alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

- (void)initXIB {
    [super initXIB];
    
    // Actual view will be added as child. Make self transparent.
    self.backgroundColor = [UIColor clearColor];
    
    // Set visibility to true so internal check will not skip call
    _isPresent = YES;
    
    // By default it shloud be hidden.
    [self loadingBarShow:NO animated:NO];
    
    // Add shadow to content view.
    [IDCloudDesignableHelpers applyShadowToView:_background];
}

// MARK: - Public API

- (void)loadingBarShow:(BOOL)show
              animated:(BOOL)animated {
    // Avoid multiple call with same result.
    if (_isPresent == show) {
        return;
    }
    
    // Start / Stop iOS loading indicator animation.
    if (show) {
        [_indicator startAnimating];
    } else {
        [_indicator stopAnimating];
    }
    
    // Stop any possible previous animations since we are not waiting for result.
    [self.layer removeAllAnimations];
    
    // Animate transition.
    if (animated) {
        if (show) {
            self.hidden = NO;
        }
        
        [UIView animateWithDuration:.5
                              delay:.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.alpha = show ? 1. : .0;
                         } completion:^(BOOL finished) {
                             if (finished && !show)
                                 self.hidden = YES;
                         }];
    } else {
        self.alpha  = show ? 1. : .0;
        self.hidden = !show;
    }
    
    _isPresent = show;
    
    // Remove last label after hide.
    if (!show) {
        [_labelCaption setText:nil];
    }
}

- (void)setCaption:(NSString *)caption {
    [_labelCaption setText:caption];
}

@end
