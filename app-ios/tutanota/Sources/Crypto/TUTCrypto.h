//
//  TUTCrypto.h
//
//  Created by Tutao GmbH on 24.09.14.
//
//

NS_ASSUME_NONNULL_BEGIN

@interface TUTPublicKey : NSObject
@property(nonatomic, nonnull) NSNumber *version;
@property(nonatomic, nonnull) NSNumber *keyLength;
@property(nonatomic, nonnull) NSString *modulus;
@property(nonatomic, nullable) NSNumber *publicExponent;

-(instancetype) initWithDict:(NSDictionary<NSString *, id> *)dict;
@end

@interface TUTPrivateKey : TUTPublicKey
@property(nonatomic, nonnull) NSString *privateExponent;
@property(nonatomic, nonnull) NSString *primeP;
@property(nonatomic, nonnull) NSString *primeQ;
@property(nonatomic, nonnull) NSString *primeExponentP;
@property(nonatomic, nonnull) NSString *primeExponentQ;
@property(nonatomic, nonnull) NSString *crtCoefficient;

-(instancetype) initWithDict:(NSDictionary<NSString *, id> *)dict;
@end

@interface TUTKeyPair : NSObject
@property(nonatomic, nonnull) TUTPublicKey *publicKey;
@property(nonatomic, nonnull) TUTPrivateKey *privateKey;
@end

/**
   Low-level cryptographic operations.
 */
@interface TUTCrypto : NSObject

- (TUTKeyPair *_Nullable)generateRsaKeyWithSeed:(NSString * _Nonnull)base64Seed error:(NSError **)error;

- (NSString *_Nullable)rsaEncryptWithPublicKey:(TUTPublicKey *_Nonnull)publicKey
                                    base64Data:(NSString * _Nonnull)base64Data
                                    base64Seed:(NSString * _Nonnull)base64Seed
                                         error: (NSError **)error;

- (NSString *_Nullable)rsaDecryptWithPrivateKey:(TUTPrivateKey *)privateKey
                                     base64Data:(NSString *)base64Data
                                          error:(NSError **)error;

+ (NSData * )sha256:(NSData *)data;

+ (NSData *)generateIv;

@end

NS_ASSUME_NONNULL_END
