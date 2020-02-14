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

#import "TokenManager.h"

@interface TokenManager()

@property (nonatomic, strong) id <EMOathTokenManager> oathManager;

@end

@implementation TokenManager

// MARK: - Life Cycle

- (instancetype)init {
    NSError                 *error      = nil;
    id<EMOathToken>         token       = nil;
    id <EMOathTokenManager> oathManager = [[EMOathService serviceWithModule:[EMOtpModule otpModule]] tokenManager:&error];
    
    // Check if we have some enrolled token.
    NSString *tokenName = oathManager ? [[oathManager tokenNames:&error] anyObject] : nil;
    
    // If there is no token saved, we can skip rest.
    if (tokenName) {
        // Try to get instance of saved token.
        token = [oathManager tokenWithName:tokenName
                     fingerprintCustomData:C_CUSTOM_FINGERPRINT_DATA()
                                     error:&error];
    }
    
    // Create self only if everything is correct so far.
    if (!error && (self = [super init])) {
        // Token might not be enrolled yet.
        if (token) {
            _tokenDevice = [TokenDevice tokenDeviceWithToken:token];
        }
        self.oathManager = oathManager;
    }
    
    // Error in such case mean, that we have broken configuration or some internal state of SDK.
    // Most probably wrong license, different fingerprint etc. We should not continue at that point.
    assert(!error);
    
    return self;
}

// MARK: - Public API

- (void)deleteTokenWithCompletionHandler:(GenericCompletion)completionHandler {
    // First we should unregister from oob and then delete token it self.
    [CMain.sharedInstance.managerPush unregisterOOBWithCompletionHandler:^(BOOL success, NSError *error) {
        BOOL removed = NO;
        
        // In case of successful unregistering, we can try to delete token it self.
        if (success) {
            removed = [self.oathManager removeToken:self.tokenDevice.token error:&error];
        }
        
        // Remove stored reference
        if (removed) {
            self->_tokenDevice = nil;
        }
        
        // Notify listener.
        if (completionHandler) {
            completionHandler(removed, error);
        }
    }];
}

- (void)provisionWithUserId:(NSString *)userId
           registrationCode:(id<EMSecureString>)regCode
          completionHandler:(void (^)(id<EMOathToken> token, NSError *error))completionHandler {
    // First try to register Client Id on OOB server.
    [CMain.sharedInstance.managerPush registerOOBWithUserId:userId
                                             registrationCode:regCode
                                            completionHandler:^(id<EMOobRegistrationResponse> aResponse, NSError *anError) {
                                                // If OOB registration was successful we can provision token.
                                                if (aResponse && aResponse.resultCode == EMOobResultCodeSuccess) {
                                                    [self doProvisioningWithUserId:userId
                                                                  registrationCode:regCode
                                                                          clientId:aResponse.clientId
                                                                 completionHandler:completionHandler];
                                                    
                                                } else if (completionHandler) {
                                                    // Notify about failure.
                                                    completionHandler(nil, anError);
                                                }
                                            }];
}

// MARK: - Private Helpers

- (void)doProvisioningWithUserId:(NSString *)userId
                registrationCode:(id<EMSecureString>)regCode
                        clientId:(NSString *)clientId
               completionHandler:(void (^)(id<EMOathToken> token, NSError *error))completionHandler {
    EMDeviceFingerprintSource *deviceFingerprintSource = [[EMDeviceFingerprintSource alloc] initWithCustomData:C_CUSTOM_FINGERPRINT_DATA()];
    EMDeviceFingerprintTokenPolicy *deviceFingerprintTokenPolicy = [[EMDeviceFingerprintTokenPolicy alloc]
                                                                    initWithDeviceFingerprintSource:deviceFingerprintSource
                                                                    failIfInvalid:YES];
    
    // Prepare provisioning configuration based on app data.
    EMProvisioningConfiguration *config = [EMProvisioningConfiguration
                                           epsConfigurationWithURL:C_CFG_OTP_PROVISION_URL()
                                           domain:C_DOMAIN()
                                           rsaKeyId:C_CFG_OTP_RSA_KEY_ID()
                                           rsaExponent:C_CFG_OTP_RSA_KEY_EXPONENT()
                                           rsaModulus:C_CFG_OTP_RSA_KEY_MODULUS()
                                           registrationCode:regCode
                                           provisioningProtocol:EMMobileProvisioningProtocolVersion5
                                           optionalParameters:^(EMEpsConfigurationBuilder *builder) {
                                               builder.tlsConfiguration = C_CFG_SDK_TLS_CONFIGURATION();
                                           }];
    
    // Try to get manager.
    NSError *error = nil;
    
    // Check if we did get token manager correctly.
    if (error && completionHandler) {
        completionHandler(nil, error);
        return;
    }
    
    @try {
        // Provision token with given config.
        [_oathManager createTokenWithName:userId
                provisioningConfiguration:config
             deviceFingerprintTokenPolicy:deviceFingerprintTokenPolicy
                               capability:EMTokenCapabilityOTP
                        extendedCompletionHandler:^(id<EMOathToken> token, NSDictionary *extensions, NSError *error) {
                            // Save client id only in case of successful registration.
                            if (token && !error) {
                                [CMain.sharedInstance.managerPush registerClientId:clientId completionHandler:nil];
                                
                                // Store current token.
                                self->_tokenDevice = [TokenDevice tokenDeviceWithToken:token];
                            }
                            
                            // Notify in UI thread.
                            if (completionHandler) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    completionHandler(token, error);
                                });
                            }
                        }];
    }
    @catch (EMException *exception) {
        if (completionHandler) {
            completionHandler(nil, [NSError errorWithDomain:[NSString stringWithFormat:@"%s", object_getClassName(self)]
                                                       code:-1
                                                   userInfo:@{NSLocalizedDescriptionKey: exception.description}]);
        }
    }
}

@end
