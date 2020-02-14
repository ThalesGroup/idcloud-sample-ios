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

/**
 Used for any generic function where we are interested of result.

 @param success Whenever operation was successful or not.
 @param error Description when operation did failed.
 */
typedef void (^GenericCompletion)(BOOL success, NSError *error);

/**
Used for getting pin where operation might not be succesfull.

@param pin User entered pin auth input.
@param error Description when operation did failed.
*/
typedef void (^PinAuthInputCompletion)(id<EMPinAuthInput> pin, NSString *error);


/**
 OTP Helper handler

 @param otp OTP value
 @param input AuthInput used for last OTP calculation
 @param serverChallenge ServerChallenge used for last OTP calculation
 @param error Description when operation did failed.
 */
typedef void (^OTPCompletion)(id<EMSecureString> otp, id<EMAuthInput> input, id<EMSecureString> serverChallenge, NSError *error);


/**
 Sample app does have two different samples for storing values.
 This protocol will unify API.
 */
@protocol StorageProtocol

/**
 Write string to storage. It will override existing key.

 @param value Value we want to store.
 @param key Key of value to be stored.
 @return YES if storing was successful.
 */
- (BOOL)writeString:(NSString *)value forKey:(NSString *)key;

/**
 Write int to storage. It will override existing key.

 @param value Value we want to store.
 @param key Key of value to be stored.
 @return YES if storing was successful.
 */
- (BOOL)writeInteger:(NSInteger)value forKey:(NSString *)key;

/**
 Get stored string value. Return null if given key does not exists.

 @param key Key of stored value.
 @return Stored value.
 */
- (NSString *)readStringForKey:(NSString *)key;

/**
  Get stored int value. Return null if given key does not exists.

 @param key Key of stored value.
 @return Stored value.
 */
- (NSInteger)readIntegerForKey:(NSString *)key;

/**
 Remove existing value from storage.

 @param key Key of stored value.
 @return YES if removing was successful.
 */
- (BOOL)removeValueForKey:(NSString *)key;

@end


