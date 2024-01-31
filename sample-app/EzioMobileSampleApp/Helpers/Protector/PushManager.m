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

#import "PushManager.h"

NSString * const C_NOTIFICATION_ID_INCOMING_MESSAGE = @"NotificationIdIncomingMessage";

typedef enum : NSInteger {
    kUnregistered   = 0,
    kRegistered     = 1,
} ClientIdState;

// Message type we want to handle. Contain message id to fetch and origin client id.
#define kPushMessageType                @"com.gemalto.msm"
#define kPushMessageClientId            @"clientId"
#define kPushMessageMessageId           @"messageId"

@interface PushManager()

@property (nonatomic, strong)   id<EMOobManager>    oobManager;

@end

@implementation PushManager

// MARK: - Life Cycle

- (id)init {
    NSError *error = nil;
    
    if (self = [super init]) {
        // Try to read previous push token already registered by app.
        NSData *CFG_OOB_RSA_KEY_MODULUS_DATA = [self dataFromHexString: CFG_OOB_RSA_KEY_MODULUS_STRING()];
        _currentPushToken   = [self lastProvidedTokenRead];
        self.oobManager     = [[EMOobModule oobModule] createOobManagerWithURL:CFG_OOB_URL()
                                                                        domain:CFG_OOB_DOMAIN()
                                                                 applicationId:CFG_OOB_APP_ID()
                                                                   rsaExponent:CFG_OOB_RSA_KEY_EXPONENT()
                                                                    rsaModulus:CFG_OOB_RSA_KEY_MODULUS_DATA
                                                                         error:&error];
    }
    
    // Something went wrong during init phase.
    // Probably wrong configuration, license etc..
    if (error) {
        NSLog(@"%@", error);
        assert(false);
        return nil;
    }
    else {
        return self;
    }
}

// MARK: - Public API

- (BOOL)isPushTokenRegistered {
    return [self lastRegisteredTokenRead] != nil;
}

- (BOOL)isIncomingMessageInQueue {
    return [self lastMessageIdRead] != nil;
}

- (void)registerToken:(NSString *)token completionHandler:(GenericCompletion)completionHandler {
    // Store provided token.
    if (!_currentPushToken || ![_currentPushToken isEqualToString:token]) {
        [self lastProvidedTokenWrite:token];
        _currentPushToken = token;
    }

    // Check if new registration is needed even if token is same like last time.
    [self registerCurrent:nil completionHandler:completionHandler];
}

- (void)registerClientId:(NSString *)clientId
       completionHandler:(GenericCompletion)completionHandler {
    // There is not much secure about Client Id, we are using secure storage just as showcase.
    // Because of that we will also update state in fast storage to not affect performance.
    [self clientIdWrite:clientId];
    [self clientIdStateWrite:kRegistered];

    // Check if new registration is needed.
    [self registerCurrent:clientId completionHandler:completionHandler];
}

