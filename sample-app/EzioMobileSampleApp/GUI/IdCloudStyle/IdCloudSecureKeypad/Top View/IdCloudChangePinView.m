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

#import "IdCloudChangePinView.h"

@interface IdCloudChangePinView()

@property (nonatomic, weak) IBOutlet UILabel            *labelCaptionFirst;
@property (nonatomic, weak) IBOutlet UILabel            *labelCaptionSecond;
@property (nonatomic, weak) IBOutlet UIStackView        *stackCharactersFirst;
@property (nonatomic, weak) IBOutlet UIStackView        *stackCharactersSecond;
@property (nonatomic, weak) id<IdCloudTopViewDelegate>  delegate;

@end

@implementation IdCloudChangePinView

// MARK: - Life Cycle

+ (instancetype)changePinViewWithFrame:(CGRect)frame
                          captionFirst:(NSString *)captionFirst
                         captionSecond:(NSString *)captionSecond
                              delegate:(id<IdCloudTopViewDelegate>)delegate {
    return [[IdCloudChangePinView alloc] initWithFrame:frame
                                          captionFirst:captionFirst
                                         captionSecond:captionSecond
                                              delegate:delegate];
}

- (instancetype)initWithFrame:(CGRect)frame
                 captionFirst:(NSString *)captionFirst
                captionSecond:(NSString *)captionSecond
                     delegate:(id<IdCloudTopViewDelegate>)delegate {
    if (self = [super initWithFrame:frame]) {
        [self changeCaption:captionFirst forIndex:0];
        [self changeCaption:captionSecond forIndex:1];
        
        self.autoresizingMask   = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.delegate           = delegate;
        
        // Tap to identify stack view.
        [_stackCharactersFirst addGestureRecognizer:
         [[UITapGestureRecognizer alloc] initWithTarget:self
                                                 action:@selector(onUserTapFirst:)]];
        
        // Tap to identify stack view.
        [_stackCharactersSecond addGestureRecognizer:
         [[UITapGestureRecognizer alloc] initWithTarget:self
                                                 action:@selector(onUserTapSecond:)]];
        
        // Prepare UI for initial usage.
        [self reset];
    }
    
    return self;
}

// MARK: - IdCloudTopViewProtocol

- (void)changeHighlightedIndex:(NSInteger)index {
    for (IdCloudPinChar *loopChar in _stackCharactersFirst.arrangedSubviews) {
        [loopChar setIsHighlighted:index == 0];
    }
    
    for (IdCloudPinChar *loopChar in _stackCharactersSecond.arrangedSubviews) {
        [loopChar setIsHighlighted:index == 1];
    }
}

- (void)changeCaption:(NSString *)caption forIndex:(NSInteger)index {
    UILabel *labelCaption;
    if (index == 0) {
        labelCaption = _labelCaptionFirst;
    } else if (index == 1) {
        labelCaption = _labelCaptionSecond;
    } else {
        // Invalid index.
        assert(NO);
        return;
    }
    
    [labelCaption setText:caption];
}

- (void)changeCharCount:(NSInteger)charcount forIndex:(NSInteger)index {
    UIStackView *stackView;
    if (index == 0) {
        stackView = _stackCharactersFirst;
    } else if (index == 1) {
        stackView = _stackCharactersSecond;
    } else {
        // Invalid index.
        assert(NO);
        return;
    }
    
    for (NSInteger loopIndex = 0; loopIndex < stackView.arrangedSubviews.count; loopIndex++) {
        IdCloudPinChar *pinChar = (IdCloudPinChar *)[stackView.arrangedSubviews objectAtIndex:loopIndex];
        [pinChar setIsPresent:loopIndex < charcount];
    }
}

- (void)reset {
    [self changeCharCount:0 forIndex:0];
    [self changeCharCount:0 forIndex:1];
    [self changeHighlightedIndex:0];
}


// MARK: - User Interface

- (void)onUserTapFirst:(UITapGestureRecognizer *)recognizer {
    [_delegate onTopViewEntryChanged:0];
}

- (void)onUserTapSecond:(UITapGestureRecognizer *)recognizer {
    [_delegate onTopViewEntryChanged:1];
}

@end
