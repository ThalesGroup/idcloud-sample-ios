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

#import "./HttpManager.h"

typedef void (^HTTPResponse)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);

#define kXMLTemplateAuth @"<?xml version=\"1.0\" encoding=\"UTF-8\"?> \
    <AuthenticationRequest> \
    <UserID>%@</UserID> \
    <OTP>%@</OTP> \
    </AuthenticationRequest>"

#define kXMLTemplateSign @"<?xml version=\"1.0\" encoding=\"UTF-8\"?> \
    <SignatureRequest> \
    <Transaction> \
    <Amount>%@</Amount> \
    <Beneficiary>%@</Beneficiary> \
    </Transaction> \
    <UserID>%@</UserID> \
    <OTP>%@</OTP> \
    </SignatureRequest>"

@implementation HttpManager

// MARK: - Public API

- (void)sendAuthRequest:(id<EMSecureString>)otp
              authInput:(id<EMAuthInput>)input
        serverChallenge:(id<EMSecureString>)serverChallenge
                  error:(NSError *)error
{
    UIViewController<MainViewControllerProtocol> *listener = [[CMain sharedInstance] getCurrentListener];
    
    if (otp && !error) {
        // Display loading indicator if UI is still valid.
        if (listener) {
            [listener loadingIndicatorShowWithCaption:NSLocalizedString(@"LOADING_MESSAGE_SENDING", nil)];
        }
        
        // Demo app use user name for token name since it's unique.
        TokenDevice *device = [CMain sharedInstance].managerToken.tokenDevice;
        NSString    *body   = [NSString stringWithFormat:kXMLTemplateAuth, device.token.name, otp.stringValue];
        
        // We don't need OTP any more. Wipe it.
        [otp wipe];
        
        // Post message and wait for results in proccessResponse.
        [self doPostMessage:C_CFG_TUTO_URL_AUTH()
                contentType:@"text/xml"
                    headers:[self authHeaders]
                       body:body
           returnInUIThread:YES
          completionHandler:proccessResponse];
    }
    else if (listener) {
        [listener showNSErrorIfExists:error];
    }
    
    // Wipe all possible data.
    [serverChallenge    wipe];
    [input              wipe];
}

- (void)sendSignRequest:(id<EMSecureString>)otp
              authInput:(id<EMAuthInput>)input
        serverChallenge:(id<EMSecureString>)serverChallenge
                  error:(NSError *)error
                 amount:(NSString *)amount
            beneficiary:(NSString *)beneficiary
{
    UIViewController<MainViewControllerProtocol> *listener = [[CMain sharedInstance] getCurrentListener];
    
    if (otp && !error) {
        // Display loading indicator if UI is still valid.
        if (listener) {
            [listener loadingIndicatorShowWithCaption:NSLocalizedString(@"LOADING_MESSAGE_SENDING", nil)];
        }
        
        // Demo app use user name for token name since it's unique.
        TokenDevice *device = [CMain sharedInstance].managerToken.tokenDevice;
        NSString    *body   = [NSString stringWithFormat:kXMLTemplateSign, amount, beneficiary, device.token.name, otp.stringValue];
        
        // We don't need OTP any more. Wipe it.
        [otp wipe];
        
        // Post message and wait for results in proccessResponse.
        [self doPostMessage:C_CFG_TUTO_URL_SIGN()
                contentType:@"text/xml"
                    headers:[self authHeaders]
                       body:body
           returnInUIThread:YES
          completionHandler:proccessResponse];
    }
    else if (listener) {
        [listener showNSErrorIfExists:error];
    }
    
    // Wipe all possible data.
    [serverChallenge    wipe];
    [input              wipe];
}

// MARK: Private Helpers

static HTTPResponse const proccessResponse = ^void(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
{
    UIViewController<MainViewControllerProtocol> *listener = [[CMain sharedInstance] getCurrentListener];
    
    // View is gone. We can exit.
    if (!listener) {
        return;
    }
    
    // Hide loading
    [listener loadingIndicatorHide];
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]] && ((NSHTTPURLResponse *)response).statusCode == 200 && data) {
        [listener showMessageWithCaption:nil description:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    } else {
        [listener showNSErrorIfExists:error];
    }
};

// WARNING: Basic authentication is used for connecting to tutorial website.
//          Note that this is only for the purpose of the sample application.
- (NSDictionary *)authHeaders
{
    NSString    *toHash = [NSString stringWithFormat:@"%@:%@", C_CFG_TUTO_BASICAUTH_USERNAME(), C_CFG_TUTO_BASICAUTH_PASSWORD()];
    NSString    *hash   = [[toHash dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    
    return @{@"Authorization" : [NSString stringWithFormat:@"Basic %@", hash]};
}

- (void)doPostMessage:(NSString *)url
          contentType:(NSString *)contentType
              headers:(NSDictionary<NSString *, NSString *> *)headers
                 body:(NSString *)body
     returnInUIThread:(BOOL)returnInUIThread
    completionHandler:(HTTPResponse)completionHandler
{
    // Prepare HTTP post request.
    NSData                  *postData   = [body dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSMutableURLRequest     *request    = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[postData length]] forHTTPHeaderField:@"Content-Length"];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    for (NSString *loopKey in headers.allKeys) {
        [request setValue:headers[loopKey] forHTTPHeaderField:loopKey];
    }
    [request setHTTPBody:postData];
    
    // Make response return in UI thread if needed.
    HTTPResponse handler = returnInUIThread && completionHandler ? ^void(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(data, response, error);
        });
    } : completionHandler;
    
    // Prepare session with predefined short timeout.
    NSURLSessionConfiguration *sessionConfig    = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest     = 15.0;
    sessionConfig.timeoutIntervalForResource    = 15.0;
    
    // Post request.
    [[[NSURLSession sessionWithConfiguration:sessionConfig] dataTaskWithRequest:request completionHandler:handler] resume];
}


@end
