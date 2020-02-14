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
 * Default liveness threshold value
 */
static int DEFAULT_LIVENESS_THRESHOLD = 0;

/**
 * Default quality threshold value
 */
static int DEFAULT_QUALITY_THRESHOLD = 48;

/**
 * Default matching threshold value
 */
static int DEFAULT_MATCHING_THRESHOLD = 50;

/**
 * Default liveness blink timeout value in milliseconds.
 */
static int DEFAULT_LIVENESS_BLINK_TIMEOUT = 4000;

/**
 * Default frame used to enroll.
 */
static int DEFAULT_NUMBER_FRAME_TO_ENROLL = 1;

/**
 * Default frame used to enroll.
 */
static int DEFAULT_COUNT_DOWN_TO_CAPTURE = 5;


/**
 * Default enroller face capture mode.
 */
static EMFaceCaptureMode DEFAULT_VERIFIER_FACE_CAPTURE_MODE = EMFaceCaptureModeLivenessPassive;


/**
 * @discussion Singleton class to handle the save and loading of the facial recognition parameters.
 */
@interface EMFaceSettings : NSObject

/**
 * Get Liveness Threshold
 */
@property (nonatomic) int livenessThreshold;

/**
 * Get Quality Threshold
 */
@property  (nonatomic) int qualityThreshold;

/**
 * Get Matching Threshold
 */
@property  (nonatomic) int matchingThreshold;

/**
 * Get Liveness Blink Timeout in ms
 */
@property  (nonatomic) int livenessBlinkTimeout;

/**
 * Get frame to enroll
 */
@property  (nonatomic) int numberOfFramesToEnroll;


/**
 * Get verifier capture mode
 */
@property (nonatomic) EMFaceCaptureMode verifierFaceCaptureMode;

/**
 * Create the singleton instance of the EMFaceSettings manager
 * Use to load or save the settings of the Face Manager.
 * @return EMFaceSettings
 */
+ (instancetype)sharedInstance;

/**
 * Reset settings to defaults values
 */
- (void) resetDefault;
@end
