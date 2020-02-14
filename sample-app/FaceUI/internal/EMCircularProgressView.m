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

#import "EMCircularProgressView.h"

@interface EMCircularProgressView() {
    CALayer *_progressLayer;
}
@end

@implementation EMCircularProgressView
+(UIColor *) green { return [UIColor colorWithRed:130.0/255.0 green:188.0/255.0 blue:0.0/255.0 alpha:1.0];}

- (void) startAnimating {
    if (self.isAnimated) {
        return;
    }
    self.animated = YES;
    if (_progressLayer) {
        [_progressLayer removeFromSuperlayer];
    }
    CGFloat size = self.bounds.size.width;
    CGFloat borderSize = self.borderWith;
    [self addGraintCircleWithBounds:CGRectMake(0.0f, 0.0f, size + borderSize, size + borderSize + 1.0f)
                           Position:CGPointMake(size / 2.0f, size / 2.0f)
                          FromColor:[UIColor whiteColor]
                            ToColor:[EMCircularProgressView green]
                          LineWidth:borderSize];
}

- (void) stopAnimating {
    if (!self.animated) {
        return;
    }
    self.animated = NO;
    [_progressLayer removeFromSuperlayer];
}

-(void)addGraintCircleWithBounds:(CGRect)bounds Position:(CGPoint)position FromColor:(UIColor *)fromColor ToColor:(UIColor *)toColor LineWidth:(CGFloat) linewidth{
    
    CALayer *graintCircle = [CALayer new];
    
    graintCircle.bounds = bounds;
    graintCircle.position = position;
    NSArray * colors = [self graintFromColor:fromColor ToColor:toColor Count:4.0];
    for (int i = 0; i < colors.count -1; i++) {
        CAGradientLayer * graint = [CAGradientLayer layer];
        graint.bounds = CGRectMake(0,0,CGRectGetWidth(bounds)/2,CGRectGetHeight(bounds)/2);
        NSValue * valuePoint = [[self positionArrayWithMainBounds:graintCircle.bounds] objectAtIndex:i];
        graint.position = valuePoint.CGPointValue;
        UIColor * fromColor = colors[i];
        UIColor * toColor = colors[i+1];
        NSArray *colors = [NSArray arrayWithObjects:(id)fromColor.CGColor, toColor.CGColor, nil];
        NSNumber *stopOne = [NSNumber numberWithFloat:0.0];
        NSNumber *stopTwo = [NSNumber numberWithFloat:1.0];
        NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, nil];
        graint.colors = colors;
        graint.locations = locations;
        graint.startPoint = ((NSValue *)[[self startPoints] objectAtIndex:i]).CGPointValue;
        graint.endPoint = ((NSValue *)[[self endPoints] objectAtIndex:i]).CGPointValue;
        [graintCircle addSublayer:graint];
    }
    
    //Set mask
    CAShapeLayer * shapelayer = [CAShapeLayer layer];
    CGRect rect = CGRectMake(0,0,CGRectGetWidth(graintCircle.bounds) - 2 * linewidth, CGRectGetHeight(graintCircle.bounds) - 2 * linewidth);
    shapelayer.bounds = rect;
    shapelayer.position = CGPointMake(CGRectGetWidth(graintCircle.bounds)/2, CGRectGetHeight(graintCircle.bounds)/2);
    shapelayer.strokeColor = [UIColor blueColor].CGColor;
    shapelayer.fillColor = [UIColor clearColor].CGColor;
    shapelayer.path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:CGRectGetWidth(rect)/2].CGPath;
    shapelayer.lineWidth = linewidth;
    shapelayer.lineCap = kCALineCapRound;
    shapelayer.strokeStart = 0.0f;
    shapelayer.strokeEnd = 1.0f;
    [graintCircle setMask:shapelayer];
    
    _progressLayer = graintCircle;
    [self.layer addSublayer:_progressLayer];
    [self animateCircle:self.animationDuration];
}

