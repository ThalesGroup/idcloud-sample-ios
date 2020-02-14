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
#import "EMFaceSettings.h"

/**
 * The Facial UI result status enumeration
 */
typedef NS_ENUM(NSUInteger, EMFaceManagerProcessStatus){
    /**
     * The Facial UI operation ended successfully
     */
    EMFaceManagerProcessStatusSuccess,
    
    /**
     * The Facial UI operation ended with an error. The error description will be stored in the faceStatusError variable
     */
    EMFaceManagerProcessStatusFail,
    
    /**
     * The Facial UI operation was canceled by the user
     */
    EMFaceManagerProcessStatusCancel
};


/**
 * The Facial UI public manager used to configure, start verify or enroll operations
 */
@interface EMFaceManager : NSObject

/**
 * The singleton instance of Face UI manager
 * @return EMFaceManager instance
 */
+ (instancetype)sharedInstance;

/**
 * Whether the device supports face authentication (i.e. Front Facing Camera)
 */
@property (readonly) BOOL isSupported;

/**
 * Whether the Service is currently initializing
 * If true, do not invoke API and wait until initialization if finished 
 * See initialize:
 */
@property (readonly) BOOL isInitializing;

/**
 * Whether the service is initialized
 * If false, do not invoke API and call first initialize: method
 */
@property (readonly) BOOL isInitialized;

/**
 * Gets the EMFaceAuthService object used internally
 * @return EMFaceAuthService
 */
@property (readonly) EMFaceAuthService *service;

/**
 * Gets the EMFaceAuthFactory object used internally
 * @return EMFaceAuthFactory
 */
@property (readonly) EMFaceAuthFactory *factory;

/**
 * If any error occured, get the error status upon the last face operation completion, nil otherwise.
 * @return NSString
 */
@property (nonatomic, strong) NSString *faceStatusError;


/** @name Tasks */
#pragma mark - Tasks

/**
 * Initializes and loads the internal face service and resources. 
 * Could be called multiple times.
 * 
 * @warning Must be called in the main thread
 */
- (void)initialize:(void(^)(BOOL success, NSError *error))completion;


/**
 * Starts the Enroll operation. Creates and present modally a EnrollVerifyController on the viewController received.
 * The method call a completion block when over: EMFaceManagerProcessStatusSuccess, EMFaceManagerProcessStatusCancel, EMFaceManagerProcessStatusFail.
 * If EMFaceManagerProcessStatusFail is end, the error description is available in EMFaceManager faceStatusError property.
 *
 * @param viewController a view controller which will present modally the verify operation (Not Null)
 * @param timeout timeout duration of the operation.
 * @param completion A completion block called when the operation is over.
 */
+  (void)enrollWithPresentingViewController:(UIViewController*) viewController
                                    timeout:(NSTimeInterval)timeout
                                 completion:(void(^)(EMFaceManagerProcessStatus))completion;


/**
 * Starts the Verify operation. Creates a EMVerifyViewController and present it modally on the viewController received.
 * The method call a completion block when over: EMFaceManagerProcessStatusSuccess, EMFaceManagerProcessStatusCancel, EMFaceManagerProcessStatusFail.
 * If EMFaceManagerProcessStatusFail is end, the error description is available in EMFaceManager faceStatusError property.
 *
 * @param viewController A view controller which will present modally the verify operation (Not Null)
 * @param authenticatable The authenticatable object
 * @param timeout timeout duration of the operation.
 * @param completion A completion block called when the operation is over.
 */
+ (void)verifyWithPresentingViewController:(UIViewController*)viewController
                           authenticatable:(id<EMAuthenticatable>)authenticatable
                                   timeout:(NSTimeInterval) timeout
                                completion:(void(^)(EMFaceManagerProcessStatus,id<EMFaceAuthInput> authInput))completion;


/**
 * Start the Unenroll operation.
 * The method call a completion block when over: EMFaceManagerProcessStatusSuccess and EMFaceManagerProcessStatusFail.
 * If EMFaceManagerProcessStatusFail is end, the error description is available in EMFaceManager faceStatusError property.
 *
 * @param completionBlock A completion block called when the operation is over.
 */
+ (void)unenrollWithCompletion:(void(^)(EMFaceManagerProcessStatus))completionBlock;

@end
