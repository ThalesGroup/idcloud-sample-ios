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

#include "Configuration.h"

// MARK: - Common SDK

/**
 Activation code is used to enable OOB features.
 It should be provided by application.
 
 @return Activation code
 */
NSData * C_CFG_SDK_ACTIVATION_CODE()
{
    static const unsigned char raw[] =
    {   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00
    };
    
    return [NSData dataWithBytes:raw length:sizeof(raw)];
}

/**
 Optional value with custom finger print data. Used as input of encryption calculation
 
 @return Custom finger print source
 */
EMDeviceFingerprintSource *C_CFG_SDK_DEVICE_FINGERPRINT_SOURCE()
{
    NSData *customFP = [@"com.gemalto.ezio.mobile.EzioMobileSdkExample" dataUsingEncoding:NSUTF8StringEncoding];
    return [[EMDeviceFingerprintSource alloc] initWithCustomData:customFP
                                           deviceFingerprintType:[NSSet setWithObject:@(EMDeviceFingerprintTypeSoft)]];
}

/**
 For debug purposes we can weaken TLS configuration.
 In release mode all values must be set to NO. Otherwise it will cause runtime exception.
 
 @return TLS Configuration.
 */
EMTlsConfiguration *C_CFG_SDK_TLS_CONFIGURATION()
{
    return [[EMTlsConfiguration alloc] initWithInsecureConnectionAllowed:NO
                                                   selfSignedCertAllowed:NO
                                                 hostnameMismatchAllowed:NO];
}

// MARK: - OTP

/**
 Define Token related behaviour on jailbroken devices.
 See EMTokenJailbreakPolicy for more details.
 
 @return Jailbreak policy
 */
EMTokenJailbreakPolicy C_CFG_OTP_JAILBREAK_POLICY()
{
    return EMTokenJailbreakPolicyIgnore;
}

/**
 Replace this byte array with your own EPS key modulus..
 The EPS' RSA modulus. This is specific to the configuration of the bank's system. Therefore other values should be used here.
 
 @return RSA Key modulus for OTP module.
 */
NSData *C_CFG_OTP_RSA_KEY_MODULUS()
{
    static const unsigned char  raw[] = {
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00
    };
    return [NSData dataWithBytes:raw length:sizeof(raw)];
}

/**
 Replace this byte array with your own EPS key exponent.
 The EPS' RSA exponent. This is specific to the configuration of the bank's system. Therefore other values should be used here.
 
 @return RSA Key exponent for OTP module.
 */
NSData *C_CFG_OTP_RSA_KEY_EXPONENT()
{
    static const unsigned char raw[] = {0x00, 0x00, 0x00};
    return [NSData dataWithBytes:raw length:sizeof(raw)];
}

/**
 Replace this URL with your EPS URL.
 
 @return Provisioning URL
 */
NSURL *C_CFG_OTP_PROVISION_URL()
{
    return [NSURL URLWithString:@""];
}

/**
 Replace this string with your own EPS key ID.
 This is specific to the configuration of the bank's system. Therefore other values should be used here.
 
 @return RSA Key ID.
 */
NSString *C_CFG_OTP_RSA_KEY_ID()
{
    return @"";
}

/**
 The custom fingerprint data that seals all the token credentials in this example.
 
 @return Device fingerprint source.
 */
EMDeviceFingerprintTokenPolicy *C_CFG_OTP_DEVICE_FINGERPRINT_SOURCE()
{
    return [[EMDeviceFingerprintTokenPolicy alloc]
            initWithDeviceFingerprintSource:C_CFG_SDK_DEVICE_FINGERPRINT_SOURCE()
            failIfInvalid:YES];
}

/**
 Configuration of example OCRA suite used in this demo.
 
 @return OCRA suite
 */
id<EMSecureString> C_CFG_OTP_OCRA_SUITE()
{
    return [@"" secureString];
}

// MARK: - OOB

/**
 Define OOB related behaviour on jailbroken devices.
 See EMOobJailbreakPolicy for more details.
 
 @return Jailbreak policy
 */
EMOobJailbreakPolicy C_CFG_OOB_JAILBREAK_POLICY()
{
    return EMOobJailbreakPolicyIgnore;
}

/**
 Replace this byte array with your own OOB key modulus unless you are using the default key pair.
 This is specific to the configuration of the bank's system. Therefore other values should be used here.
 
 @return RSA Key modulus for OOB module.
 */
