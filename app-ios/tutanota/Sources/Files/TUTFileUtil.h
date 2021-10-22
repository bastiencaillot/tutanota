#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TUTFileUtil : NSObject
/** Helper functions for file access. */
+ (NSString *_Nullable) getEncryptedFolder:(NSError * _Nullable * )error;
+ (NSString *_Nullable) getDecryptedFolder:(NSError * _Nullable * )error;
+ (BOOL) fileExistsAtPath:(NSString *)path;
+ (NSURL *) urlFromPath:(NSString *)path;
+ (NSString *) pathFromUrl:(NSURL *)url;
@end

NS_ASSUME_NONNULL_END
