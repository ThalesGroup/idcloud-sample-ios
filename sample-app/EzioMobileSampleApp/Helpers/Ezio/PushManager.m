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

#import "PushManager.h"

typedef enum : NSInteger {
    kUnregistered   = 0,
    kRegistered     = 1,
} ClientIdState;

// Last token provided by application
#define kStorageLastProvidedTokenId     @"LastProvidedTokenId"

// Last token actually registered with current ClientId.
// Since demo app is for singe token only we don't care about relations.
#define kStorageLastRegistredTokenId    @"LastRegistredTokenId"

// Last registered OOB ClientId.
#define kStorageKeyClientId             @"ClientId"

// Stored in fast storage to prevent reading encrypted data.
#define kStorageKeyClientIdStat         @"ClientIdState"

// Message type we want to handle. Contain message id to fetch and origin client id.
#define kPushMessageType                @"com.gemalto.msm"
#define kPushMessageClientId            @"clientId"
#define kPushMessageMessageId           @"messageId"

@interface PushManager()

@property (nonatomic, strong)   id<EMOobManager>    oobManager;

@end

@implementation PushManager

// MARK: - Life Cycle

- (id)init
{
    NSError *error = nil;
    
    if (self = [super init]) {
        // Try to read previous push token already registered by app.
        _currentPushToken   = [[[CMain sharedInstance] storageFast] readStringForKey:kStorageLastProvidedTokenId];
        self.oobManager     = [[EMOobModule oobModule] createOobManagerWithURL:C_CFG_OOB_URL()
                                                                        domain:C_CFG_OOB_DOMAIN()
                                                                 applicationId:C_CFG_OOB_APP_ID()
                                                                   rsaExponent:C_CFG_OOB_RSA_KEY_EXPONENT()
                                                                    rsaModulus:C_CFG_OOB_RSA_KEY_MODULUS()
                                                                         error:&error];
    }
    
    // Something went wrong during init phase.
    // Probably wrong configuration, license etc..
    if (error) {
        NSLog(@"%@", error);
        assert(false);
        return nil;
    } else {
        return self;
    }
}

// MARK: - Public API

- (BOOL)isPushTokenRegistered
{
    return [[CMain sharedInstance].storageFast readStringForKey:kStorageLastRegistredTokenId] != nil;
}

- (void)registerToken:(NSString *)token completionHandler:(GenericCompletion)completionHandler
{
    // Store provided token.
    if (!_currentPushToken || ![_currentPushToken isEqualToString:token]) {
        [[[CMain sharedInstance] storageFast] writeString:token forKey:kStorageLastProvidedTokenId];
        _currentPushToken = token;
    }
    
    // Check if new registration is needed even if token is same like last time.
    [self registerCurrent:nil completionHandler:completionHandler];
}

- (void)registerClientId:(NSString *)clientId
       completionHandler:(GenericCompletion)completionHandler
{
    CMain *main = [CMain sharedInstance];
    
    // There is not much secure about Client Id, we are using secure storage just as showcase.
    // Because of that we will also update state in fast storage to not affect performance.
    [main.storageSecure writeString:clientId forKey:kStorageKeyClientId];
    [main.storageFast writeInteger:kRegistered forKey:kStorageKeyClientIdStat];
    
    // Check if new registration is needed.
    [self registerCurrent:clientId completionHandler:completionHandler];
}

- (void)registerOOBWithUserId:(NSString *)userId
             registrationCode:(id<EMSecureString>)regCode
            completionHandler:(void (^)(id<EMOobRegistrationResponse> response, NSError *error))completionHandler
{
    NSError *error = nil;
    do {
        id<EMOobRegistrationManager>    regManager  = [_oobManager oobRegistrationManager];
        EMOobRegistrationRequest        *request    = [[EMOobRegistrationRequest alloc] initWithUserId:userId
                                                                                    userAliasForClient:userId
                                                                                    registrationMethod:EMOobRegistrationMethodRegistrationCode
                                                                                 registrationParameter:regCode
                                                                                                 error:&error];
        BREAK_IF_NOT_NULL(error);
        [regManager registerWithRequest:request completionHandler:completionHandler];
    } while (NO);
    
    // Notify about possible failure.
    if (completionHandler && error) {
        completionHandler(nil, error);
    }
}

- (void)unregisterOOBWithCompletionHandler:(GenericCompletion)completionHandler
{
    CMain *main = [CMain sharedInstance];
    
    // Push token is registered
    if ([self isPushTokenRegistered]) {
        // Call unregister
        [self unRegisterOOBClientId:[main.storageSecure readStringForKey:kStorageKeyClientId]
                  completionHandler:^(BOOL success, NSError *error) {
            if (success) {
                // Remove all stored values.
                [main.storageFast removeValueForKey:kStorageLastRegistredTokenId];
                [main.storageFast removeValueForKey:kStorageKeyClientIdStat];
                [main.storageSecure removeValueForKey:kStorageKeyClientId];
                
                [self notifyAboutStatusChange];
            }
            if (completionHandler) {
                completionHandler(success, error);
            }
        }];
    } else {
        [self returnSuccessToHandler:completionHandler];
    }
}

