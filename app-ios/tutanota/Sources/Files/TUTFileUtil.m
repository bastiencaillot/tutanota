
#import "Swiftier.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import "TUTFileViewer.h"
#import "TUTFileUtil.h"
#import "tutanota-Swift.h"

static NSString * const FILES_ERROR_DOMAIN = @"tutanota_files";


// TODO: delete after splitting CryptoFacade
@implementation TUTFileUtil

+ (NSString *) getEncryptedFolder:(NSError **)error {
    NSString * encryptedFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:@"encrypted"];
    [[NSFileManager defaultManager] createDirectoryAtPath:encryptedFolder
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:error];
    return encryptedFolder;
}

+ (NSString *) getDecryptedFolder:(NSError **)error  {
    NSString *decryptedFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:@"decrypted"];
    [[NSFileManager defaultManager] createDirectoryAtPath:decryptedFolder
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:error];
    return decryptedFolder;	
}


+ (BOOL) fileExistsAtPath:(NSString*)path  {
	return [[NSFileManager defaultManager] fileExistsAtPath:path];
};

+ (NSURL*) urlFromPath:(NSString*)path{
	return  [NSURL fileURLWithPath:path];
};

+ (NSString*) pathFromUrl:(NSURL*)url	{
	return [url path];
};

@end

			
