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

#import "IdCloudTextField.h"

@interface IdCloudTextField() <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIImageView *textIcon;

@end

@implementation IdCloudTextField

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
    // Get our view from storyboard.
    UIView *contentView = [[[NSBundle bundleForClass:self.class] loadNibNamed:NSStringFromClass(self.class) owner:self options:nil] firstObject];
    contentView.frame = frame;
    
    // Add it as child of current View.
    [self addSubview:contentView];
    
    _textField.delegate = self;
    
    // Make icon dark gray.
    [_textIcon setTintColor:[UIColor darkGrayColor]];
    
    // By default we don't have any chain.
    // This will update keyboard type.
    [self setResponderChain:nil];
}


// MARK: - IBInspectable

- (void)setIcon:(UIImage *)icon {
    [_textIcon setImage:icon];
    
    [self setNeedsLayout];
}

- (UIImage *)icon {
    return _textIcon.image;
}

- (void)setPlaceholder:(NSString *)placeholder {
    [_textField setPlaceholder:placeholder];
    
    [self setNeedsLayout];
}

- (NSString *)placeholder {
    return _textField.placeholder;
}

- (void)setText:(NSString *)text {
    [_textField setText:text];
    
    [self setNeedsLayout];
}

- (NSString *)text {
    return _textField.text;
}

- (void)setSecure:(BOOL)secure {
    [_textField setSecureTextEntry:secure];
    
    [self setNeedsLayout];
}

- (BOOL)enabled {
    return _textField.enabled;
}

- (void)setEnabled:(BOOL)enabled{
    [_textField setEnabled:enabled];
    
    [self setNeedsLayout];
}

- (BOOL)secure {
    return _textField.secureTextEntry;
}

- (void)setDecimalPad:(BOOL)decimalPad {
    [_textField setKeyboardType:decimalPad ? UIKeyboardTypeDecimalPad : UIKeyboardTypeDefault];
    
    [self setNeedsLayout];
}

- (BOOL)decimalPad {
    return _textField.keyboardType == UIKeyboardTypeDecimalPad;
}

// MARK: - Public API

- (BOOL)becomeFirstResponder {
    BOOL retValue = [super becomeFirstResponder];
    return [_textField becomeFirstResponder] && retValue;
}

- (BOOL)resignFirstResponder {
    BOOL retValue = [super resignFirstResponder];
    return [_textField resignFirstResponder] && retValue;
}

- (void)setResponderChain:(IdCloudTextField *)responderChain {
    _responderChain = responderChain;
    
    [_textField setReturnKeyType:responderChain ? UIReturnKeyNext : UIReturnKeyDone];
}

// MARK: - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // Hide current keyboard.
    [_textField resignFirstResponder];
    
    // Jump to next one.
    if (_responderChain) {
        [_responderChain becomeFirstResponder];
    }
    
    // All actions are allowed
    return YES;
}

// MARK: - User Interface

- (IBAction)onTextChanged:(UITextField *)sender {
    [_delegate onTextChanged:self];
}

@end
