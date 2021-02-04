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

// COMMON SDK
extern NSData                           *CFG_SDK_ACTIVATION_CODE();
extern EMDeviceFingerprintSource        *CFG_SDK_DEVICE_FINGERPRINT_SOURCE();
extern EMTlsConfiguration               *CFG_SDK_TLS_CONFIGURATION();

// OTP
extern EMTokenJailbreakPolicy           CFG_OTP_JAILBREAK_POLICY();
extern NSData                           *CFG_OTP_RSA_KEY_MODULUS();
extern NSData                           *CFG_OTP_RSA_KEY_EXPONENT();
extern NSURL                            *CFG_OTP_PROVISION_URL();
extern NSString                         *CFG_OTP_RSA_KEY_ID();
extern EMDeviceFingerprintTokenPolicy   *CFG_OTP_DEVICE_FINGERPRINT_SOURCE();
extern id<EMSecureString>               CFG_OTP_OCRA_SUITE();
extern NSString                         *CFG_DOMAIN();
extern NSData                           *CFG_CUSTOM_FINGERPRINT_DATA();

// OOB
extern EMOobJailbreakPolicy             CFG_OOB_JAILBREAK_POLICY();
extern NSData                           *CFG_OOB_RSA_KEY_MODULUS();
extern NSData                           *CFG_OOB_RSA_KEY_EXPONENT();
extern NSURL                            *CFG_OOB_URL();
extern NSString                         *CFG_OOB_DOMAIN();
extern NSString                         *CFG_OOB_APP_ID();
extern NSString                         *CFG_OOB_CHANNEL();
extern NSString                         *CFG_OOB_PROVIDER_ID();

// MSP
extern NSArray                          *CFG_MSP_OBFUSCATION_CODE();
extern NSArray                          *CFG_MSP_SIGN_KEYS();

// APP CONFIG
extern NSURL                            *CFG_PRIVACY_POLICY_URL();

// TUTU PAGE CONFIG
extern NSString                         *CFG_TUTO_BASICAUTH_USERNAME();
extern NSString                         *CFG_TUTO_BASICAUTH_PASSWORD();
extern NSString                         *CFG_TUTO_URL_ROOT();
extern NSString                         *CFG_TUTO_URL_AUTH();
extern NSString                         *CFG_TUTO_URL_SIGN();

// SECURE LOG
extern NSData                           *CFG_SECURE_LOG_RSA_KEY_MODULUS();
extern NSData                           *CFG_SECURE_LOG_RSA_KEY_EXPONENT();
