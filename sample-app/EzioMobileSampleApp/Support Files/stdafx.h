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

#ifndef stdafx_h
#define stdafx_h

// All those warinig can be turned off by removing last build step "Mark interesting parts of code" or simple removing "SAMPLE" mark.

// Make sure, that we are importing those only in ObjectiveC files like AppDelegate.m, main.m etc...
#ifdef __OBJC__

#define TRANSLATE(__KEY__) NSLocalizedString(__KEY__, nil)

// Load ViewController with same storyboard id as class name from selected storyboard file.
#define CreateVC(__STORYBOARD__, __SELF__) [[UIStoryboard storyboardWithName:__STORYBOARD__ \
bundle:[NSBundle bundleForClass:__SELF__.class]] \
instantiateViewControllerWithIdentifier:NSStringFromClass(__SELF__.class)]

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <EzioMobile/EzioMobile.h>
#import <IdCloudDesignable/IdCloudDesignable.h>

// Add categories
#import "NSData+Protector.h"
#import "NSString+Protector.h"

// Common data types used everywhere
#import "Protocols.h"
#import "Configuration.h"
#import "CMain.h"

#endif

#endif /* stdafx_h */
