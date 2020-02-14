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

#import "QRCodeManager.h"

@implementation QRCodeManager

// MARK: - Public API

- (void)parseQRCode:(id<EMSecureByteArray>)qrCodeData completionHandler:(QRCodeManagerComletion)completionHandler {
    // Handler is mandatory parameter.
    assert(completionHandler);
    if (!completionHandler) {
        return;
    }
    
    BOOL                retValue    = NO;
    NSError             *error      = nil;
    NSString            *userId     = nil;
    id<EMSecureString>  regCode     = nil;
    
    do {
        // Two components in frame are user id and reg code.
        NSString            *plainData = [[NSString alloc] initWithData:qrCodeData.dataValue encoding:NSUTF8StringEncoding];
        NSArray<NSString *> *components = [plainData componentsSeparatedByString:@","];
        if (components.count != 2) {
            error = [NSError errorWithDomain:[NSString stringWithFormat:@"%s", object_getClassName(self)]
                                        code:-1
                                    userInfo:@{NSLocalizedDescriptionKey: TRANSLATE(@"STRING_TOKEN_QR_CODE_PARSE_ERROR")}];
        }
        BREAK_IF_NOT_NULL(error);
        
        // Get actual values.
        userId      = components[0];
        regCode     = [components[1] secureString];
        retValue    = YES;
        
    } while (NO);
    
    // Notify handler.
    completionHandler(retValue, userId, regCode, error);
    
    // Do not wipe regCode directly after handler.
    // There is a lot of async task after it. It's easier to wipe at manually after.
}

@end
