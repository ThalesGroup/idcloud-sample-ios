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

#import "EMFaceManager.h"
#import "EMFaceConstant.h"
#import "EMFaceEnrollManager.h"
#import "EMVerifyViewController.h"
#import "EMEnrollViewController.h"

@interface EMFaceManager() {
    EMFaceAuthService *_faceAuthService;

    BOOL _isServiceInitializing;
}

@property EMFaceSettings* settings;

@end

@implementation EMFaceManager

+ (void)verifyWithPresentingViewController:(UIViewController*)viewController
                           authenticatable:(id<EMAuthenticatable>)authenticatable
                                   timeout:(NSTimeInterval) timeout
                                completion:(void (^)(EMFaceManagerProcessStatus,id<EMFaceAuthInput> authInput))completion{
    EMVerifyViewController *vc = [EMFaceManager verifyViewController];
    vc.completionHandler = completion;
    vc.authenticatable = authenticatable;
    vc.timeout = timeout;
    vc.autoDismissWhenComplete = YES;
    [viewController presentViewController:vc animated:YES completion:^{
        
    }];

}

+ (void) enrollWithPresentingViewController:(UIViewController*) viewController timeout:(NSTimeInterval) timeout completion:(void (^)(EMFaceManagerProcessStatus))completion {
    EMEnrollViewController *vc = [EMFaceManager enrollViewController];
    vc.completionHandler = completion;
    vc.timeout = timeout;
    [viewController presentViewController:vc animated:YES completion:^{
        
    }];
}

+ (void)unenrollWithCompletion:(void (^)(EMFaceManagerProcessStatus))completionBlock{
    [[EMFaceEnrollManager sharedInstance] unenrollWithCompletionHandler:^(BOOL success, NSError *error) {
        if(success){
            completionBlock(EMFaceManagerProcessStatusSuccess);
        }else{
            completionBlock(EMFaceManagerProcessStatusFail);
        }
    }];
}

+ (EMVerifyViewController*) verifyViewController {
    UIStoryboard* faceIdsb = [UIStoryboard storyboardWithName:@"FaceUI" bundle:[NSBundle faceUIBundle]];
    EMVerifyViewController *myViewController = [faceIdsb instantiateViewControllerWithIdentifier:@"EMVerifyViewController"];
    return myViewController;
}


+ (EMEnrollViewController*) enrollViewController {
    UIStoryboard* faceIdsb = [UIStoryboard storyboardWithName:@"FaceUI" bundle:[NSBundle faceUIBundle]];
    EMEnrollViewController *myViewController = [faceIdsb instantiateViewControllerWithIdentifier:@"EMEnrollViewController"];
    return myViewController;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[EMFaceManager alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        EMAuthModule *authModule = [EMAuthModule authModule];
        _faceAuthService = [EMFaceAuthService serviceWithModule:authModule];
        _isServiceInitializing = NO;
        _isSupported = [_faceAuthService isSupported:nil];
    }

    return self;
}

- (void)initialize:(void (^)(BOOL, NSError *))completion
{
    if (!_isServiceInitializing && ![_faceAuthService isInitialized]) {
        _isServiceInitializing = YES;
        [_faceAuthService initializeWithCompletion:^(BOOL success, NSError *error) {
            self->_isServiceInitializing = NO;
            if (completion) {
                completion(success, error);
            }
        }];
    }
}

- (BOOL)isInitializing
{
    return _isServiceInitializing;
}

- (BOOL)isInitialized
{
    return [_faceAuthService isInitialized];
}

- (EMFaceAuthService *)service
{
    return _faceAuthService;
}

- (EMFaceAuthFactory *)factory
{
    return [_faceAuthService faceAuthFactory];
}

@end
