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

#import "EMFaceBaseManager.h"
#import <EzioMobile/EzioMobile.h>

/**
 * @discussion Face UI SDK mananger to handle the verify operation
 */
@interface EMFaceVerifyManager : EMFaceBaseManager <EMFaceAuthVerifierDelegate>

/**
 * Create the singleton instance of the Face Verify Operation manager
 * @return EMFaceVerifyManager
 */
+ (instancetype)sharedInstance;

/**
 * Method to start a verify of a specific user with a maximum timeout.
 * @param authenticatable The authenticatable to authenticate.
 * @param delegate The delegate which will handles the UI of the verify operation.
 * @param timeout The maximum time (in seconds) before canceling the operation, default 60 seconds.
 * @param completion The completion handler.
 */
- (void)verifyWithAuthenticable:(id<EMAuthenticatable>)authenticatable
                       delegate:(id<EMFaceAuthUIDelegate>)delegate
                        timeout:(NSTimeInterval)timeout
                     completion:(void(^)(id<EMFaceAuthInput> authInput,NSError *error))completion;

@end
