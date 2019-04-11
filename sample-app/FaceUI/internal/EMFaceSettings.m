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

#import "EMFaceSettings.h"

@interface EMFaceSettings()
//Fix out of ranges settings
- (void) fixValues;

@end

@implementation EMFaceSettings

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^
                  {
                      sharedInstance = [self new];
                      [sharedInstance resetDefault];
                  });
    return sharedInstance;
}

- (void) setQualityThreshold:(int)qualityThreshold {
    _qualityThreshold = qualityThreshold;
    [self fixValues];
}

- (void) setLivenessThreshold:(int)livenessThreshold {
    _livenessThreshold = livenessThreshold;
    [self fixValues];
}

- (void) setLivenessBlinkTimeout:(int)livenessBlinkTimeout {
    _livenessBlinkTimeout = livenessBlinkTimeout;
    [self fixValues];
}

- (void) setMatchingThreshold:(int)matchingThreshold {
    _matchingThreshold = matchingThreshold;
    [self fixValues];
}

- (void) setNumberOfFramesToEnroll:(int)numberOfFramesToEnroll {
    _numberOfFramesToEnroll = numberOfFramesToEnroll;
    [self fixValues];
}


- (void) setVerifierFaceCaptureMode:(EMFaceCaptureMode)verifierFaceCaptureMode {
    _verifierFaceCaptureMode = verifierFaceCaptureMode;
}

- (void) fixValues {
    if(_livenessThreshold<0) {
        _livenessThreshold = 0;
    }
    else if(_livenessThreshold>100) {
        _livenessThreshold = 100;
    }
    
    if(_qualityThreshold<0) {
        _qualityThreshold = 0;
    }
    else if(_qualityThreshold>100) {
        _qualityThreshold = 100;
    }
    
    if(_matchingThreshold<0) {
        _matchingThreshold = 0;
    }
    else if(_matchingThreshold>72) {
        _matchingThreshold = 72;
    }
    
    if(_livenessBlinkTimeout<0) {
        _livenessBlinkTimeout = 0;
    }
    else if(_livenessBlinkTimeout>100000) {
        _livenessBlinkTimeout = 100000;
    }
    
    if(_numberOfFramesToEnroll < 1){
        _numberOfFramesToEnroll = 1;
    } else if(_numberOfFramesToEnroll > 20){
         _numberOfFramesToEnroll = 20;
    }


    
}

- (void) resetDefault {
    self.livenessThreshold = DEFAULT_LIVENESS_THRESHOLD;
    self.qualityThreshold = DEFAULT_QUALITY_THRESHOLD;
    self.matchingThreshold = DEFAULT_MATCHING_THRESHOLD;
    self.livenessBlinkTimeout = DEFAULT_LIVENESS_BLINK_TIMEOUT;
    self.numberOfFramesToEnroll = DEFAULT_NUMBER_FRAME_TO_ENROLL;
    self.verifierFaceCaptureMode = DEFAULT_VERIFIER_FACE_CAPTURE_MODE;;
    
}
@end