- (void)registerOOBWithUserId:(NSString *)userId
             registrationCode:(id<EMSecureString>)regCode
            completionHandler:(void (^)(id<EMOobRegistrationResponse> response, NSError *error))completionHandler {
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

- (void)unregisterOOBWithCompletionHandler:(GenericCompletion)completionHandler {
    // Push token is registered
    if ([self isPushTokenRegistered]) {
        // Call unregister
        [self unRegisterOOBClientId:[self clientIdRead] completionHandler:^(BOOL success, NSError *error) {
            if (success) {
                // Remove all stored values.
                [self lastRegisteredTokenDelete];
                [self clientIdStateDelete];
                [self lastMessageIdDelete];
                [self clientIdDelete];
            }
            if (completionHandler) {
                completionHandler(success, error);
            }
        }];
    }
    else {
        [self returnSuccessToHandler:completionHandler];
    }
}

- (void)processIncomingPush:(NSDictionary *)notification {
    // React on message type com.gemalto.msm
    if (!notification || !(notification = notification[kPushMessageType])) {
        return;
    }

    // Get client and message id out of it.
    NSString *msgClientId   = notification[kPushMessageClientId];
    NSString *msgMessageId  = notification[kPushMessageMessageId];
    NSString *locClientId   = [self clientIdRead];

    // Find related token / client id on local. React only on current one.
    if (![msgClientId isEqualToString:locClientId]) {
        return;
    }

    // Store current id and send local notification to UI.
    [self lastMessageIdWrite:msgMessageId];
}

- (void)fetchMessagesWithHandler:(BaseViewController *)handler {

    NSString *locClientId   = [self clientIdRead];

    // Prepare manager with current client and provider id.
    id<EMOobMessageManager> oobMessageManager = [_oobManager oobMessageManagerWithClientId:locClientId
                                                                                providerId:CFG_OOB_PROVIDER_ID()];
    
    // Display loading bar to indicate message downloading.
    [handler loadingIndicatorShowWithCaption:TRANSLATE(@"STRING_LOADING_FETCHING")];
    
    // Check if there is any stored incoming message id.
    NSString *messageId = [self lastMessageIdRead];
    if (messageId) {
        // Remove last stored id and notify UI.
        [self lastMessageIdDelete];
        
        // Try to fetch any possible messages on server.
        [oobMessageManager fetchWithMessageId:messageId completionHandler:^(id<EMOobFetchMessageResponse> aResponse, NSError *anError) {
            [self processFetchResponse:oobMessageManager response:aResponse error:anError handler:handler];
        }];
    } else {
        // Try to fetch any possible messages on server.
        [oobMessageManager fetchWithTimeout:30 completionHandler:^(id<EMOobFetchMessageResponse> aResponse, NSError *anError) {
            [self processFetchResponse:oobMessageManager response:aResponse error:anError handler:handler];
        }];
    }
    
}

// MARK: - Message handlers

- (void)processFetchResponse:(id<EMOobMessageManager>)manager
                    response:(id<EMOobFetchMessageResponse>)response
                       error:(NSError *)error
                     handler:(BaseViewController *)handler
{
    // Downloading is done, we can hide dialog.
    [handler loadingIndicatorHide];

    // Check response code and either proccess incoming message or display error.
    if (response.resultCode == EMOobResultCodeSuccess) {
        if (response.oobIncomingMessage) {
            [self processIncomingMessage:response.oobIncomingMessage oobMessageManager:manager handler:handler];
        } else {
            notifyDisplay(TRANSLATE(@"STRING_MESSAGING_NO_MESSAGES"), NotifyTypeInfo);
        }
    } else if (error) {
        notifyDisplayErrorIfExists(error);
    }
    
}

- (BOOL)processIncomingMessage:(id<EMOobIncomingMessage>)message
             oobMessageManager:(id<EMOobMessageManager>)oobMessageManager
                       handler:(BaseViewController *)handler
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
                                 handler:(BaseViewController *)handler
{
    NSError         *internalError  = nil;
    id<EMMspParser> parser          = [[[EMMspService serviceWithModule:[EMMspModule mspModule]] mspFactory] createMspParser];

    // Get message subject key and fill in all values.
    NSString *subject = TRANSLATE(request.subject.stringValue);
    NSString *origSubject = subject;
    NSString *params = @"";
    if (request.meta.count > 0) {
        for (NSString *key in request.meta.allKeys) {
            NSString *placeholder = [NSString stringWithFormat:@"%%%@", key];
            subject = [subject stringByReplacingOccurrencesOfString:placeholder withString:request.meta[key]];
            params = [NSString stringWithFormat:@"%@%@%@%@%@", params, @"\n", key, @":", request.meta[key]];
            if ([origSubject isEqual:subject]) {
                // Message string does not contain the request fields, append them to message instead
                subject = [TRANSLATE(@"message_subject_authentication_default") stringByAppendingString:params];
            }
        }
    }

    // Try to parse frame.
    do {
        id<EMMspFrame>  frame   = [parser parse:request.mspFrame error:&internalError];
        BREAK_IF_NOT_NULL(internalError);

        id<EMMspData>   data    = [parser parseMspData:frame error:&internalError];
        BREAK_IF_NOT_NULL(internalError);
        
        // For purpouse of this sample app we will support only OATH.
        if (data.baseAlgo != EM_MSP_BASE_ALGO_OATH) {
            break; // Skip unsupported frames.
        }
        
        // Display dialog to get user reaction. For approve we need also OTP to be calculated.
        [handler approveIncomingMessage:subject
                    withServerChallenge:((id <EMMspOathData>)data).ocraServerChallenge.value
                      completionHandler:^(id<EMSecureString> otp) {
            // Send response.
            [self processTransactionSigningRequest:request
                                 oobMessageManager:oobMessageManager
                                           handler:handler
                                               otp:otp];
        }];
    } while (NO);
    
    // Display possible parsing issue.
    if (handler && internalError) {
        [handler loadingIndicatorHide];
        notifyDisplayErrorIfExists(internalError);
    }
    
    return YES;
}

- (void)processTransactionSigningRequest:(id<EMOobTransactionSigningRequest>)request
                       oobMessageManager:(id<EMOobMessageManager>)oobMessageManager
                                 handler:(BaseViewController *)handler
                                     otp:(id<EMSecureString>)otp {
    // If we get OTP it mean, that user did approved request.
    EMOobTransactionSigningResponseValue type = otp ? EMOobTransactionSigningResponseValueAccepted : EMOobTransactionSigningResponseValueRejected;
    id<EMOobTransactionSigningResponse> responseToSend = [request createWithResponse:type
                                                                                 otp:[otp copy] // Send copy, this instance will get wiped!
                                                                                meta:nil];
    
    // Send message and wait display result.
    [oobMessageManager sendWithMessage:responseToSend
                     completionHandler:^(id<EMOobMessageResponse> response, NSError *error)
     {
         // Hide loading indicator in all cases, because sending is done.
         [handler loadingIndicatorHide];
         
         if (response && !error) {
             notifyDisplay(TRANSLATE(@"STRING_MESSAGING_SENT"), NotifyTypeInfo);
         } else {
             notifyDisplayErrorIfExists(error);
         }
     }];
}

- (BOOL)processTransactionVerifyRequest:(id<EMOobTransactionVerifyRequest>)request
                      oobMessageManager:(id<EMOobMessageManager>)oobMessageManager
                                handler:(BaseViewController *)handler
{
    // Empty sample method
    return NO;
}

// MARK: - Private Helpers

- (void)registerCurrent:(NSString *)clientId completionHandler:(GenericCompletion)completionHandler
{
    // We don't have token from app? Nothing to do without it.
    if (!_currentPushToken) {
        // In full app this would not be an error, but in sample app we want to foce registration OOB before token.
        [self returnErrorToHandler:completionHandler error:TRANSLATE(@"STRING_MESSAGING_MISSING_TOKEN")];
        return;
    }

    // We don't have any client id at all.
    if ([self clientIdStateRead] == kUnregistered) {
        // This will probably happen when app will get push token without any enrolled token / client id.
        [self returnSuccessToHandler:completionHandler];
        return;
    }

    // Last registered token is same as current one.
    if ([[self lastRegisteredTokenRead] isEqualToString:_currentPushToken]) {
        [self returnSuccessToHandler:completionHandler];
        return;
    }

    // Get current Client Id or use one provided from API to safe some time.
    if (!clientId) {
        clientId = [self clientIdRead];
    }

    // This should not happen. If client Id is registered, we should have it.
    assert(clientId);
    if (!clientId) {
        [self returnErrorToHandler:completionHandler error:TRANSLATE(@"STRING_MESSAGING_MISSING_CLIENT_ID")];
        return;
    }

    // To avoid retention in block and still work.
    NSString *currentPushToken = [_currentPushToken copy];
    
    // Now we have everything to register token to OOB it self.
    [self registerOOBClientId:clientId
                    pushToken:currentPushToken
            completionHandler:^(BOOL success, NSError *error) {
                if (success) {
                    [self lastRegisteredTokenWrite:currentPushToken];
                }
                if (completionHandler) {
                    completionHandler(success, error);
                }
            }];
    
}

- (void)returnSuccessToHandler:(GenericCompletion)completionHandler {
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}


- (void)returnErrorToHandler:(GenericCompletion)completionHandler error:(NSString *)error {
    if (completionHandler) {
        completionHandler(NO, [NSError errorWithDomain:[NSString stringWithFormat:@"%s", object_getClassName(self)]
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey: error}]);
    }
}

