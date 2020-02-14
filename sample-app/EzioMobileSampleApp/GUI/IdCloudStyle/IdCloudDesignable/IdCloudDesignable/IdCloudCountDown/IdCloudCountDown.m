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

#import "IdCloudCountDown.h"

// UI Configuration
static const CGFloat    C_LINE_WIDTH        = 3.f;

#define kFontColour         [UIColor colorWithRed:27.f / 255.f green:27.f / 255.f blue:98.f / 255.f alpha:1.f]
#define kFontColourDisabled [UIColor colorWithRed:27.f / 255.f green:27.f / 255.f blue:98.f / 255.f alpha:1.f]

// Precalculated helpers
static const CGFloat    C_ANAGLE_START      = M_PI * 1.5;
static const CGFloat    C_ANAGLE_END        = C_ANAGLE_START + (M_PI * 2);

@interface IdCloudCountDown ()

@property (nonatomic, assign) NSInteger                 timeInMsEnd;
@property (nonatomic, assign) NSInteger                 timeInMsStart;
@property (nonatomic, strong) NSTimer                   *timer;
@property (nonatomic, strong) NSMutableParagraphStyle   *paragraphStyle;

@end

@implementation IdCloudCountDown

// MARK: - Life Cycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
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
    // Make view transparent.
    self.backgroundColor    = [UIColor clearColor];
    self.opaque             = NO;
    
    // Make sure, that ui is by default rendered as finished.
    _timeInMsStart  = 0;
    _timeInMsEnd    = 0;
    
    // Text style is still the same. We can preload it.
    self.paragraphStyle             = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    _paragraphStyle.lineBreakMode   = NSLineBreakByTruncatingTail;
    _paragraphStyle.alignment       = NSTextAlignmentCenter;
}

// MARK: - Drawing routine
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGFloat     radius          = MIN(rect.size.width, rect.size.height); // Size to fit.
    CGFloat     percentage      = 1.f;
    NSInteger   remainingSec    = 0;
    NSInteger   timeNow         = CACurrentMediaTime() * 1000;
    
    // We are within time period.
    if (timeNow < _timeInMsEnd) {
        remainingSec    = (_timeInMsEnd - timeNow) / 1000.f + 1;
        percentage      = (CGFloat)(timeNow - _timeInMsStart) / (CGFloat)(_timeInMsEnd - _timeInMsStart);
    } else {
        // Uschedule timer tick.
        [self stopCounter];
    }
    
    // Draw percentage circle.
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath addArcWithCenter:CGPointMake(rect.size.width / 2.f, rect.size.height / 2.f)
                          radius:radius / 2.f - C_LINE_WIDTH
                      startAngle:(C_ANAGLE_END - C_ANAGLE_START) * percentage + C_ANAGLE_START
                        endAngle:C_ANAGLE_START
                       clockwise:YES];
    bezierPath.lineWidth = C_LINE_WIDTH;
    if (_color) {
        [_color setStroke];
    }
    [bezierPath stroke];
    
    // Draw remaining time string.
    NSDictionary *attributes =
    @{
      // Font
      NSFontAttributeName:              [UIFont systemFontOfSize:radius / 7.f],
      // Alignment etc..
      NSParagraphStyleAttributeName:    _paragraphStyle,
      // Color based on state.
      NSForegroundColorAttributeName:   remainingSec ? kFontColour : kFontColourDisabled
      };
    
    // Prepare centered rect for text based on his size.
    NSString *caption   = [NSString stringWithFormat:@"%lds", (long)remainingSec];
    CGSize textSize     = [caption sizeWithAttributes:attributes];
    CGRect textRect     = CGRectMake(rect.origin.x,
                                     rect.origin.y + (rect.size.height - textSize.height) / 2.0,
                                     rect.size.width,
                                     textSize.height);
    
    [caption drawInRect:textRect withAttributes:attributes];
    
}

// MARK: - Private Helpers

- (void)onTimerTick:(NSTimer *)sender {
    // Force UI to redraw.
    [self setNeedsDisplay];
}

// MARK: - Public API

- (void)startCounter:(NSInteger)max current:(NSInteger)current {
    // Make sure there is no other animation running.
    [self stopCounter];
    
    // Get time period we want to display.
    _timeInMsStart = CACurrentMediaTime() * 1000 - (max - current) * 1000;
    _timeInMsEnd = CACurrentMediaTime() * 1000 + current * 1000;
    
    // Schedule timer to force redraw.
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0 // 60 fps
                                                  target:self
                                                selector:@selector(onTimerTick:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)startCounter:(NSInteger)seconds {
    // Make sure there is no other animation running.
    [self stopCounter];
    
    // Get time period we want to display.
    _timeInMsStart = CACurrentMediaTime() * 1000;
    _timeInMsEnd = _timeInMsStart + seconds * 1000;
    
    // Schedule timer to force redraw.
    // It's not as precise as CGD, but enough for this reason.
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0 // 60 fps
                                                  target:self
                                                selector:@selector(onTimerTick:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stopCounter {
    // Stop any previous animation
    if (_timer) {
        [_timer invalidate];
        self.timer = nil;
    }
}

// MARK: - IBInspectable

- (void)setColor:(UIColor *)color {
    _color = color;
    
    // Force UI to redraw.
    [self setNeedsDisplay];
}

@end
