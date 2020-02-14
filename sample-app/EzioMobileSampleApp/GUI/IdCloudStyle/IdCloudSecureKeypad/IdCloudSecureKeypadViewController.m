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

#import "IdCloudSecureKeypadViewController.h"
#import "IdCloudChangePinView.h"
#import "IdCloudPinEntryView.h"

@interface IdCloudSecureKeypadViewController () <EMSecureInputCustomUiDelegate, IdCloudTopViewDelegate>

@property (nonatomic, weak)     IBOutlet UIView                 *secureKeypadArea;
@property (nonatomic, weak)     IBOutlet UIView                 *pinArea;
@property (nonatomic, weak)     IBOutlet UIButton               *buttonBack;

@property (nonatomic, assign)   BOOL                            shouldLoadSecureKeypad;
@property (nonatomic, assign)   BOOL                            changePin;
@property (nonatomic, assign)   BOOL                            backButton;
@property (nonatomic, copy)     NSString                        *captionFirst;
@property (nonatomic, copy)     NSString                        *captionSecond;
@property (nonatomic, copy)     EMSecureInputUiOnFinish         handler;
@property (nonatomic, strong)   id<EMSecureInputBuilderV2>      builder;
@property (nonatomic, strong)   id<EMSecureInputUi>             secureInput;
@property (nonatomic, strong)   UIView<IdCloudTopViewProtocol>  *pinAreaContent;
@end

@implementation IdCloudSecureKeypadViewController

+ (instancetype)pinEntryWithCaption:(NSString *)caption
                         backButton:(BOOL)backbutton
                  completionHandler:(EMSecureInputUiOnFinish)handler {
    return [[IdCloudSecureKeypadViewController alloc] init:NO
                                              captionFirst:caption
                                             captionSecond:nil
                                                backButton:backbutton
                                         completionHandler:handler];
}

+ (instancetype)changePinWithCaptionFirst:(NSString *)captionFirst
                            captionSecond:(NSString *)captionSecond
                               backButton:(BOOL)backbutton
                        completionHandler:(EMSecureInputUiOnFinish)handler {
    return [[IdCloudSecureKeypadViewController alloc] init:YES
                                              captionFirst:captionFirst
                                             captionSecond:captionSecond
                                                backButton:backbutton
                                         completionHandler:handler];
}

