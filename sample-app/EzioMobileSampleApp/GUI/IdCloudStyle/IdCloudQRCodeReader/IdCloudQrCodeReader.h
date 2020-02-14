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

@class IdCloudQrCodeReader;

/**
 QR Code Reader response
 */
@protocol IdCloudQrCodeReaderDelegate
/**
 Triggered once QR code is successfuly parsed.

 @param sender Instance of QR Code reader. So we can check custom tag etc.
 @param qrCode Parsed code data.
 */
- (void)onQRCodeProvided:(IdCloudQrCodeReader *)sender qrCode:(id<EMSecureByteArray>)qrCode;

@end

/**
 VC With camera preview used to detect and read QR Code data.
 */
@interface IdCloudQrCodeReader : BaseViewController

/**
 Prepare current instance of reader to be shown.

 @param delegate Listener class
 */
+ (instancetype)readerWithDelegate:(id<IdCloudQrCodeReaderDelegate>)delegate;

@end
