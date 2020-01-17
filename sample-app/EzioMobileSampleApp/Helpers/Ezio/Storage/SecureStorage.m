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

#import "SecureStorage.h"

#define kSampleStorage @"SampleStorage"

@interface SecureStorage()

@property (nonatomic, strong) id<EMSecureStorageManager> manager;

@end

@implementation SecureStorage

// MARK: - Life Cycle

- (id)init
{
    if (self = [super init]) {
        self.manager = [[EMSecureStorageModule secureStorageModule] secureStorageManager];
    }
    
    return self;
}

// MARK: - StorageProtocol

- (BOOL)writeString:(NSString *)value forKey:(NSString *)key
{
    BOOL                    retValue    = NO;
    NSError                 *error      = nil;
    id<EMPropertyStorage>   storage     = [self getAndOpenStorage:&error];
    if (storage) {
        retValue = [storage setProperty:[value secureString]
                                 forKey:[key dataUsingEncoding:NSUTF8StringEncoding]
                              wipeValue:YES
                                  error:&error];
        [storage close:&error];
    }
    
    return retValue;
}
- (BOOL)writeInteger:(NSInteger)value forKey:(NSString *)key
{
    BOOL                    retValue        = NO;
    NSError                 *internalError  = nil;
    id<EMPropertyStorage>   storage         = [self getAndOpenStorage:&internalError];
    if (storage) {
        NSData *convertedValue = [NSData dataWithBytes:&value length:sizeof(NSInteger)];
        retValue = [storage setProperty:[convertedValue secureByteArray:YES]
                                 forKey:[key dataUsingEncoding:NSUTF8StringEncoding]
                              wipeValue:YES
                                  error:&internalError];
        [storage close:&internalError];
    }
    
    return retValue;
}

- (NSString *)readStringForKey:(NSString *)key
{
    NSString                *retValue       = nil;
    id<EMSecureByteArray>   value           = nil;
    NSError                 *internalError  = nil;
    id<EMPropertyStorage>   storage         = [self getAndOpenStorage:&internalError];
    if (storage) {
        value = [storage propertyForKey:[key dataUsingEncoding:NSUTF8StringEncoding] error:&internalError];
        [storage close:&internalError];
        
        // We want secure string instead of data.
        if (value) {
            retValue = [[NSString alloc] initWithData:value.dataValue encoding:NSUTF8StringEncoding];
            [value wipe];
        }
    }

    return retValue;
}

- (NSInteger)readIntegerForKey:(NSString *)key
{
    NSInteger               retValue        = 0;
    id<EMSecureByteArray>   value           = nil;
    NSError                 *internalError  = nil;
    id<EMPropertyStorage>   storage         = [self getAndOpenStorage:&internalError];
    if (storage) {
        value = [storage propertyForKey:[key dataUsingEncoding:NSUTF8StringEncoding] error:&internalError];
        [storage close:&internalError];
        
        // We want secure string instead of data.
        if (value) {
            [value.dataValue getBytes:&retValue length:sizeof(NSInteger)];
            [value wipe];
        }
    }
    
    return retValue;
}

- (BOOL)removeValueForKey:(NSString *)key
{
    BOOL                    retValue        = NO;
    NSError                 *internalError  = nil;
    id<EMPropertyStorage>   storage         = [self getAndOpenStorage:&internalError];
    if (storage) {
        retValue = [storage removePropertyForKey:[key dataUsingEncoding:NSUTF8StringEncoding] error:&internalError];
        [storage close:&internalError];
    }
    
    return retValue;
}

// MARK: - Private Helpers

- (id<EMPropertyStorage>)getAndOpenStorage:(NSError **)error
{
    // Try to get common storage.
    NSError                 *internalError  = nil;
    id<EMPropertyStorage>   retValue        = [_manager propertyStorageWithIdentifier:kSampleStorage error:&internalError];

    // Try to open given storage.
    if (retValue && !internalError) {
        [retValue open:&internalError];
    }

    // Transfer possible error.
    if (error) {
        *error = internalError;
    }
    
    return retValue;
}
@end