- (void)registerOOBClientId:(NSString *)clientId
                  pushToken:(NSString *)token
          completionHandler:(GenericCompletion)completionHandler {
    assert(clientId && token && completionHandler);

    id<EMOobNotificationManager> notifyManager = [_oobManager oobNotificationManagerWithClientId:clientId];

    NSArray <EMOobNotificationProfile *> *arrProfiles = @[[[EMOobNotificationProfile alloc] initWithChannel:CFG_OOB_CHANNEL() endPoint:token]];
    [notifyManager setNotificationProfiles:arrProfiles completionHandler:^(id<EMOobResponse> response, NSError *error) {
        BOOL success = !error && response && [response resultCode] == EMOobResultCodeSuccess;
        completionHandler(success, error);
    }];
}

- (void)unRegisterOOBClientId:(NSString *)clientId
            completionHandler:(GenericCompletion)completionHandler {
    assert(clientId && completionHandler);
    
    id<EMOobNotificationManager> notifyManager = [_oobManager oobNotificationManagerWithClientId:clientId];
    [notifyManager clearNotificationProfilesWithCompletionHandler:^(id<EMOobResponse> response, NSError *error) {
        BOOL success = !error && response && [response resultCode] == EMOobResultCodeSuccess;
        completionHandler(success, error);
            
    }];
}

