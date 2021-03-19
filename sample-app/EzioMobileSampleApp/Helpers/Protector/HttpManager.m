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

#import "./HttpManager.h"

typedef void (^HTTPResponse)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);

#define kAuthSuccess @"0"
#define kSignSuccess @"Signature verification succeeded"

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

- (void)sendAuthRequest:(NSString *)otp completionHandler:(HttpManagerCompletion)handler {
    // Demo app use user name for token name since it's unique.
    TokenDevice *device = CMain.sharedInstance.managerToken.tokenDevice;
    NSDictionary    *input = @{
        @"userId": device.token.name,
        @"otp":otp
    };
    NSDictionary    *body = @{
        @"name": @"Auth_OTP",
        @"input":input
    };
    // Post message and wait for results in proccessResponse.
    [self doPostMessage:CFG_TUTO_URL_ROOT()
            contentType:@"application/json"
                headers:[self authHeaders]
                   body:body
       returnInUIThread:YES
      completionHandler:[self processResponse:handler]];
    
}

- (void)sendSignRequest:(NSString *)otp
                 amount:(NSString *)amount
            beneficiary:(NSString *)beneficiary
      completionHandler:(HttpManagerCompletion)handler {
    // Demo app use user name for token name since it's unique.
    TokenDevice *device = CMain.sharedInstance.managerToken.tokenDevice;
    NSDictionary *transactionDict = @{
        @"amount": amount,
        @"beneficiary": beneficiary
    };
    NSDictionary    *input = @{
        @"userId": device.token.name,
        @"otp":otp,
        @"transactionData":transactionDict
    };
    NSDictionary    *body = @{
        @"name": @"Sign_OTP",
        @"input":input
    };
    // Post message and wait for results in proccessResponse.
    [self doPostMessage:CFG_TUTO_URL_ROOT()
            contentType:@"application/json"
                headers:[self authHeaders]
                   body:body
       returnInUIThread:YES
      completionHandler:[self processResponse:handler]];
}

// MARK: Private Helpers

- (HTTPResponse)processResponse:(HttpManagerCompletion)handler {
    return ^void(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]] && ((NSHTTPURLResponse *)response).statusCode == 201 && data) {
            NSDictionary *dict =
            [NSJSONSerialization JSONObjectWithData:data
                                            options:0
                                              error:nil];
            NSString *value = (NSString*)[dict valueForKeyPath:@"state.result.code"];
            NSString *message = (NSString*)[dict valueForKeyPath:@"state.result.message"];
            BOOL        success         = [value isEqual:kAuthSuccess];
            handler(success, message);
        } else {
            handler(NO, error.localizedDescription);
        }
    };
}

- (NSDictionary *)authHeaders {
    NSDictionary    *headers    = @{
        @"Authorization" : CFG_TUTO_BASIC_AUTH_JWT(),
        @"X-API-KEY" : CFG_TUTO_BASIC_AUTH_API_KEY()
    };
    return headers;
}

- (void)doPostMessage:(NSString *)url
          contentType:(NSString *)contentType
              headers:(NSDictionary<NSString *, NSString *> *)headers
                 body:(NSDictionary *)body
     returnInUIThread:(BOOL)returnInUIThread
    completionHandler:(HTTPResponse)completionHandler {
    // Prepare HTTP post request.
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:body
                                                   options:0
                                                     error:nil];
    NSString *dataString = [[NSString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding];
    dataString =  [dataString stringByTrimmingCharactersInSet:
                   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    dataString =   [dataString stringByTrimmingCharactersInSet:
                    [NSCharacterSet newlineCharacterSet]];
    NSData *postData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    
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
