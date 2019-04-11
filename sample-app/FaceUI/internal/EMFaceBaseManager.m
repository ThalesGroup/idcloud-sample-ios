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

@interface EMFaceBaseManager() {
    UIImage * faceImage; // Returned by Ezio EMFaceFrameEvent
}
@end

@implementation EMFaceBaseManager

- (void) handleUIWithframeReceived:(id<EMFaceAuthFrameEvent>)event {
    
    @autoreleasepool {
        faceImage = [event image];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate imageDidUpdate:self->faceImage];
    });
}


// Helper function to check if face is detected
- (BOOL) containsFaceWithFrameEvent:(id<EMFaceAuthFrameEvent>) event {
    BOOL hasFace = YES;
    CGRect faceRect = [event imageBounds];
    
    if(CGRectIsEmpty(faceRect)) {
        hasFace = NO;
    }

    return hasFace;
}


- (void) stepDidChange:(EMFaceUIDelegateStep) step {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate stepDidChange:step];
    });
}

+(NSString*)faceStatusToNSString:(EMStatus)status{
    
    NSString *result;
    
    switch (status) {
            
        case EM_STATUS_AUTHENTICATION_FACIAL_NONE:
            result = @"None";
            break;
        case EM_STATUS_AUTHENTICATION_FACIAL_SUCCESS:
            result =@"Success";
            break;
        case EM_STATUS_AUTHENTICATION_FACIAL_REQUIRED_LIVE_ACTION:
            result =@"Required live action";
            break;
        case EM_STATUS_AUTHENTICATION_FACIAL_ERROR:
            result =@"Error";
            break;
        case EM_STATUS_AUTHENTICATION_FACIAL_TIMEOUT:
            result=@"Timeout";
            break;
        case EM_STATUS_AUTHENTICATION_FACIAL_BAD_QUALITY:
            result=@"Bad quality";
            break;
        case EM_STATUS_AUTHENTICATION_FACIAL_CAMERA_NOT_FOUND:
            result=@"Camera not found";
            break;
        case EM_STATUS_AUTHENTICATION_FACIAL_CANCELED:
            result=@"Canceled";
            break;
        case EM_STATUS_AUTHENTICATION_FACIAL_MATCH_NOT_FOUND:
            result =@"Match not found";
            break;
        case EM_STATUS_AUTHENTICATION_FACIAL_USER_EXISTS:
            result=@"User exist";
            break;
            
        case EM_STATUS_AUTHENTICATION_FACIAL_USER_NOT_FOUND:
            result=@"User not found";
            break;
            
        case EM_STATUS_AUTHENTICATION_FACIAL_USER_REENROLL_NEEDED:
            result=@"Re enroll needed";
            break;
            
        case EM_STATUS_AUTHENTICATION_FACIAL_ALREADY_EXTRACTING:
            result=@"Already extracting";
            break;
            
        case EM_STATUS_AUTHENTICATION_FACIAL_LIVENESS_CHECK_FAILED:
            result=@"Liveness check failed";
            break;
            
        case EM_STATUS_AUTHENTICATION_FACIAL_FACE_NOT_FOUND:
            result=@"Face not found";
            break;
            
        default:
            result=@"Error";
            break;
    }
    
    return result;
}

- (void) cancelFaceOperation{
}
@end
