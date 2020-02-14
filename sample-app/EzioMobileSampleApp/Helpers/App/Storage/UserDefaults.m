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

#import "UserDefaults.h"

@interface UserDefaults()

@property (nonatomic, strong) NSUserDefaults *manager;

@end

@implementation UserDefaults

// MARK: - Life Cycle

- (id)init {
    if (self = [super init]) {
        self.manager = [NSUserDefaults standardUserDefaults];
    }
    
    return self;
}

// MARK: - StorageProtocol

- (BOOL)writeString:(NSString *)value forKey:(NSString *)key {
    [_manager setObject:value forKey:key];
    return [_manager synchronize];
}

- (BOOL)writeInteger:(NSInteger)value forKey:(NSString *)key {
    [_manager setInteger:value forKey:key];
    return [_manager synchronize];
}

- (NSString *)readStringForKey:(NSString *)key {
    return [_manager objectForKey:key];
}

- (NSInteger)readIntegerForKey:(NSString *)key {
    return [_manager integerForKey:key];
}

- (BOOL)removeValueForKey:(NSString *)key {
    [_manager removeObjectForKey:key];
    return YES;
}
@end
