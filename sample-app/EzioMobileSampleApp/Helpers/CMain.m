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

#import "Protector/Storage/SecureStorage.h"
#import "App/Storage/UserDefaults.h"
#import "../AppDelegate.h"

#import "SideMenuViewController.h"
#import "ProvisionerViewController.h"

static CMain *sInstance = nil;

@implementation CMain

// MARK: - Static Helpers

+ (instancetype)sharedInstance
{
    if (!sInstance) {
        sInstance = [[CMain alloc] init];
    }
    
    return sInstance;
}

+ (void)end {
    sInstance = nil;
}

// MARK: - Public API

- (void)configureAndActivateSDK {
    // Make sure, that we will always check isConfigured first. Multiple call of init will cause crash / run time exception.
    if (![EMCore isConfigured]) {
        NSError *error = nil;
        EMCore *core = [EMCore configureWithActivationCode:CFG_SDK_ACTIVATION_CODE()
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
        [self updateProtectorFaceIdStatus];
    }
    
    _storageSecure      = [SecureStorage    new];
    _storageFast        = [UserDefaults     new];
    _managerPush        = [PushManager      new];
    _managerToken       = [TokenManager     new];
    _managerQRCode      = [QRCodeManager    new];
    _managerHttp        = [HttpManager      new];
}

- (void)updateRootViewController {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.rootViewController switchToViewController:[self getNewViewController]];
}

- (void)updateProtectorFaceIdStatus {
    EMFaceAuthService *faceIdService = [[EMFaceManager sharedInstance] service];
    
    NSError *error = nil;
    if (![faceIdService isSupported:&error]) {
        return;
    }
    
    // Allow to use sample app without face id.
    if (!CFG_FACE_ID_PRODUCT_KEY() || !CFG_FACE_ID_PRODUCT_KEY().length ||
        !CFG_FACE_ID_SERVER_URL() || !CFG_FACE_ID_SERVER_URL().length) {
        return;
    }
    
    [faceIdService configureLicense:^(EMFaceAuthLicenseBuilder *builder) {
        builder.productKey  = CFG_FACE_ID_PRODUCT_KEY();
        builder.serverUrl   = CFG_FACE_ID_SERVER_URL();
    } completion:^(BOOL success, NSError *error) {
        if (success && ![faceIdService isInitialized]) {
            [[EMFaceManager sharedInstance] initialize:nil];
        }
    }];
}

// MARK: - Private Helpers

- (UIViewController *)getNewViewController {
    return _managerToken.tokenDevice ? [SideMenuViewController protectorVC] : [ProvisionerViewController viewController];
}

- (NSSet *)moduleConfigurations {    
    // OTP module is required for token management and OTP calculation.
    EMOtpConfiguration  *otpCFG = [EMOtpConfiguration configurationWithJailbreakPolicy:CFG_OTP_JAILBREAK_POLICY()];
    
    // OOB module is required for push notifications.
    EMOobConfiguration  *oobCFG = [EMOobConfiguration configurationWithOptionalParameters:^(EMOobConfigurationBuilder *configurationBuilder) {
        // Jailbreak policy for OOB module. See EMOobJailbreakPolicyIgnore for more details.
        [configurationBuilder setJailbreakPolicy:CFG_OOB_JAILBREAK_POLICY()];
        // Device fingerprint is used for security reason. This way app can add some additional input for internal encryption mechanism.
        // This value must remain the same all the time. Othewise all provisioned tokens will not be valid any more.
        [configurationBuilder setDeviceFingerprintSource:CFG_SDK_DEVICE_FINGERPRINT_SOURCE()];
        // For debug and ONLY debug reasons we might lower some TLS configuration.
        [configurationBuilder setTlsConfiguration:CFG_SDK_TLS_CONFIGURATION()];
    }];
    
    // Mobile Signing Protocol QR parsing, push messages etc..
    EMMspConfiguration *mspCFG = [EMMspConfiguration configurationWithObfuscationKeys:CFG_MSP_OBFUSCATION_CODE()
                                                                        signatureKeys:CFG_MSP_SIGN_KEYS()];
    
    // Return all configurations.
    return [NSSet setWithObjects:otpCFG, oobCFG, mspCFG, nil];
}

@end
