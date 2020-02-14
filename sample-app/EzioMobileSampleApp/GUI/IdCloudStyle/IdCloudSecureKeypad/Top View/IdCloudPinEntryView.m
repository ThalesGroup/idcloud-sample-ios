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

#import "IdCloudPinEntryView.h"

@interface IdCloudPinEntryView()

@property (nonatomic, weak) IBOutlet UILabel            *labelCaption;
@property (nonatomic, weak) IBOutlet UIStackView        *stackCharacters;
@property (nonatomic, weak) id<IdCloudTopViewDelegate>  delegate;

@end

@implementation IdCloudPinEntryView

// MARK: - Life Cycle

+ (instancetype)pinEntryViewWithFrame:(CGRect)frame
                              caption:(NSString *)caption
                             delegate:(id<IdCloudTopViewDelegate>)delegate {
    return [[IdCloudPinEntryView alloc] initWithFrame:frame caption:caption delegate:delegate];
}

- (instancetype)initWithFrame:(CGRect)frame
                      caption:(NSString *)caption
                     delegate:(id<IdCloudTopViewDelegate>)delegate {
    if (self = [super initWithFrame:frame]) {
        [self changeCaption:caption forIndex:0];
        
        self.autoresizingMask   = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.delegate           = delegate;
        
        // Prepare UI for initial usage.
        [self reset];
    }
    
    return self;
}

// MARK: - IdCloudTopViewProtocol

- (void)changeHighlightedIndex:(NSInteger)index {
    for (IdCloudPinChar *loopChar in _stackCharacters.arrangedSubviews) {
        [loopChar setIsHighlighted:index == 0];
    }
}

- (void)changeCaption:(NSString *)caption forIndex:(NSInteger)index {
    // Invalid index.
    if (index) {
        assert(NO);
        return;
    }
    
    [_labelCaption setText:caption];
}

- (void)changeCharCount:(NSInteger)charcount forIndex:(NSInteger)index {
    // Invalid index.
    if (index) {
        assert(NO);
        return;
    }
    
    for (NSInteger loopIndex = 0; loopIndex < _stackCharacters.arrangedSubviews.count; loopIndex++) {
        IdCloudPinChar *pinChar = (IdCloudPinChar *)[_stackCharacters.arrangedSubviews objectAtIndex:loopIndex];
        [pinChar setIsPresent:loopIndex < charcount];
    }
}

- (void)reset {
    [self changeCharCount:0 forIndex:0];
    [self changeHighlightedIndex:0];
}


@end
