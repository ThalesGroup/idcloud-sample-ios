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

#import "IdCloudBackground.h"

@interface IdCloudBackground()

@property (nonatomic, strong) CAGradientLayer   *gradientLayer;
@property (nonatomic, strong) UIImageView       *imageView;

@end

@implementation IdCloudBackground

// MARK: - Lifecycle

+ (Class)layerClass {
    return CAGradientLayer.class;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initGradientLayer];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initGradientLayer];
    }
    
    return self;
}

- (void)initGradientLayer {
    if (!_gradientLayer) {
        self.gradientLayer = (CAGradientLayer *)self.layer;
        _gradientLayer.locations = @[@0.0, @0.4, @1.0];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Gradient
    if (_gradientStart && _gradientMiddle && _gradientEnd) {
        _gradientLayer.colors = @[(id)_gradientStart.CGColor, (id)_gradientMiddle.CGColor, (id)_gradientEnd.CGColor];
    } else {
        _gradientLayer.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor clearColor].CGColor, (id)[UIColor clearColor].CGColor];
    }

    if (_image) {
        if (!_imageView) {
            self.imageView = [UIImageView new];
            [self insertSubview:_imageView atIndex:0];
        }
        _imageView.image = _image;
        _imageView.frame = self.bounds;
    } else if (_imageView) {
        [_imageView removeFromSuperview];
        self.imageView = nil;
    }
}

// MARK: - IBInspectable

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    _gradientLayer.cornerRadius = cornerRadius;
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    _gradientLayer.borderColor = borderColor.CGColor;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    _gradientLayer.borderWidth = borderWidth;
}

- (void)setGradientStart:(UIColor *)gradientStart {
    _gradientStart = gradientStart;
    [self setNeedsLayout];
}

- (void)setGradientMiddle:(UIColor *)gradientMiddle {
    _gradientMiddle = gradientMiddle;
    [self setNeedsLayout];
}
- (void)setGradientEnd:(UIColor *)gradientEnd {
    _gradientEnd = gradientEnd;
    [self setNeedsLayout];
}

- (void)setImage:(UIImage *)image {
    _image = image;
    [self setNeedsLayout];
}


// MARK: - Public API

- (UIImage *)renderImage
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, .0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *retValue = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return retValue;
}
@end
