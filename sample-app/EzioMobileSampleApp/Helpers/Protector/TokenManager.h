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

#import "TokenDevice.h"

/**
 Class handling token life cycle.
 */
@interface TokenManager : NSObject

/**
 Return curent enrolled token / device or nil in case we don't have one.
 */
@property (nonatomic, strong, readonly) TokenDevice *tokenDevice;

//
/**
 Unregister from OOB and delete token from DB.
 Device must be online to performe such operation, because we will first try to unregister OOB.
 
 @param completionHandler Triggered once operation is finished
 */
- (void)deleteTokenWithCompletionHandler:(GenericCompletion)completionHandler;

/**
 Register to OOB and provision token with given user id and registration code.
 
 @param userId User id to be provisioned
 @param regCode Provisioning registration code
 @param completionHandler Triggered once operation is finished
 */
- (void)provisionWithUserId:(NSString *)userId
           registrationCode:(id<EMSecureString>)regCode
          completionHandler:(void (^)(id<EMOathToken> token, NSError *error))completionHandler;

@end
