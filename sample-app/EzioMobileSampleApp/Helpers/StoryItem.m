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

#import "StoryItem.h"

@implementation StoryItem

// MARK: - Life Cycle

+ (instancetype _Nullable )itemWithStoryboradName:(NSString *_Nonnull)storyBoardName
                                 storyboardItemId:(NSString *_Nonnull)storyboardItemId
{
    return [[StoryItem alloc] initWithStoryboradName:storyBoardName storyboardItemId:storyboardItemId];
}

- (instancetype _Nullable )initWithStoryboradName:(NSString *_Nonnull)storyBoardName
                                 storyboardItemId:(NSString *_Nonnull)storyboardItemId
{
    if (storyBoardName && storyboardItemId && (self = [super init]))
    {
        _storyboardName     = [storyBoardName copy];
        _storyboardItemId   = [storyboardItemId copy];
    }
    
    return self;
}

// MARK: - Predefined once

#define kStoryName                                  @"Main"

#define kStoryID_QRCodeReaderVC                     @"QRCodeReaderVC"
#define kStoryID_Tab_ProvisionVC                    @"Tab_ProvisionVC"
#define kStoryID_Tab_TokenDetail_AuthenticationVC   @"Tab_TokenDetail_AuthenticationVC"
#define kStoryID_Tab_TokenDetail_TransactionVC      @"Tab_TokenDetail_TransactionVC"
#define kStoryID_Tab_TokenDetail_SettingsVC         @"Tab_TokenDetail_SettingsVC"
#define kStoryID_Tab_GemaltoFaceIdVC                @"Tab_GemaltoFaceIdVC"

+ (instancetype)itemQrReader
{
    static StoryItem *retValue = nil;
    if (!retValue) {
        retValue = [StoryItem itemWithStoryboradName:kStoryName storyboardItemId:kStoryID_QRCodeReaderVC];
    }
    return retValue;
}

+ (instancetype)itemProvision
{
    static StoryItem *retValue = nil;
    if (!retValue) {
        retValue = [StoryItem itemWithStoryboradName:kStoryName storyboardItemId:kStoryID_Tab_ProvisionVC];
    }
    return retValue;
}

+ (instancetype)itemAuthentication
{
    static StoryItem *retValue = nil;
    if (!retValue) {
        retValue = [StoryItem itemWithStoryboradName:kStoryName storyboardItemId:kStoryID_Tab_TokenDetail_AuthenticationVC];
    }
    return retValue;
}

+ (instancetype)itemTransactionSign
{
    static StoryItem *retValue = nil;
    if (!retValue) {
        retValue = [StoryItem itemWithStoryboradName:kStoryName storyboardItemId:kStoryID_Tab_TokenDetail_TransactionVC];
    }
    return retValue;
}

+ (instancetype)itemSettings
{
    static StoryItem *retValue = nil;
    if (!retValue) {
        retValue = [StoryItem itemWithStoryboradName:kStoryName storyboardItemId:kStoryID_Tab_TokenDetail_SettingsVC];
    }
    return retValue;
}

+ (instancetype)itemGemaltoFaceId
{
    static StoryItem *retValue = nil;
    if (!retValue) {
        retValue = [StoryItem itemWithStoryboradName:kStoryName storyboardItemId:kStoryID_Tab_GemaltoFaceIdVC];
    }
    return retValue;
}
@end