- (void)processIncomingPush:(NSDictionary *)notification
{
    UIViewController<MainViewControllerProtocol> *listener = [[CMain sharedInstance] getCurrentListener];
    
    // React on message type com.gemalto.msm with supported view controller on screen.
    // This is just to simplify sample app scenario. Real application should handle all notification all the time.
    if (!listener || !notification || !(notification = notification[kPushMessageType])) {
        return;
    }
    
    // Get client and message id out of it.
    NSString *msgClientId   = notification[kPushMessageClientId];
    NSString *msgMessageId  = notification[kPushMessageMessageId];
    NSString *locClientId   = [[[CMain sharedInstance] storageSecure] readStringForKey:kStorageKeyClientId];
    
    // Find related token / client id on local. React only on current one.
    if (![msgClientId isEqualToString:locClientId]) {
        return;
    }
    
    // Prepare manager with current client and provider id.
    id<EMOobMessageManager> oobMessageManager = [_oobManager oobMessageManagerWithClientId:locClientId
                                                                                providerId:C_CFG_OOB_PROVIDER_ID()];
    
    // Display loading bar to indicate message downloading.
    [listener loadingIndicatorShowWithCaption:NSLocalizedString(@"LOADING_MESSAGE_INCOMING_MESSAGE", nil)];
    
    // Download message content.
    // Some messages might already be prefetched so we don't have to download them.
    // For simplicity we will download all of them.
    [oobMessageManager fetchWithMessageId:msgMessageId completionHandler:^(id<EMOobFetchMessageResponse> response, NSError *error) {
        // Notify about possible error
        if (response.resultCode != EMOobResultCodeSuccess || !response.oobIncomingMessage || error) {
            [listener loadingIndicatorHide];
            [listener showNSErrorIfExists:error];
            return;
        }
        
        // Since we might support multiple message type, it's cleaner to have separate method for that.
        if (![self processIncomingMessage:response.oobIncomingMessage oobMessageManager:oobMessageManager handler:listener]) {
            // Hide indicator in case that message was not processed.
            // Otherwise indicator will be hidden by specific method.
            [listener loadingIndicatorHide];
        }
    }];
}

// MARK: - Message handlers

- (BOOL)processIncomingMessage:(id<EMOobIncomingMessage>)message
             oobMessageManager:(id<EMOobMessageManager>)oobMessageManager
                       handler:(UIViewController<MainViewControllerProtocol> *)handler
{
    BOOL retValue = NO;
    
    if ([message.messageType isEqualToString:EMOobIncomingMessageTypeTransactionSigning]) {
        // Sign request.
        retValue = [self processTransactionSigningRequest:(id <EMOobTransactionSigningRequest>)message
                                        oobMessageManager:oobMessageManager
                                                  handler:handler];
    } else if ([message.messageType isEqualToString:EMOobIncomingMessageTypeTransactionVerify]) {
        // Verify request
        retValue = [self processTransactionVerifyRequest:(id <EMOobTransactionVerifyRequest>)message
                                       oobMessageManager:oobMessageManager
                                                 handler:handler];
    }
    
    return retValue;
}

- (BOOL)processTransactionSigningRequest:(id<EMOobTransactionSigningRequest>)request
                       oobMessageManager:(id<EMOobMessageManager>)oobMessageManager
                                 handler:(UIViewController<MainViewControllerProtocol> *)handler
{
    NSError         *internalError  = nil;
    id<EMMspParser> parser          = [[[EMMspService serviceWithModule:[EMMspModule mspModule]] mspFactory] createMspParser];
    
    // Get message subject key and fill in all values.
    NSString *subject = NSLocalizedString(request.subject.stringValue, nil);
    for (NSString *key in request.meta.allKeys) {
        NSString *placeholder = [NSString stringWithFormat:@"%%%@", key];
        subject = [subject stringByReplacingOccurrencesOfString:placeholder withString:request.meta[key]];
    }
    
    // Try to parse frame.
    do {
        id<EMMspFrame>  frame   = [parser parse:request.mspFrame error:&internalError];
        BREAK_IF_NOT_NULL(internalError);
        
        id<EMMspData>   data    = [parser parseMspData:frame error:&internalError];
        BREAK_IF_NOT_NULL(internalError);
        
        // For purpose of this sample app we will support only OATH.
        if (data.baseAlgo != EM_MSP_BASE_ALGO_OATH)
            break; // Skip unsupported frames.
        
        // Display dialog to get user reaction. For approve we need also OTP to be calculated.
        [handler approveOTP:subject withServerChallenge:((id <EMMspOathData>)data).ocraServerChallenge.value completionHandler:^(id<EMSecureString> otp) {
            // If we get OTP it mean, that user did approved request.
            id<EMOobTransactionSigningResponse> responseToSend = [request createWithResponse:otp ? EMOobTransactionSigningResponseValueAccepted : EMOobTransactionSigningResponseValueRejected
                                                                                         otp:[otp copy] // Send copy, this instance will get wiped!
                                                                                        meta:nil];
            
            // Send message and wait display result.
            [oobMessageManager sendWithMessage:responseToSend
                             completionHandler:^(id<EMOobMessageResponse> response, NSError *error) {
                // Hide loading indicator in all cases, because sending is done.
                [handler loadingIndicatorHide];
                
                if (response && !error) {
                    [handler showMessageWithCaption:NSLocalizedString(@"COMMON_MESSAGE_SUCCESS", nil)
                                        description:NSLocalizedString(@"PUSH_SENT", nil)];
                }
                [handler showNSErrorIfExists:error];
            }];
        }];
    } while (NO);
    
    // Display possible parsing issue.
    if (handler && internalError) {
        [handler loadingIndicatorHide];
        [handler showNSErrorIfExists:internalError];
    }
    
    return YES;
}

