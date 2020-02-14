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

#import "IdCloudSideMenu.h"

// TODO: Add autorotation support.
// TODO: Cancel animation should keep current transform instead of final one.
//       Easiest way will be UIViewPropertyAnimator, but we are supporting older iOS version.

// MARK: - Visual configuration

// Maximum side menu with in percentage of portrait screen width. From 0-1
#define kWidth                  .7f
#define kWidthMax               350.f

// Side menu transition animation duration in seconds
#define kAnimationDuration      .5f

// Used for black layer when UIAccessibilityIsReduceTransparencyEnabled.
#define kAnimationBlackAlpha    .6f

@interface IdCloudSideMenu ()

@property (nonatomic, strong) UIViewController  *sideMenu;
@property (nonatomic, strong) UIViewController  *mainViewController;

@property (nonatomic, strong) UIView            *viewOverlay;
@property (nonatomic, assign) CGFloat           viewOverlayOpacity;
@property (nonatomic, assign) CGFloat           menuWidth;

@property (nonatomic, assign) CGAffineTransform sideMenuVisible;
@property (nonatomic, assign) CGAffineTransform sideMenuHidden;

@property (nonatomic, assign) BOOL              isMenuVisible;
@property (nonatomic, assign) BOOL              isUserInteractionEnabled;

@property (nonatomic, strong) NSNumber          *gestureStartX;


@end

@implementation IdCloudSideMenu

// MARK: - Life Cycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Load both view controllers
    self.sideMenu           = [self.storyboard instantiateViewControllerWithIdentifier:_sideMenuIdentifier];
    self.mainViewController = [self.storyboard instantiateViewControllerWithIdentifier:_mainViewIdentifier];

    // Check integrity.
    assert(_sideMenu && _mainViewController);
    
    // Add Main View controller.
    [self addChildViewController:_mainViewController];
    [self.view addSubview:_mainViewController.view];
    
    // Add overlay view to adjust transition effect catch touches etc.
    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.viewOverlay = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        self.viewOverlayOpacity = 1.f;
    } else {
        self.viewOverlay = [UIView new];
        _viewOverlay.backgroundColor = [UIColor blackColor];
        self.viewOverlayOpacity = kAnimationBlackAlpha;
    }
    _viewOverlay.frame              = self.view.frame;
    _viewOverlay.autoresizingMask   = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _viewOverlay.alpha              = .0f;
    
    // Tap on overlay to close menu.
    [_viewOverlay addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(onUserTap:)]];
    
    [self.view addSubview:_viewOverlay];
    
    // Add side menu.
    [self addChildViewController:_sideMenu];
    [self.view addSubview:_sideMenu.view];
    
    // Update sizes and prepare transformations
    self.menuWidth = MIN(kWidthMax, CGRectGetWidth(self.view.bounds) * kWidth);
    _sideMenu.view.frame = CGRectMake(-_menuWidth, .0f, _menuWidth, _sideMenu.view.frame.size.height);
    self.sideMenuHidden = _sideMenu.view.transform;
    self.sideMenuVisible = CGAffineTransformTranslate(_sideMenuHidden, _menuWidth, .0f);
    
    // Set default values.
    self.isMenuVisible              = NO;
    self.isUserInteractionEnabled   = YES;
    
    // Allow swipe gesture to open / close menu.
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onUserSwipe:)];
    panGesture.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panGesture];
}

// MARK: - Public API

- (void)menuDisplay {
    [self menuDisplay:.0f];
}

- (void)menuHide {
    [self menuHide:.0f];
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled {
    self.isUserInteractionEnabled = userInteractionEnabled;
}

// MARK: - Private Helpers

- (void)menuDisplay:(CGFloat)percentage {
    [self cancelCurrentAnimation];
    
    // Animate
    [UIView animateWithDuration:kAnimationDuration
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.sideMenu.view.transform   = self.sideMenuVisible;
                         self.viewOverlay.alpha         = self.viewOverlayOpacity;
                     } completion:^(BOOL finished) {
                         self.isMenuVisible = YES;
                     }];
}

- (void)menuHide:(CGFloat)percentage {
    [self cancelCurrentAnimation];
    
    // Animate
    [UIView animateWithDuration:kAnimationDuration
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.sideMenu.view.transform   = self.sideMenuHidden;
                         self.viewOverlay.alpha         = .0f;
                     } completion:^(BOOL finished) {
                         self.isMenuVisible = NO;
                     }];
}

- (void)cancelCurrentAnimation {
    [_sideMenu.view.layer   removeAllAnimations];
    [_viewOverlay.layer     removeAllAnimations];
}

// MARK: - User Interface

- (void)onUserTap:(UITapGestureRecognizer *)recognizer {
    if (!_isUserInteractionEnabled) {
        return;
    }
    
    [self cancelCurrentAnimation];
    [self menuHide];
}

- (void)onUserSwipe:(UIPanGestureRecognizer *)gestureRecognizer {
    if (!_isUserInteractionEnabled) {
        return;
    }
    
    CGPoint location    = [gestureRecognizer locationInView:self.view];
    CGPoint velocity    = [gestureRecognizer velocityInView:self.view];
    CGFloat frameWidth  = CGRectGetWidth(self.view.bounds);
    
    if (_gestureStartX == nil && (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
                                  gestureRecognizer.state == UIGestureRecognizerStateChanged)) {
        [self cancelCurrentAnimation];
        
        BOOL velocityReady = _isMenuVisible ? velocity.x < 0.0 : velocity.x > 0.0;
        
        if (velocityReady && (location.x < frameWidth * .35f || _isMenuVisible)) {
            self.gestureStartX = [NSNumber numberWithFloat:location.x];
        }
    } else if (_gestureStartX != nil) {
        CGFloat firstVar    = location.x - _gestureStartX.floatValue;
        if ((_isMenuVisible && firstVar > .0f) ||
            (!_isMenuVisible && firstVar < .0f)) {
            // Ignore inverse movement.
            firstVar = .0f;
        }
        
        CGFloat percentage  = MAX(MIN(fabs(firstVar / _menuWidth), 1.f), .0f);
        
        if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
            CGAffineTransform transform;
            CGFloat opacity;
            if (_isMenuVisible) {
                transform   = CGAffineTransformTranslate(_sideMenuVisible, -_menuWidth * percentage, .0f);
                opacity     = _viewOverlayOpacity * (1.f - percentage);
            } else {
                transform   = CGAffineTransformTranslate(_sideMenuHidden, _menuWidth * percentage, .0f);
                opacity     = _viewOverlayOpacity * percentage;
            }
            self.sideMenu.view.transform   = transform;
            self.viewOverlay.alpha         = opacity;
        }
        else if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
                 gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
            if (!_isMenuVisible) {
                if (velocity.x > 1000.f || percentage > .5f) {
                    [self menuDisplay:percentage];
                } else {
                    [self menuHide:percentage];
                }
            } else if (_isMenuVisible) {
                if (velocity.x < -1000.f || percentage > .5f) {
                    [self menuHide:percentage];
                } else {
                    [self menuDisplay:percentage];
                }
            }
            
            self.gestureStartX = nil;
        }
                 
    }

}
@end
