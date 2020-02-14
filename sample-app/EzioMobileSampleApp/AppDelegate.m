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

#import "AppDelegate.h"

@interface AppDelegate()

@property (nonatomic, assign) BOOL skipNextResignActive;

@end

@implementation AppDelegate

// MARK: - Life Cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // First thing we will do in our app is init Protector SDK so we can start using all features.
    [CMain.sharedInstance configureAndActivateSDK];
        
    // Register for notifications
//    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *notifyCenter = [UNUserNotificationCenter currentNotificationCenter];
        notifyCenter.delegate = self;
        [notifyCenter requestAuthorizationWithOptions: UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound
                                    completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                        if (granted) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [application registerForRemoteNotifications];
                                            });
                                        }
                                    }];
//    } else {
//        UIUserNotificationType      types       = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
//        UIUserNotificationSettings  *settings   = [UIUserNotificationSettings settingsForTypes:types categories:nil];
//
//        [application registerUserNotificationSettings:settings];
//        [application registerForRemoteNotifications];
//    }
    
    // Save root view controller for better handeling.
    // We will use empty container so base controller can be switched on runtime.
    self.rootViewController = (RootViewController *)_window.rootViewController;
    
    // Load proper VC based on SDK state.
    [CMain.sharedInstance updateRootViewController];
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [CMain.sharedInstance.managerPush registerToken:[deviceToken hexStringRepresentation] completionHandler:nil];
}

//- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
//    [CMain.sharedInstance.managerPush processIncomingPush:userInfo];
//}

- (void)applicationWillResignActive:(UIApplication *)application {
    //ios 8 FP calls resign active & become active sequentially, so app blicks. To avoid this state, skipNextResignActive is used for Touch ID flows
    if(!_skipNextResignActive) {
        [self bgBlurPresentedView];
    }
    
    _skipNextResignActive = NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self bgBlurPresentedView];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    _skipNextResignActive = NO;
    
    [self bgUnblurPresentedView];
}


// MARK: - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0)) {
    [CMain.sharedInstance.managerPush processIncomingPush:notification.request.content.userInfo];
    
    // Notify system.
    completionHandler(0);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void(^)(void))completionHandler API_AVAILABLE(ios(10.0)) {
    [CMain.sharedInstance.managerPush processIncomingPush:response.notification.request.content.userInfo];
    
    // Notify system.
    completionHandler();
}

// MARK: - Private Helpers

#define kWindowBlurViewTag 326598

/**
 Hide data in app snapshot to avoid secure data leaks
 */
- (void)bgBlurPresentedView {
    if ([self.window viewWithTag:kWindowBlurViewTag]) {
        return;
    }
    [self.window addSubview:[self bgBlurView]];
}

- (void)bgUnblurPresentedView {
    UIView *blurView = [self.window viewWithTag:kWindowBlurViewTag];
    [UIView animateWithDuration:.25
                          delay:.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         blurView.alpha = .0;
                     } completion:^(BOOL finished) {
                         [blurView removeFromSuperview];
                     }];
}

- (UIView *)bgBlurView {
    UIVisualEffectView *retValue = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    retValue.frame  = self.window.frame;
    retValue.tag    = kWindowBlurViewTag;
    retValue.alpha  = .0;
    
    [UIView animateWithDuration:.25
                          delay:.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         retValue.alpha = 1.0;
                     } completion:nil];
    
    
    return retValue;
}


- (UIInterfaceOrientationMask)application:(UIApplication *)application
  supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
