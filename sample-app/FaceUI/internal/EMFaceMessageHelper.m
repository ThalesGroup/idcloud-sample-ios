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

#import "EMFaceMessageHelper.h"

@implementation EMFaceMessageHelper

    NSString* const OkButtonTitle = @"OK";
    NSString* const RetryButtonTitle = @"RETRY";
    NSString* const StartButtonTitle = @"START";
    NSString* const ContinueButtonTitle = @"CONTINUE";
    NSString* const CancelButtonTitle = @"CANCEL";

    NSString* const VerificationFaceOutTitle = @"Please position your face in the center of the circle";
    NSString* const VerificationBlinkTitle = @"BLINK YOUR EYES !";
    NSString* const VerificationKeepStillTitle = @"KEEP STILL !";

    NSString* const ErrorUnknown = @"An error has occurred. You may retry again later";
    NSString* const ErrorBadQuality = @"We are not able to capture your face. Please make sure to position your face in front of the camera and to have good lighting conditions";
    NSString* const ErrorCameraNotFound = @"We couldn't detect or use a camera on your device.";
    NSString* const ErrorMatchNotFound = @"We are sorry but your face does not seem to match the one registered.";
    NSString* const ErrorUserReenollmentNeeded = @"Sorry but you need to enroll again !";
    NSString* const ErrorLivenessCheckFailed = @"We could not detect that you blinked. Please try again to blink and make sure to have good lighting conditions";
    NSString* const ErrorTimedOut = @"We could not detect your face. Please try again and make sure to have good lighting conditions";
    NSString* const ErrorUserNotFound = @"The user you selected does not exist !";
    NSString* const ErrorLicenseError = @"License Error. Either the license is not set or the license is invalid.";


    + (NSString*) getErrorMessageForErrorCode:(EMStatus) error {
        if (error == EM_STATUS_AUTHENTICATION_FACIAL_ERROR || error == EM_STATUS_AUTHENTICATION_FACIAL_ALREADY_EXTRACTING) {
            return ErrorTimedOut;
        } else if (error == EM_STATUS_AUTHENTICATION_FACIAL_BAD_QUALITY) {
            return ErrorBadQuality;
        } else if (error == EM_STATUS_AUTHENTICATION_FACIAL_CAMERA_NOT_FOUND) {
            return ErrorCameraNotFound;
        } else if (error == EM_STATUS_AUTHENTICATION_FACIAL_MATCH_NOT_FOUND) {
            return ErrorMatchNotFound;
        } else if (error == EM_STATUS_AUTHENTICATION_FACIAL_USER_NOT_FOUND) {
            return ErrorUserNotFound;
        } else if (error == EM_STATUS_AUTHENTICATION_FACIAL_USER_REENROLL_NEEDED) {
            return ErrorUserReenollmentNeeded;
        } else if (error == EM_STATUS_AUTHENTICATION_FACIAL_LIVENESS_CHECK_FAILED) {
            return ErrorLivenessCheckFailed;
        } else if (error == EM_STATUS_AUTHENTICATION_FACIAL_TIMEOUT) {
            return ErrorTimedOut;
        }else if (error == EM_STATUS_AUTHENTICATION_LICENSE_ERROR) {
            return ErrorLicenseError;
        }
        return ErrorUnknown;
    }
@end