NSData *C_CFG_OOB_RSA_KEY_MODULUS()
{
    static const unsigned char raw[] = {
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    };
    return [NSData dataWithBytes:raw length:sizeof(raw)];
}

/**
 Replace this byte array with your own OOB key exponent.
 This is specific to the configuration of the bank's system. Therefore other values should be used here.
 
 @return RSA Key exponent for OOB module.
 */
NSData *C_CFG_OOB_RSA_KEY_EXPONENT()
{
    static const unsigned char raw[] = {0x00, 0x00, 0x00};
    return [NSData dataWithBytes:raw length:sizeof(raw)];
}

/**
 Replace this URL with your OOB server URL.
 This is specific to the configuration of the bank's system. Therefore other values should be used here.
 
 @return OOB server Url
 */
NSURL *C_CFG_OOB_URL()
{
    return [NSURL URLWithString:@""];
}

/**
 Replace this domain with your OOB server domain.
 This is specific to the configuration of the bank's system. Therefore other values should be used here.
 
 @return OOB server domain
 */
NSString *C_CFG_OOB_DOMAIN()
{
    return @"";
}

/**
 Replace this app id with your OOB server app id.
 This is specific to the configuration of the bank's system. Therefore other values should be used here.
 
 @return OOB server app id
 */
NSString *C_CFG_OOB_APP_ID()
{
    return @"";
}

/**
 Replace this push channel with your OOB server push channel.
 This is specific to the configuration of the bank's system. Therefore other values should be used here.
 
 @return OOB server push channel
 */
NSString *C_CFG_OOB_CHANNEL()
{
    return @"";
}

/**
 Replace this provider id with your OOB server provider id.
 This is specific to the configuration of the bank's system. Therefore other values should be used here.
 
 @return OOB server provider id
 */
NSString *C_CFG_OOB_PROVIDER_ID()
{
    return @"";
}

// MARK: - GEMALTO FACE ID

/**
 Use in order to activate Gemalto Face ID support.
 
 @return Gemalto Face ID product key
 */
NSString *C_CFG_FACE_ID_PRODUCT_KEY()
{
    return @"";
}

/**
 Use in order to activate Gemalto Face ID support.
 
 @return Gemalto Face ID server url.
 */
NSString *C_CFG_FACE_ID_SERVER_URL()
{
    return @"";
}

// MARK: - MSP

/**
 This sample app does not use MSP encryption.

 @return MSP Obfuscation keys
 */
NSArray *C_CFG_MSP_OBFUSCATION_CODE()
{
    return nil;
}

/**
 This sample app does not use MSP encryption.

 @return MSP Sign keys
 */
NSArray *C_CFG_MSP_SIGN_KEYS()
{
    return nil;
}

// MARK: - APP CONFIG

/**
 This sample application can be used to demonstrate different set of cases.
 Here we can define which tabs will be available.
 
 @return List of application tabs.
 */
NSArray<StoryItem *> *C_CFG_APP_TABS()
{
    // First two tabs are hardcoded, mandatory and fixed (itemProvision, itemAuthentication), they can't be added multiple times.
    // [StoryItem itemWithStoryboradName:@"Main" storyboardItemId:@"Tab_TokenDetail_TransactionVC"]
    return @[[StoryItem itemTransactionSign],
             [StoryItem itemSettings],
             [StoryItem itemGemaltoFaceId]];
}


/**
 This value is optional. In case that URL is not nil. It will display privacy policy button on settings page.

 @return Url to privacy policy.
 */
NSURL *C_CFG_PRIVACY_POLICY_URL()
{
    return [NSURL URLWithString:@""];
}

// MARK: - TUTU PAGE CONFIG


/**
 Tuto page does require authentication.

 @return User name
 */
NSString *C_CFG_TUTO_BASICAUTH_USERNAME()
{
    return @"";
}

/**
 Tuto page does require authentication.
 
 @return User password
 */
NSString *C_CFG_TUTO_BASICAUTH_PASSWORD()
{
    return @"";
}

/**
 Base tutorial page URL. Used for In Band cases.
 
 @return Url to tutorial page root.
 */
NSString *C_CFG_TUTO_URL_ROOT()
{
    return @"";
}

/**
 Auth API url used for In Band cases.
 
 @return Url to tutorial page auth.
 */
NSString *C_CFG_TUTO_URL_AUTH()
{
    return @"";
}

/**
 Transaction sign API url used for In Band cases.

 @return Url to tutorial page sign.
 */
NSString *C_CFG_TUTO_URL_SIGN()
{
    return @"";
}
