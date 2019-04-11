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

#import "Ezio/Storage/SecureStorage.h"
#import "App/Storage/UserDefaults.h"
#import "../AppDelegate.h"

static CMain *sInstance = nil;

@implementation CMain

// MARK: - Static Helpers

+ (instancetype)sharedInstance
{
    if (!sInstance)
        sInstance = [[CMain alloc] init];
    
    return sInstance;
}

+ (void)end
{
    sInstance = nil;
}

// MARK: - Public API

- (void)configureAndActivateSDK
{
    // Make sure, that we will always check isConfigured first. Multiple call of init will cause crash / run time exception.
    if (![EMCore isConfigured])
    {
        NSError *error = nil;
        EMCore *core = [EMCore configureWithActivationCode:C_CFG_SDK_ACTIVATION_CODE()
                                            configurations:[self moduleConfigurations]];
        
        // Login so we can use secure storage, OOB etc..
        [core.passwordManager login:&error];
        
        // This should not happen. Usually it means, that someone try to login with different password than last time.
        assert(!error);
        
        // FaceId fallback. When it's not configured.
        [EMSystemFaceAuthService setIsSupportedFallback:^BOOL(NSString *machineID) {
            return [machineID isEqualToString:@"iPhone11,3"] || [machineID isEqualToString:@"iPhone11,6"];
        }];
        
        // This will also register and activate licence.
        [self updateGemaltoFaceIdStatus];
    }
    
    _storageSecure      = [[SecureStorage alloc] init];
    _storageFast        = [[UserDefaults alloc] init];
    _managerPush        = [[PushManager alloc] init];
    _managerToken       = [[TokenManager alloc] init];
    _managerQRCode      = [[QRCodeManager alloc] init];
    _managerHttp        = [[HttpManager alloc] init];
}

- (__kindof UIViewController *_Nonnull)getViewController:(StoryItem *)storyItem
{
    UIStoryboard        *storyboard = [UIStoryboard storyboardWithName:storyItem.storyboardName bundle:nil];
    UIViewController    *retValue   = [storyboard instantiateViewControllerWithIdentifier:storyItem.storyboardItemId];
 
    return retValue;
}

- (__kindof UIViewController<MainViewControllerProtocol> *)getCurrentListener
{
    id                      retValue        = nil;
    AppDelegate             *appDelegate    = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UINavigationController  *navController  = (UINavigationController *)appDelegate.window.rootViewController;
    UITabBarController      *tabController  = (UITabBarController *)navController.topViewController;
    
    if ([tabController isKindOfClass:[UITabBarController class]] && [tabController.selectedViewController conformsToProtocol:@protocol(MainViewControllerProtocol)])
        retValue = tabController.selectedViewController;
    
    return retValue;
}

- (void)switchTabToCurrentState:(BOOL)animated
{
    AppDelegate             *appDelegate    = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UINavigationController  *navController  = (UINavigationController *)appDelegate.window.rootViewController;
    UITabBarController      *tabController  = (UITabBarController *)navController.topViewController;
    NSInteger               newIndex        = _managerToken.tokenDevice ? 1 : 0;
    UIViewController        *newVC          = tabController.viewControllers[newIndex];
    
    // Switch to proper tab.
    if (animated)
        [self animateTabChange:tabController toViewController:newVC];
    else // Hide navigation bar on provisioning VC.
        [self updateNavigationController:navController hide:newIndex == 0 animated:NO];
    
    
    [tabController setSelectedViewController:newVC];
}

- (BOOL)animateTabChange:(UITabBarController *)tabBarController toViewController:(UIViewController *)viewController
{
    BOOL    retValue    = NO;
    UIView  *fromView   = tabBarController.selectedViewController.view;
    UIView  *toView     = viewController.view;
    
    retValue = fromView != toView;
    if (retValue)
    {
        NSUInteger  fromIndex   = [tabBarController.viewControllers indexOfObject:tabBarController.selectedViewController];
        NSUInteger  toIndex     = [tabBarController.viewControllers indexOfObject:viewController];
        
        // Hide navigation bar on provisioning VC.
        [self updateNavigationController:viewController.navigationController hide:toIndex == 0 animated:YES];
        
        [UIView transitionFromView:fromView
                            toView:toView
                          duration:0.5
                           options: (fromIndex > toIndex ? UIViewAnimationOptionTransitionCurlUp : UIViewAnimationOptionTransitionCurlDown) | UIViewAnimationOptionCurveEaseInOut
                        completion:^(BOOL finished) {
                            if (finished) {
                                tabBarController.selectedIndex = [tabBarController.viewControllers indexOfObject:viewController];
                            }
                        }];
    }
    return retValue;
}

