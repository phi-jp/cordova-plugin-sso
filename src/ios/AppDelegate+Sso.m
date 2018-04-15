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
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <GoogleSignIn/GoogleSignIn.h>

@implementation AppDelegate(Sso)

- (BOOL)application: (UIApplication *)app
                              openURL: (NSURL *)url
                              options: (NSDictionary *)options
{
    
    NSRange twitter = [url.absoluteString rangeOfString:@"twitterkit"];
    NSRange line = [url.absoluteString rangeOfString:@"line3rdp"];
    NSRange google = [url.absoluteString rangeOfString:@"com.googleusercontent"];
    BOOL fb = [url.absoluteString hasPrefix: @"fb"];
    
    if (twitter.location != NSNotFound) {
        return [[Twitter sharedInstance] application:app openURL:url options:options];
    }
    else if (line.location != NSNotFound) {
        return [[LineSDKLogin sharedInstance] handleOpenURL:url];
    }
    else if (fb) {
        return [[FBSDKApplicationDelegate sharedInstance] application:app
            openURL:url
            sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
            annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    }
    else if (google.location != NSNotFound) {
        return [[GIDSignIn sharedInstance] handleURL:url
            sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
            annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    }
    else {
        // call super
        return [self application:app openURL:url options:options];
    }
}

- (void) applicationDidBecomeActive:(NSNotification *) notification {
    [FBSDKAppEvents activateApp];
}

@end
