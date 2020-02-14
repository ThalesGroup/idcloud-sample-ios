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

#import "IdCloudQrCodeReader.h"
#import <AVFoundation/AVFoundation.h>

@interface IdCloudQrCodeReader() <AVCaptureMetadataOutputObjectsDelegate>

// Logic layer. In final application this should be separated.
// But for sample purposes we want to keep things simple. And have this as standalone QR Reader class.
@property (nonatomic, strong)   AVCaptureSession            *captureSession;
@property (nonatomic, strong)   AVCaptureVideoPreviewLayer  *capturePreview;

// Make sure, that we will send notification just once.
@property (nonatomic, assign)   BOOL                        wasProcessed;
@property (nonatomic, weak)     IBOutlet UIView             *cameraLayer;

@property (nonatomic, weak)     id<IdCloudQrCodeReaderDelegate> delegate;

@end

@implementation IdCloudQrCodeReader

// MARK: - Life Cycle

+ (instancetype)readerWithDelegate:(id<IdCloudQrCodeReaderDelegate>)delegate {
    return [[IdCloudQrCodeReader alloc] initWithDelegate:delegate ];
}

- (instancetype)initWithDelegate:(id<IdCloudQrCodeReaderDelegate>)delegate {
    if (self = [super initWithNibName:NSStringFromClass(self.class)
                               bundle:[NSBundle bundleForClass:self.class]]) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.delegate               = delegate;
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    [self captureStart];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self captureStop];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // This is enough to have proper size, but orientation might not be handled.
    [self captureUpdateBounds];
}

-(void)viewWillTransitionToSize:(CGSize)size
      withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // This way we might reload constraint multiple times, but it will solve issue with 180 degree landscape change.
    // And trigger viewDidLayoutSubviews even during such rotation.
    [self.cameraLayer setNeedsLayout];
    [self.view setNeedsLayout];
}

// MARK: - Helpers

-  (void)captureStart {
    // We want to notify handler just once.
    _wasProcessed = NO;
    
    // Try to prepare capture device. This is not going to work on emulator and devices without camera in general.
    // Also user might not give permissins for camera.
    NSError                 *error          = nil;
    AVCaptureDevice         *captureDevice  = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput    *input          = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (error) {
        notifyDisplayErrorIfExists(error);
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
        [_cameraLayer.layer addSublayer:_capturePreview];

        // Update default bounds. But at this point it might not be loaded yet.
        [self captureUpdateBounds];
        
        // Run capturing
        [_captureSession startRunning];
    }
}

- (void)captureStop {
    // Stop and release all reader related items.
    [_captureSession stopRunning];
    self.captureSession = nil;
    
    [_capturePreview removeFromSuperlayer];
    self.capturePreview = nil;
    
    _delegate   = nil;
}

- (void)captureUpdateBounds {
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

// Return proper otientation for preview. Enum is different than statusbar one.
- (AVCaptureVideoOrientation)videoOrientation {
    switch ([UIApplication sharedApplication].statusBarOrientation) {
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

- (void)captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
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
    
    // Notify listener
    if (_wasProcessed && _delegate) {
        [_delegate onQRCodeProvided:self qrCode:qrCodeData];
    }
}

// MARK: - User Interface

- (IBAction)onButtonPressedCancel:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
