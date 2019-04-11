//  MIT License
//
//  Copyright (c) 2019 Thales DIS
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

// IMPORTANT: This source code is intended to serve training information purposes only. Please make sure to review our IdCloud documentation, including security guidelines.

#import "Ezio/PushManager.h"
#import "Ezio/TokenManager.h"
#import "Ezio/QRCodeManager.h"
#import "Ezio/HttpManager.h"
#import "StoryItem.h"
#import "KeyValue.h"

typedef enum : NSInteger {
    // Face Id service was not even started.
    GemaloFaceIdStateUndefined,
    // Face id is not supported
    GemaloFaceIdStateNotSupported,
    // Failed to registered.
    GemaloFaceIdStateUnlicensed,
    // Successfully registered.
    GemaloFaceIdStateLicensed,
    // Failed to init service.
    GemaloFaceIdStateInitFailed,
    // Registered and initialised.
    GemaloFaceIdStateInited,
    // Registered, initialised and configured with at least one user enrolled.
    GemaloFaceIdStateReadyToUse
} GemaloFaceIdState;

/**
 Main app singleton. It will keep all important class instances.
 */
@interface CMain : NSObject

/**
 Return instance of secure storage. (Ezio SecureStorage)
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
 Used for handling http communication.
 */
@property (nonnull, strong, readonly) HttpManager           *managerHttp;

/**
 Gemalto face id does have multiple step async activation.
 Check this value to see current state.
 */
@property (nonatomic, assign, readonly) GemaloFaceIdState   faceIdState;

/**
 Common method to get CMain singleton.

 @return Instance of CMain class.
 */
+ (__nonnull instancetype)sharedInstance;

/**
 Release singleton together with all helper class inside.
 */
+ (void)end;

/**
 Activate SDK and prepare all required modules so they can be used.
 This method should be called as first thing in app life cycle.
 */
- (void)configureAndActivateSDK;

/**
 Return view controller for given item.

 @param storyItem StoryItem description of VC we want to return.
 @return View controller
 */
- (__kindof UIViewController *_Nonnull)getViewController:(StoryItem *_Nonnull)storyItem;

/**
 Return current view controller in case that token detail is visible. Otherview nil.
 Used instead of notification.
 
 @return Current listener
 */
- (__kindof UIViewController *_Nullable)getCurrentListener;

/**
 Switch to proper tab based on SDK state. Enroller without token, authentication with it.

 @param animated Whenever we should animate transition.
 */
- (void)switchTabToCurrentState:(BOOL)animated;

/**
 Perform animation on selected VC.

 @param tabBarController Parent tab view controller
 @param viewController Destination view controller.
 @return Return YES if new view controller is different from current one in tab bar.
 */
- (BOOL)animateTabChange:(UITabBarController *_Nonnull)tabBarController toViewController:(UIViewController *_Nonnull)viewController;

/**
 Force reload gemalto face id status.
 */
- (void)updateGemaltoFaceIdStatus;

@end
