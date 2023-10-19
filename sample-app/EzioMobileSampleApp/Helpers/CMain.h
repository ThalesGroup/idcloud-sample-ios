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

#import "Protector/PushManager.h"
#import "Protector/TokenManager.h"
#import "Protector/QRCodeManager.h"
#import "KeyValue.h"

/**
 Main app singletone. It will keep all important class instances.
 */
@interface CMain : NSObject

/**
 Return instance of secure storage. (Protector SecureStorage)
 */
@property (nonnull, strong, readonly) id<StorageProtocol>   storageSecure;

/**
 Return instance of fast insecure storage. (iOS UserDefaults)
 */
@property (nonnull, strong, readonly) id<StorageProtocol>   storageFast;

/**
 Used for handling all push related actions.
 */
@property (nonnull, strong, readonly) PushManager           *managerPush;

/**
 Used for handling all token related actions.
 */
@property (nonnull, strong, readonly) TokenManager          *managerToken;

/**
 Used for handling QR codes.
 */
@property (nonnull, strong, readonly) QRCodeManager         *managerQRCode;

/**
 Common method to get CMain singletone.

 @return Instance of CMain class.
 */
+ (__nonnull instancetype)sharedInstance;

/**
 Release singletone together with all helper class inside.
 */
+ (void)end;

/**
 Activate SDK and prepare all required modules so they can be used.
 This method should be called as first thing in app life cycle.
 */
- (void)configureAndActivateSDK;

/**
 Switch to proper View Controller based on SDK state.

 */
- (void)updateRootViewController;


@end