- (void) animateCircle:(NSTimeInterval) duration {
    CAMediaTimingFunction* linearCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    
    animation.fromValue = @(0.0f);
    animation.toValue = @(M_PI*2.0f);
    animation.duration = duration;
    animation.timingFunction = linearCurve;
    animation.removedOnCompletion = NO;
    animation.repeatCount = HUGE_VALF;
    animation.fillMode = kCAFillModeForwards;
    animation.autoreverses = NO;
    
    CAShapeLayer *circleMask = (CAShapeLayer*)self.layer.mask;
    circleMask.strokeEnd = 1.0f;
    circleMask.strokeStart = 0.0f;
    
    [_progressLayer addAnimation:animation forKey:@"rotate"];
}

-(NSArray *)positionArrayWithMainBounds:(CGRect)bounds{
    CGPoint first = CGPointMake(CGRectGetWidth(bounds)/4 *3, CGRectGetHeight(bounds)/4 *1);
    CGPoint second = CGPointMake(CGRectGetWidth(bounds)/4 *3, CGRectGetHeight(bounds)/4 *3);
    CGPoint thrid = CGPointMake(CGRectGetWidth(bounds)/4 *1, CGRectGetHeight(bounds)/4 *3);
    CGPoint fourth = CGPointMake(CGRectGetWidth(bounds)/4 *1, CGRectGetHeight(bounds)/4 *1);
    return @[[NSValue valueWithCGPoint:first],
             [NSValue valueWithCGPoint:second],
             [NSValue valueWithCGPoint:thrid],
             [NSValue valueWithCGPoint:fourth]];
}
-(NSArray *)startPoints{
    return @[[NSValue valueWithCGPoint:CGPointMake(0,0)],
             [NSValue valueWithCGPoint:CGPointMake(1,0)],
             [NSValue valueWithCGPoint:CGPointMake(1,1)],
             [NSValue valueWithCGPoint:CGPointMake(0,1)]];
}
-(NSArray *)endPoints{
    return @[[NSValue valueWithCGPoint:CGPointMake(1,1)],
             [NSValue valueWithCGPoint:CGPointMake(0,1)],
             [NSValue valueWithCGPoint:CGPointMake(0,0)],
             [NSValue valueWithCGPoint:CGPointMake(1,0)]];
}
-(NSArray *)graintFromColor:(UIColor *)fromColor ToColor:(UIColor *)toColor Count:(NSInteger)count{
    CGFloat fromR = 0.0,fromG = 0.0,fromB = 0.0,fromAlpha = 0.0;
    [fromColor getRed:&fromR green:&fromG blue:&fromB alpha:&fromAlpha];
    CGFloat toR = 0.0,toG = 0.0,toB = 0.0,toAlpha = 0.0;
    [toColor getRed:&toR green:&toG blue:&toB alpha:&toAlpha];
    NSMutableArray * result = [[NSMutableArray alloc] init];
    for (int i = 0; i <= count; i++) {
        CGFloat oneR = fromR + (toR - fromR)/count * i;
        CGFloat oneG = fromG + (toG - fromG)/count * i;
        CGFloat oneB = fromB + (toB - fromB)/count * i;
        CGFloat oneAlpha = fromAlpha + (toAlpha - fromAlpha)/count * i;
        UIColor * onecolor = [UIColor colorWithRed:oneR green:oneG blue:oneB alpha:oneAlpha];
        [result addObject:onecolor];
    }
    return result;
}
-(UIColor *)midColorWithFromColor:(UIColor *)fromColor ToColor:(UIColor*)toColor Progress:(CGFloat)progress{
    CGFloat fromR = 0.0,fromG = 0.0,fromB = 0.0,fromAlpha = 0.0;
    [fromColor getRed:&fromR green:&fromG blue:&fromB alpha:&fromAlpha];
    CGFloat toR = 0.0,toG = 0.0,toB = 0.0,toAlpha = 0.0;
    [toColor getRed:&toR green:&toG blue:&toB alpha:&toAlpha];
    CGFloat oneR = fromR + (toR - fromR) * progress;
    CGFloat oneG = fromG + (toG - fromG) * progress;
    CGFloat oneB = fromB + (toB - fromB) * progress;
    CGFloat oneAlpha = fromAlpha + (toAlpha - fromAlpha) * progress;
    UIColor * onecolor = [UIColor colorWithRed:oneR green:oneG blue:oneB alpha:oneAlpha];
    return onecolor;
}

@end
