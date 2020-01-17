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

#import "QRCodeReaderVC.h"
#import <AVFoundation/AVFoundation.h>

@interface QRCodeReaderVC() <AVCaptureMetadataOutputObjectsDelegate>

// Logic layer. In final application this should be separated.
// But for sample purposes we want to keep things simple. And have this as standalone QR Reader class.
@property (nonatomic, strong)   AVCaptureSession                *captureSession;
@property (nonatomic, strong)   AVCaptureVideoPreviewLayer      *capturePreview;

// Make sure, that we will send notification just once.
@property (nonatomic, assign)   BOOL                            wasProcessed;
@property (nonatomic, assign)   BOOL                            navBarHidden;

@end

@implementation QRCodeReaderVC

// MARK: - Life Cycle

- (void)init:(id<QRCodeReaderDelegate>)delegate customTag:(NSInteger)customTag
{
    _delegate   = delegate;
    _customTag  = customTag;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
        
    [self captureStart];
    
    // Display navigation bar if it was hidden.
    _navBarHidden = self.navigationController.isNavigationBarHidden;
    if (_navBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Hide navigation bar if it was hidden.
    if (_navBarHidden) {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }
}
    
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self captureStop];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // This is enough to have proper size, but orientation might not be handled.
    [self captureUpdateBounds];
}

-(void)viewWillTransitionToSize:(CGSize)size
      withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // This way we might reload constraint multiple times, but it will solve issue with 180 degree landscape change.
    // And trigger viewDidLayoutSubviews even during such rotation.
    [self.view setNeedsLayout];
}

// MARK: - Helpers

-  (void)captureStart
{
    // We want to notify handler just once.
    _wasProcessed = NO;
    
    // Try to prepare capture device. This is not going to work on emulator and devices without camera in general.
    // Also user might not give permissions for camera.
    NSError                 *error          = nil;
    AVCaptureDevice         *captureDevice  = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput    *input          = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (error) {
        [self showNSErrorIfExists:error];
    } else {
        // Setup capture session. Output must be added before setting metadata types.
        AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
        self.captureSession = [[AVCaptureSession alloc] init];
        [_captureSession addInput:input];
        [_captureSession addOutput:captureMetadataOutput];
        
        // Define callback and detection type to QR.
        [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
        
        // Add preview layer to UI.
        self.capturePreview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        _capturePreview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.view.layer addSublayer:_capturePreview];

        // Update default bounds. But at this point it might not be loaded yet.
        [self captureUpdateBounds];
        
        // Run capturing
        [_captureSession startRunning];
    }
}

- (void)captureStop
{
    // Stop and release all reader related items.
    [_captureSession stopRunning];
    self.captureSession = nil;
    
    [_capturePreview removeFromSuperlayer];
    self.capturePreview = nil;
    
    _delegate   = nil;
    _customTag  = 0;
}

- (void)captureUpdateBounds
{
    // In case that something went wrong during init.
    if (!_capturePreview) {
        return;
    }
    
    // Fill up full view frame
    _capturePreview.frame       = self.view.layer.bounds;
    _capturePreview.position    = CGPointMake(CGRectGetMidX(_capturePreview.frame), CGRectGetMidY(_capturePreview.frame));
    
    // Update orientation
    if ([_capturePreview.connection isVideoOrientationSupported]) {
        _capturePreview.connection.videoOrientation = [self videoOrientation];
    }
}

// Return proper orientation for preview. Enum is different than status bar one.
- (AVCaptureVideoOrientation)videoOrientation
{
    switch ([UIApplication sharedApplication].statusBarOrientation)
    {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        case UIInterfaceOrientationUnknown:
            return AVCaptureVideoOrientationPortrait;
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // Continue only if there is just one item detected and nothing was processed yet.
    if (!metadataObjects || [metadataObjects count] != 1 || _wasProcessed) {
        return;
    }
    
    // We are interested in QR only.
    AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects firstObject];
    if (![[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
        return;
    }
    
    // Mark as processed so we will not trigger handler multiple times.
    _wasProcessed = YES;

    // Encrypt data and wipe source.
    id <EMSecureByteArray> qrCodeData = [[NSData dataWithHexString:metadataObj.stringValue] secureByteArray:YES];
    
    // Hide it self. This will also stop tracking after hide.
    // It's important to call before handler, because there might be some error popup etc.
    [self.navigationController popViewControllerAnimated:YES];
    
    // Notify listener
    if (_wasProcessed && _delegate) {
        [_delegate onQRCodeProvided:self qrCode:qrCodeData];
    }
    
    // Wipe encrypted data.
    [qrCodeData wipe];

}

@end
