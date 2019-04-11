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

#import "EMFaceBaseManager.h"


/**
 * @discussion Face UI SDK manager to handle the enrolled operation
 */
//
@interface EMFaceEnrollManager : EMFaceBaseManager <EMFaceAuthEnrollerDelegate>


/**
 * Create the singleton instance of the Face Enroll Operation manager
 * @return EMFaceEnrollManager
 */
+ (instancetype)sharedInstance;

/**
 * Unenrolled a previously enrolled user
 * @param completion The completion block for unenrolled
 */
- (void)unenrollWithCompletionHandler:(void(^)(BOOL success, NSError *error))completion;

/**
 * Method to start an enrolment of a specific user with a maximum timeout.
 * @param sender the delegate which will handles the UI of the enrolled operation
 * @param timeout the maximum time (in ms) before canceling the operation, default 60 seconds
 */
- (void)startEnrollmentWithDelegate:(id)sender
                            timeout:(NSTimeInterval)timeout
                  completionHandler:(void(^)(EMStatus status))handler;

/* Method to inform SDK that user is ready to be captured */
- (void)userIsReady;
@end
