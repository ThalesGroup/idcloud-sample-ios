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

/**
 Helper class to handle push notifications
 */
@interface PushManager : NSObject

/**
 Last push token provided by application. It might not be registered yet.
 */
@property (nonatomic, copy, readonly)       NSString    *currentPushToken;

/**
 Whenever is last provided push token registered on OOB server.
 */
@property (nonatomic, assign, readonly)     BOOL        isPushTokenRegistered;

/**
 Should be called each time application get push token from Apple.
 Usually directly from didRegisterForRemoteNotificationsWithDeviceToken.
 
 @param token Hex representation of push token
 @param completionHandler Triggered once operation is finished
 */
- (void)registerToken:(NSString *)token
    completionHandler:(GenericCompletion)completionHandler;

/**
 Register current push token with specified client Id.

 @param clientId OOB Client ID
 @param completionHandler Triggered once operation is finished
 */
- (void)registerClientId:(NSString *)clientId
       completionHandler:(GenericCompletion)completionHandler;

/**
 Register to OOB and store given client Id.

 @param userId User id to be registered
 @param regCode User registration code
 @param completionHandler Triggered once operation is finished
 */
- (void)registerOOBWithUserId:(NSString *)userId
             registrationCode:(id<EMSecureString>)regCode
            completionHandler:(void (^)(id<EMOobRegistrationResponse> aResponse, NSError *anError))completionHandler;

/**
 Unregister all push tokens for current client Id on server.

 @param completionHandler Triggered once operation is finished
 */
- (void)unregisterOOBWithCompletionHandler:(GenericCompletion)completionHandler;

/**
 Process incoming push notification.

 @param notification Incoming push notification user info.
 */
- (void)processIncomingPush:(NSDictionary *)notification;

@end