- (BOOL)processTransactionVerifyRequest:(id<EMOobTransactionVerifyRequest>)request
                      oobMessageManager:(id<EMOobMessageManager>)oobMessageManager
                                handler:(UIViewController<MainViewControllerProtocol> *)handler
{
    // Empty sample method
    return NO;
}

// MARK: - Private Helpers

- (void)registerCurrent:(NSString *)clientId completionHandler:(GenericCompletion)completionHandler
{
    // We don't have token from app? Nothing to do without it.
    if (!_currentPushToken) {
        // In full app this would not be an error, but in sample app we want to force registration OOB before token.
        [self returnErrorToHandler:completionHandler error:NSLocalizedString(@"COMMON_MSG_NO_PUSH_TOKEN", nil)];
        return;
    }
    
    CMain *main = [CMain sharedInstance];
    
    // We don't have any client id at all.
    if ([main.storageFast readIntegerForKey:kStorageKeyClientIdStat] == kUnregistered) {
        // This will probably happen when app will get push token without any enrolled token / client id.
        [self returnSuccessToHandler:completionHandler];
        return;
    }
    
    // Last registered token is same as current one.
    if ([[main.storageFast readStringForKey:kStorageLastRegistredTokenId] isEqualToString:_currentPushToken]) {
        [self returnSuccessToHandler:completionHandler];
        return;
    }
    
    // Get current Client Id or use one provided from API to safe some time.
    if (!clientId) {
        clientId = [main.storageSecure readStringForKey:kStorageKeyClientId];
    }
    
    // This should not happen. If client Id is registered, we should have it.
    assert(clientId);
    if (!clientId) {
        [self returnErrorToHandler:completionHandler error:NSLocalizedString(@"COMMON_MSG_MISSING_CLIENT_ID", nil)];
        return;
    }
    
    // To avoid retention in block and still work.
    NSString *currentPushToken = [_currentPushToken copy];
    
    // Now we have everything to register token to OOB it self.
    [self registerOOBClientId:clientId
                    pushToken:currentPushToken
            completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            [main.storageFast writeString:currentPushToken forKey:kStorageLastRegistredTokenId];
            [self notifyAboutStatusChange];
        }
        if (completionHandler) {
            completionHandler(success, error);
        }
    }];
    
}

- (void)returnSuccessToHandler:(GenericCompletion)completionHandler
{
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}


- (void)returnErrorToHandler:(GenericCompletion)completionHandler error:(NSString *)error
{
    if (completionHandler) {
        completionHandler(NO, [NSError errorWithDomain:[NSString stringWithFormat:@"%s", object_getClassName(self)]
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: error}]);
    }
}

- (void)registerOOBClientId:(NSString *)clientId
                  pushToken:(NSString *)token
          completionHandler:(GenericCompletion)completionHandler

{
    assert(clientId && token && completionHandler);
    
    id<EMOobNotificationManager> notifyManager = [_oobManager oobNotificationManagerWithClientId:clientId];
    
    NSArray <EMOobNotificationProfile *> *arrProfiles = @[[[EMOobNotificationProfile alloc] initWithChannel:C_CFG_OOB_CHANNEL() endPoint:token]];
    [notifyManager setNotificationProfiles:arrProfiles completionHandler:^(id<EMOobResponse> response, NSError *error) {
        BOOL success = !error && response && [response resultCode] == EMOobResultCodeSuccess;
        completionHandler(success, error);
    }];
}

- (void)unRegisterOOBClientId:(NSString *)clientId
            completionHandler:(GenericCompletion)completionHandler
{
    assert(clientId && completionHandler);
    
    id<EMOobNotificationManager> notifyManager = [_oobManager oobNotificationManagerWithClientId:clientId];
    [notifyManager clearNotificationProfilesWithCompletionHandler:^(id<EMOobResponse> response, NSError *error) {
        BOOL success = !error && response && [response resultCode] == EMOobResultCodeSuccess;
        completionHandler(success, error);
    }];
}

- (void)notifyAboutStatusChange
{
    id listener = [[CMain sharedInstance] getCurrentListener];
    if (listener) {
        [listener updatePushRegistrationStatus];
    }
}
@end