- (instancetype)init:(BOOL)changePin
        captionFirst:(NSString *)captionFirst
       captionSecond:(NSString *)captionSecond
          backButton:(BOOL)backbutton
   completionHandler:(EMSecureInputUiOnFinish)handler {
    if (self = [super initWithNibName:NSStringFromClass(self.class)
                               bundle:[NSBundle bundleForClass:self.class]]) {
        self.shouldLoadSecureKeypad = YES;
        self.changePin              = changePin;
        self.captionFirst           = captionFirst;
        self.captionSecond          = captionSecond;
        self.backButton             = backbutton;
        self.handler                = handler;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    return self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (!_secureInput && _shouldLoadSecureKeypad) {
        [self initSecureKeypad];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_pinAreaContent) {
        if (_changePin) {
            self.pinAreaContent = [IdCloudChangePinView changePinViewWithFrame:_pinArea.bounds
                                                                  captionFirst:_captionFirst
                                                                 captionSecond:_captionSecond
                                                                      delegate:self];
        } else {
            self.pinAreaContent = [IdCloudPinEntryView pinEntryViewWithFrame:_pinArea.bounds
                                                                     caption:_captionFirst
                                                                    delegate:self];
        }
        [_pinArea addSubview:_pinAreaContent];
    }
    
    [_buttonBack setHidden:!_backButton];
    [self setShouldLoadSecureKeypad:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.shouldLoadSecureKeypad = NO;
}


// MARK: - Private Helpers

- (void)initSecureKeypad {
    // Set keypad design.
    self.builder = [[EMSecureInputService serviceWithModule:[EMUIModule uiModule]] secureInputBuilderV2];
    
    // Overall Design
    [_builder setKeypadFrameColor:[UIColor clearColor]];
    [_builder setKeyColor:[UIColor darkGrayColor] forState:EMSecureInputUiControlStateNormal];
    [_builder setButtonPressedVisibility:YES];
    [_builder setButtonBackgroundColor:[UIColor clearColor]
                              forState:EMSecureInputUiControlStateNormal];
    [_builder setKeypadViewRectInPortrait:_secureKeypadArea.bounds];
    [_builder setKeypadViewRectInLandscape:CGRectMake(_secureKeypadArea.bounds.origin.x, _secureKeypadArea.bounds.origin.x,
                                                      _secureKeypadArea.bounds.size.height, _secureKeypadArea.bounds.size.width)];
    [_builder setKeypadGridGradientColors:[UIColor clearColor] gridGradientEndColor:[UIColor blackColor]];
    [_builder swapOkAndDeleteButton];
    
    // Delete Button
    [_builder setDeleteButtonText:@"✕"];
    [_builder setDeleteButtonFont:[UIFont fontWithName:@"HelveticaNeue" size:35.0f]];
    [_builder setDeleteButtonGradientColors:[UIColor clearColor]
                     buttonGradientEndColor:[UIColor clearColor]
                                   forState:EMSecureInputUiControlStateNormal];
    [_builder setDeleteButtonGradientColors:[UIColor clearColor]
                     buttonGradientEndColor:[UIColor clearColor]
                                   forState:EMSecureInputUiControlStateDisabled];
    
    // Ok Button
    [_builder setOkButtonText:@"✔"];
    [_builder setOkButtonFont:[UIFont fontWithName:@"HelveticaNeue" size:30.0f]];
    [_builder setOkButtonGradientColors:[UIColor clearColor]
                 buttonGradientEndColor:[UIColor clearColor]
                               forState:EMSecureInputUiControlStateNormal];
    [_builder setOkButtonGradientColors:[UIColor clearColor]
                 buttonGradientEndColor:[UIColor clearColor]
                               forState:EMSecureInputUiControlStateDisabled];
    
    // Behaviour
    [_builder showTopScreen:NO];
    [_builder setMinimumInputLength:4 andMaximumInputLength:4];
    [_builder setOkButtonBehavior:EMSecureInputUiOkButtonCustom];
    
    [_builder validateUiConfiguration];
    
    // Build keypad and add handler.
    self.secureInput =
    [_builder buildWithScrambling:NO
               isDoubleInputField:_changePin
                         isDialog:NO
                    onFinishBlock:^(id<EMPinAuthInput> firstPin, id<EMPinAuthInput> secondPin) {
                        [self.builder wipe];
                        self.builder = nil;
                        self.secureInput = nil;
                        
                        [self dismissViewControllerAnimated:YES completion:nil];
                        if (self.handler) {
                            self.handler(firstPin, secondPin);
                        }
                    }];
    
    _secureInput.customUiDelegate = self;
    [self addChildViewController:_secureInput.viewController];
    [_secureKeypadArea addSubview:_secureInput.keypadView];
}

// MARK: - EMSecureInputCustomUiDelegate

- (void)secureInputUi:(id)caller keyPressedCountChanged:(NSInteger)count forInputField:(NSInteger)inputFieldIndex {
    [_pinAreaContent changeCharCount:count forIndex:inputFieldIndex];
}

- (void)secureInputUi:(id)caller selectedInputFieldChanged:(NSInteger)inputFieldIndex {
    [_pinAreaContent changeHighlightedIndex:inputFieldIndex];
}

- (void)secureInputUiOkButtonPressed:(id)caller {
    
}

- (void)secureInputUiDeleteButtonPressed:(id)caller {
    
}

// MARK: - IdCloudTopViewDelegate

- (void)onTopViewEntryChanged:(NSInteger)index {
    [_secureInput setSelectedInputFieldIndex:index];
    [_pinAreaContent changeHighlightedIndex:index];
}

// MARK: - User Interface

- (IBAction)onButtonPressedBack:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
