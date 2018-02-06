//
//  AppDelegate+Sso.m
//  Sso
//
//  Created by shogo on 2018/02/04.
//
//

#import "AppDelegate+Sso.h"
#import <objc/runtime.h>
#import <LineSDK/LineSDK.h>
#import <TwitterKit/TwitterKit.h>

@implementation AppDelegate (Sso)


- (BOOL)application: (UIApplication *)app
                              openURL: (NSURL *)url
                              options: (NSDictionary *)options
{
    
    NSRange twitter = [url.absoluteString rangeOfString:@"twitterkit"];
    NSRange line = [url.absoluteString rangeOfString:@"line3rdp"];
    
    if (twitter.location != NSNotFound) {
        return [[Twitter sharedInstance] application:app openURL:url options:options];
    }
    else if (line.location != NSNotFound) {
        return [[LineSDKLogin sharedInstance] handleOpenURL:url];
    }
    else {
        // call super
        return [self application:app openURL:url options:options];
    }
}

@end