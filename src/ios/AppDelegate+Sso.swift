//
//  AppDelegate+Sso.m
//  cordova-plugin-sso Login
//
//  Created by shogo inc on 2018/02/04.
//
//

import UIKit
import LineSDK
import TwitterKit

class hogetohoge: AppDelegate {
  

    override func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        let urlStr: String = url.absoluteString

        if urlStr.contains("line3rdp") {
          return LineSDKLogin.sharedInstance().handleOpen(url)
        }

        else if urlStr.contains("twitterkit") {
          return Twitter.sharedInstance().application(app, open: url, options: options)
        }

        return false
    }
}
