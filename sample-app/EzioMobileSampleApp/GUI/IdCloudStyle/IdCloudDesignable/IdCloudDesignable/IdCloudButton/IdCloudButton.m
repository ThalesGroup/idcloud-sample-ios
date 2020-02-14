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

#import "IdCloudButton.h"

@interface IdCloudButton()

@property (nonatomic, assign) BOOL internalHighlighted;

@end

@implementation IdCloudButton

// MARK: - Life Cycle

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self setupWithFrame:self.bounds];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupWithFrame:frame];
    }
    
    return self;
}

- (void)setupWithFrame:(CGRect)frame {
    _internalHighlighted = NO;
    
    // Make sure, that icon does not goes gray when system dialog is present.
    [self setTintAdjustmentMode:UIViewTintAdjustmentModeNormal];
    
    [self updateColor];
}

- (void)setHighlighted:(BOOL)highlighted {
    // Do not call super. We want custom behaviour.
    _internalHighlighted = highlighted;
    
    [self updateColor];
}

- (BOOL)isHighlighted {
    return _internalHighlighted;
}


- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    
    [self updateColor];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (_iconLeftTextCenter) {
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        CGRect availableSpace = UIEdgeInsetsInsetRect(self.bounds, self.contentEdgeInsets);
        CGFloat availableWidth = availableSpace.size.width
        - (self.imageView ? self.imageView.frame.size.width : .0f)
        - (self.titleLabel ? self.titleLabel.frame.size.width : .0f);
        
        self.titleEdgeInsets = UIEdgeInsetsMake(.0f, availableWidth * .5f, .0f, .0f);
    }
    
    [self updateColor];
}

// MARK: - Private Helpers

- (void)updateOverallColor:(UIColor *)color tint:(UIColor *)tint {
    self.backgroundColor        = color;
        
    self.layer.borderColor      = tint.CGColor;
    self.tintColor              = tint;
    self.titleLabel.textColor   = tint;
    
    [self setTitleColor:tint forState:UIControlStateNormal | UIControlStateHighlighted | UIControlStateDisabled];
}

- (void)updateColor {
    if (_shadow) {
        self.layer.borderWidth      = .0f;
        self.layer.shadowOpacity    = .0f;
        self.layer.shadowColor      = [UIColor blackColor].CGColor;
        self.layer.shadowOffset     = CGSizeMake(1.f, 1.f);
        self.layer.shadowRadius     = .5f;
    }

    if ([self isEnabled]) {
        if ([self isHighlighted]) {
            [self updateOverallColor:_buttonColorHighlighted tint:_buttonTintColorHighlighted];
        } else {
            if (_shadow) {
                self.layer.shadowOpacity = .9f;
            }
            [self updateOverallColor:_buttonColor tint:_buttonTintColor];
        }
    } else {
        if (_shadow) {
            self.layer.borderWidth = 1.f;
        }
        [self updateOverallColor:_buttonColorDisabled tint:_buttonTintColorHighlighted];
    }
}

// MARK: - IBInspectable

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    
    [self.layer setCornerRadius:cornerRadius];
}

-(void)setButtonColor:(UIColor *)buttonColor {
    _buttonColor = buttonColor;
    
    [self updateColor];
}

-(void)setButtonColorHighlighted:(UIColor *)buttonColorHighlighted {
    _buttonColorHighlighted = buttonColorHighlighted;
    
    [self updateColor];
}

- (void)setButtonTintColor:(UIColor *)buttonTintColor {
    _buttonTintColor = buttonTintColor;
    
    [self updateColor];
}

- (void)setButtonTintColorHighlighted:(UIColor *)buttonTintColorHighlighted {
    _buttonTintColorHighlighted = buttonTintColorHighlighted;
    
    [self updateColor];
}

-(void)setButtonColorDisabled:(UIColor *)buttonColorDisabled {
    _buttonColorDisabled = buttonColorDisabled;
    
    [self updateColor];
}

- (void)setIconLeftTextCenter:(BOOL)iconLeftTextCenter {
    _iconLeftTextCenter = iconLeftTextCenter;
    
    [self setNeedsLayout];
}

- (void)setShadow:(BOOL)shadow {
    _shadow = shadow;
    
    [self updateColor];
}

@end
