//
//  WebviewHacks.h
//  tutanota
//
//  Created by Tutao GmbH on 10/20/21.
//  Copyright © 2021 Tutao GmbH. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WebviewHacks : NSObject
+ (void) keyboardDisplayDoesNotRequireUserAction;
+ (void)hideAccessoryBar;
@end

NS_ASSUME_NONNULL_END
