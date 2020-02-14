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

#import <UIKit/UIKit.h>
#import "EMFaceBaseManager.h"
#import "EMFaceView.h"
#import "EMCircularProgressView.h"
#import "EMFaceManager.h"


/**
 * @discussion Face UI SDK base UIViewController handling everything common between the verify and the enroll operation.
 */
@interface EMBaseViewController : UIViewController <EMFaceAuthUIDelegate>

/**
 * Start Button
 */
@property (nonatomic, weak) IBOutlet UIButton *startButton;

/**
 * Cancel Button
 */
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;

/**
 * Navigation Bar IBOutlet
 */
@property (nonatomic, weak) IBOutlet UINavigationBar *navBar;

/**
 * Navigation Item IBOutlet
 */
@property (nonatomic, weak) IBOutlet UINavigationItem *navItem;

/**
 * Status label where information like keeping his head in front of the camera is displayed.
 */
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;

/**
 * Status label where information like blinking eyes is displayed.
 */
@property (nonatomic, weak) IBOutlet UILabel *blinkLabel;

/**
 * Face View which contains the Face UI SDK output of the camera.
 */
@property (nonatomic, weak) IBOutlet EMFaceView *faceViewContainer;

/**
 * Overview to display circular progress bar. It contains the face view.
 */
@property (nonatomic, weak) IBOutlet EMCircularProgressView *overContainer;

/**
 * Success view where success message and image are displayed when the operation ends successfully.
 */
@property (nonatomic, weak) IBOutlet UIView *successView;

/**
 * Time out of the operation in seconds.
 */
@property NSTimeInterval timeout;

/**
 * Auto dismisses when either enroll or verification has succeeded. Default is NO.
 */
@property BOOL autoDismissWhenComplete;

/**
 * Global color used in the Face UI SDK.
 * @return UIColor
 */
+(UIColor *) green;
+(UIColor *) red;
+(UIColor *) textActive;
+(UIColor *) textInactive;

/**
 IBAction called when starting the current operation.

 @param sender calling object
 */
- (IBAction)startProcess:(id)sender;

/**
 IBAction called when canceling or terminating the current operation.

 @param sender sender calling object
 */
- (IBAction)cancelProcess:(id)sender;

@end

