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

/**
 Example app tab / page configuration item.
 */
@interface StoryItem : NSObject

/**
 Name of story board file.
 */
@property (nonatomic, copy, readonly) NSString * _Nonnull storyboardName;
/**
 Name of item on story board.
 */
@property (nonatomic, copy, readonly) NSString * _Nonnull storyboardItemId;

/**
 Create new instance of StoryItem.

 @param storyBoardName Name of story board file
 @param storyboardItemId Name of item on story board
 @return New instance of StoryItem
 */
+ (instancetype _Nullable )itemWithStoryboradName:(NSString *_Nonnull)storyBoardName
                                 storyboardItemId:(NSString *_Nonnull)storyboardItemId;


/**
 Predefined item for QR Reader

 @return QR Reader StoryItem
 */
+ (instancetype _Nonnull)itemQrReader;

/**
 Predefined item for Provisioner
 
 @return Provisioner StoryItem
 */
+ (instancetype _Nonnull)itemProvision;

/**
 Predefined item for Authentication
 
 @return Authentication StoryItem
 */
+ (instancetype _Nonnull)itemAuthentication;

/**
 Predefined item for Transaction sign
 
 @return Authentication StoryItem
 */
+ (instancetype _Nonnull)itemTransactionSign;

/**
 Predefined item for Settings
 
 @return Settings StoryItem
 */
+ (instancetype _Nonnull)itemSettings;

/**
 Predefined item for Gemalto Face ID Settings
 
 @return Gemalto Face ID Settings StoryItem
 */
+ (instancetype _Nonnull)itemGemaltoFaceId;
@end