// MARK: - Storage - Message Id
#define kStorageLastIncomminMessageId @"LastIncomminMessageId"

- (BOOL)lastMessageIdWrite:(NSString *)messageId {
    BOOL retValue = [CMain.sharedInstance.storageFast writeString:messageId forKey:kStorageLastIncomminMessageId];
    if (retValue) {
        [[NSNotificationCenter defaultCenter] postNotificationName:C_NOTIFICATION_ID_INCOMING_MESSAGE object:nil];
    }
    return retValue;
}

- (NSString *)lastMessageIdRead {
    return [CMain.sharedInstance.storageFast readStringForKey:kStorageLastIncomminMessageId];
}

- (BOOL)lastMessageIdDelete {
    BOOL retValue = [CMain.sharedInstance.storageFast removeValueForKey:kStorageLastIncomminMessageId];
    if (retValue) {
        [[NSNotificationCenter defaultCenter] postNotificationName:C_NOTIFICATION_ID_INCOMING_MESSAGE object:nil];
    }
    return retValue;
}

// MARK: - Storage - Last Provisioned Token
#define kStorageLastProvidedTokenId @"LastProvidedTokenId"

- (BOOL)lastProvidedTokenWrite:(NSString *)token {
    return [CMain.sharedInstance.storageFast writeString:token forKey:kStorageLastProvidedTokenId];
}

- (NSString *)lastProvidedTokenRead {
    return [CMain.sharedInstance.storageFast readStringForKey:kStorageLastProvidedTokenId];
}

- (BOOL)lastProvidedTokenDelete {
    return [CMain.sharedInstance.storageFast removeValueForKey:kStorageLastProvidedTokenId];
}

// MARK: - Storage - Last Registered Token
#define kStorageLastRegistredTokenId @"LastRegistredTokenId"

- (BOOL)lastRegisteredTokenWrite:(NSString *)token {
    return [CMain.sharedInstance.storageFast writeString:token forKey:kStorageLastRegistredTokenId];
}

- (NSString *)lastRegisteredTokenRead {
    return [CMain.sharedInstance.storageFast readStringForKey:kStorageLastRegistredTokenId];
}

- (BOOL)lastRegisteredTokenDelete {
    return [CMain.sharedInstance.storageFast removeValueForKey:kStorageLastRegistredTokenId];
}

// MARK: - Storage - Client Id

// Last registered OOB ClientId.
#define kStorageKeyClientId @"ClientId"

- (BOOL)clientIdWrite:(NSString *)clientId {
    return [CMain.sharedInstance.storageSecure writeString:clientId forKey:kStorageKeyClientId];
}

- (NSString *)clientIdRead {
    return [CMain.sharedInstance.storageSecure readStringForKey:kStorageKeyClientId];
}

- (BOOL)clientIdDelete {
    return [CMain.sharedInstance.storageSecure removeValueForKey:kStorageKeyClientId];
}

// MARK: - Storage - Client Id State
#define kStorageKeyClientIdStat @"ClientIdState"

- (BOOL)clientIdStateWrite:(ClientIdState)clientIdState {
    return [CMain.sharedInstance.storageFast writeInteger:clientIdState forKey:kStorageKeyClientIdStat];
}

- (ClientIdState)clientIdStateRead {
    return [CMain.sharedInstance.storageFast readIntegerForKey:kStorageKeyClientIdStat];
}

- (BOOL)clientIdStateDelete {
    return [CMain.sharedInstance.storageFast removeValueForKey:kStorageKeyClientIdStat];
}

- (NSData *)dataFromHexString:(NSString *) string {
    if([string length] % 2 == 1){
        string = [@"0"stringByAppendingString:string];
    }

    const char *chars = [string UTF8String];
    int i = 0, len = (int)[string length];

    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;

    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    return data;

}

@end