- (void)updateGemaltoFaceIdStatus
{
    EMFaceAuthService *faceIdService = [[EMFaceManager sharedInstance] service];

    // Activate face id support.
    _faceIdState = GemaloFaceIdStateUndefined;
    
    NSError *error = nil;
    if (![faceIdService isSupported:&error])
    {
        self.faceIdState = GemaloFaceIdStateNotSupported;
        NSLog(@"%@", error);
        return;
    }
    
    // Allow to use sample app without face id.
    if (!C_CFG_FACE_ID_PRODUCT_KEY() || !C_CFG_FACE_ID_PRODUCT_KEY().length ||
        !C_CFG_FACE_ID_SERVER_URL() || !C_CFG_FACE_ID_SERVER_URL().length) {
        self.faceIdState = GemaloFaceIdStateUnlicensed;
        return;
    }
    
    [faceIdService configureLicense:^(EMFaceAuthLicenseBuilder *builder) {
        builder.productKey  = C_CFG_FACE_ID_PRODUCT_KEY();
        builder.serverUrl   = C_CFG_FACE_ID_SERVER_URL();
    } completion:^(BOOL success, NSError *error) {
        // Print out reason and exit.
        if (!success)
        {
            self.faceIdState = GemaloFaceIdStateUnlicensed;
            NSLog(@"%@", error);
            return;
        }
        self.faceIdState = GemaloFaceIdStateLicensed;
        
        // Already inited.
        if ([faceIdService isInitialized])
            [self updateGemaltoFaceIdStatusConfigured:faceIdService];
        else
        {
            // With license we can activate face id service.
            [[EMFaceManager sharedInstance] initialize:^(BOOL success, NSError *error) {
                // Print out reason and exit.
                if (!success)
                {
                    self.faceIdState = GemaloFaceIdStateInitFailed;
                    NSLog(@"%@", error);
                    return;
                }
                [self updateGemaltoFaceIdStatusConfigured:faceIdService];
            }];
        }
    }];
}

// MARK: - Private Helpers

- (void)updateNavigationController:(UINavigationController *)controller hide:(BOOL)hide animated:(BOOL)animated
{
    if ([controller isNavigationBarHidden] != hide)
        [controller setNavigationBarHidden:hide animated:animated];
}
    
- (void)updateGemaltoFaceIdStatusConfigured:(EMFaceAuthService *)authService
{
    // Configured at this point mean, that there is at least one user enrolled.
    NSError *error = nil;
    if ([authService isConfigured:&error])
        self.faceIdState = GemaloFaceIdStateReadyToUse;
    else
        self.faceIdState = GemaloFaceIdStateInited;
    
    if (error)
        NSLog(@"%@", error);
}

- (NSSet *)moduleConfigurations
{
    // SAMPLE: CONFIG - How to init SDK.
    
    // OTP module is required for token management and OTP calculation.
    EMOtpConfiguration  *otpCFG = [EMOtpConfiguration configurationWithJailbreakPolicy:C_CFG_OTP_JAILBREAK_POLICY()];
    
    // OOB module is required for push notifications.
    EMOobConfiguration  *oobCFG = [EMOobConfiguration configurationWithOptionalParameters:^(EMOobConfigurationBuilder *configurationBuilder) {
        // Jailbreak policy for OOB module. See EMOobJailbreakPolicyIgnore for more details.
        [configurationBuilder setJailbreakPolicy:C_CFG_OOB_JAILBREAK_POLICY()];
        // Device fingerprint is used for security reason. This way app can add some additional input for internal encryption mechanism.
        // This value must remain the same all the time. Otherwise all provisioned tokens will not be valid any more.
        [configurationBuilder setDeviceFingerprintSource:C_CFG_SDK_DEVICE_FINGERPRINT_SOURCE()];
        // For debug and ONLY debug reasons we might lower some TLS configuration.
        [configurationBuilder setTlsConfiguration:C_CFG_SDK_TLS_CONFIGURATION()];
    }];
    
    // Mobile Signing Protocol QR parsing, push messages etc..
    EMMspConfiguration *mspCFG = [EMMspConfiguration configurationWithObfuscationKeys:C_CFG_MSP_OBFUSCATION_CODE()
                                                                        signatureKeys:C_CFG_MSP_SIGN_KEYS()];
    
    // Return all configurations.
    return [NSSet setWithObjects:otpCFG, oobCFG, mspCFG, nil];
}

- (void)setFaceIdState:(GemaloFaceIdState)faceIdState
{
    // Update value
    _faceIdState = faceIdState;
    
    // Notify about first change
    id listener = [[CMain sharedInstance] getCurrentListener];
    if (listener)
        [listener updateFaceIdSupport];
}

@end
