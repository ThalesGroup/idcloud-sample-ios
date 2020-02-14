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

#import "NotifyAction.h"

#define kIconInfoName       @"IdCloudNotificationInfo"
#define kIconInfoColor      [UIColor colorWithRed:.035f green:.33f blue:.94f alpha:1.f]

#define kIconWarningName    @"IdCloudNotificationWarning"
#define kIconWarningColor   [UIColor colorWithRed:1.f green:.8f blue:.0f alpha:1.f]

#define kIconErrorName      @"IdCloudNotificationError"
#define kIconErrorColor     [UIColor colorWithRed:.93f green:.09f blue:.11f alpha:1.f]

@implementation NotifyAction

// MARK: - Life Cycle

+ (instancetype)actionHide {
    return [[NotifyAction alloc] initWithDisplay:NO label:nil type:NotifyTypeInfo];
}

+ (instancetype)actionShow:(NSString *)label type:(NotifyType)type {
    return [[NotifyAction alloc] initWithDisplay:YES label:label type:type];
}

- (instancetype)initWithDisplay:(BOOL)display
                          label:(NSString *)label
                           type:(NotifyType)type{
    if (self = [super init]) {
        self.scheduledDisplay   = display;
        self.scheduledLabel     = label;
        self.scheduledType      = type;
    }
    
    return self;
}


// MARK: - Static Helpers

+ (UIColor *)NotifyTypeColor:(NotifyType)type {
    UIColor *retValue = nil;
    
    switch (type) {
        case NotifyTypeError:
            retValue = kIconErrorColor;
            break;
        case NotifyTypeWarning:
            retValue = kIconWarningColor;
            break;
        case NotifyTypeInfo:
            retValue = kIconInfoColor;
            break;
    }
    
    return retValue;
}

+ (UIImage *)NotifyTypeImage:(NotifyType)type {
    NSString *iconName = nil;
    
    switch (type) {
        case NotifyTypeError:
            iconName = kIconErrorName;
            break;
        case NotifyTypeInfo:
            iconName = kIconInfoName;
            break;
        case NotifyTypeWarning:
            iconName = kIconWarningName;
            break;
    }
    
    return [UIImage imageNamed:iconName inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil];
}


@end
