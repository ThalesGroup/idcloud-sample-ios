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

#import <Foundation/Foundation.h>
#import <EzioMobile/EzioMobile.h>

/**
 * @discussion Face UI SDK protocol to listen all the UI modification to present to the user.
 */
@protocol EMFaceAuthUIDelegate <NSObject>

/**
 * Face UI SDK Step enumeration. Describes each step the Face UI could be in
 */
typedef NS_ENUM(NSUInteger, EMFaceUIDelegateStep)
{
    /**
     * Waiting for a face to be positioned in front of the camera
     */
    EMFaceUIDelegateStepEnrollWaitFace,
    
    /**
     * Waiting for a face to be positioned in front of the camera
     */
    EMFaceUIDelegateStepVerifyWaitFace,
    
    /**
     * Got a face in front of the camera (enrolment) and user already starts real enrollment
     */
    EMFaceUIDelegateStepAddFace,

    
    /**
     * Waiting for end-user start
     */
    EMFaceUIDelegateStepWaitStart,
    
    /**
     * Processing step of the current operation
     */
    EMFaceUIDelegateStepProcessing,
    
    /**
     * Waiting the end-user to blink during verify operation
     */
    EMFaceUIDelegateStepBlink,
    
    /**
     * Waiting the end-user to keep still during verify operation
     */
    EMFaceUIDelegateStepKeepStill,
    
    /**
     * Step to handle the UI of a sucessfully ended operation
     */
    EMFaceUIDelegateStepSuccess,
    
    /**
     * Step to handle the UI where the operation ended with an error
     */
    EMFaceUIDelegateStepError,
    
    /**
     * Step to handle the UI where the user canceled the operation
     */
    EMFaceUIDelegateStepCancel,
};

/**
 * Delegate method which receives the image from the camera
 * @param image the image to set on a UIImageView
 */
- (void)imageDidUpdate:(UIImage*)image;


/**
 * Delegate method to handle a new step during the Verify or Enroll operation
 * @param step new step of the operation
 */
- (void)stepDidChange:(EMFaceUIDelegateStep)step;


@end


/**
 * Base Manager of the Face UI SDK processes, Enroll and Verify. It handles all the commun elements between the two processes
 */

@interface EMFaceBaseManager : NSObject

/**
 * Face Listener delegate property
 */
@property (nonatomic, weak) id <EMFaceAuthUIDelegate> delegate;


/**
 * Helper method to detect if the current face frame event has a face on it.
 * @param event current face frame event
 * @return return YES if the event has a face, NO otherwise
 */
- (BOOL)containsFaceWithFrameEvent:(id<EMFaceAuthFrameEvent>)event;


/**
 * Helper method to handle the step modification during a operation
 * @param step current step
 */
- (void)stepDidChange:(EMFaceUIDelegateStep)step;

/**
 * Helper methode to display the current face status as a BSString
 * @param status the current face status
 * @return the string of the current face status
 */
+(NSString*)faceStatusToNSString:(EMStatus)status;


/* !
 * Update video view with the new frame received
 * @param event New frame event received
 */
- (void)handleUIWithframeReceived:(id<EMFaceAuthFrameEvent>)event;

/* !
 * Cancel operation handler
 * To be overrided by children class
 */
- (void)cancelFaceOperation;

@end
