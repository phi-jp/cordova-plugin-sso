import Foundation
import LineSDK
import TwitterKit
import FBSDKCoreKit
import FBSDKLoginKit

@objc(Sso) class Sso :CDVPlugin {

    
    
    var callbackId:String?
    var twitterLogin: TWTRTwitter?
    
    // init
    override func pluginInitialize() {
        // for LINE
        let lineChannelId = self.commandDelegate.settings["linechannelid"]
        LoginManager.shared.setup(channelID: lineChannelId as! String, universalLinkURL: nil)
        
        
        // for Twitter
        let consumerKey = self.commandDelegate.settings["twitterconsumerkey"] as? String
        let consumerSecret = self.commandDelegate.settings["twitterconsumersecret"] as? String
        
        twitterLogin =  TWTRTwitter.sharedInstance()
        twitterLogin?.start(withConsumerKey: consumerKey!, consumerSecret: consumerSecret!);
        
        // for Facebook
        FBSDKApplicationDelegate.sharedInstance().application(UIApplication.shared, didFinishLaunchingWithOptions: [:])
        
        
        // notification from appDelegate application
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).notifyFromAppDelegate(notification:)), name: Notification.Name.CDVPluginHandleOpenURLWithAppSourceAndAnnotation, object: nil)

    }

    
    // for LINE
    func loginWithLine(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        LoginManager.shared.login(permissions: [.profile], in: CDVViewController()) {
            result in
            switch result {
            case .success(let loginResult):
                let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: self.lineResponseObject(result: loginResult))
                
                self.commandDelegate.send(result, callbackId: self.callbackId)
            case .failure(let error):
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.errorDescription)
                self.commandDelegate.send(result, callbackId:self.callbackId)
            }
        }
    }
    
    // for Twitter
    func loginWithTwitter(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId

        self.twitterLogin?.logIn(with: CDVViewController(), completion: { (session, error) in
            if (session != nil) {
                
                let client = TWTRAPIClient(userID: session?.userID)
                client.loadUser(withID: (session?.userID)!) { (user, error) -> Void in
                    if (error != nil) {
                        let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.debugDescription)
                        self.commandDelegate.send(result, callbackId:self.callbackId)
                    }
                    else {
                        
                        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: self.twResponseObject(session, user))
                        self.commandDelegate.send(result, callbackId:self.callbackId)
                    }
                }
            } else {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.debugDescription)
                self.commandDelegate.send(result, callbackId:self.callbackId)
            }
        })
    }

    // for Facebook
    func loginWithFacebook(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        
        // Logout before login
        let loginManger:FBSDKLoginManager = FBSDKLoginManager();
        loginManger.logOut();
        FBSDKLoginManager().logIn(withReadPermissions: ["public_profile"], from: self.topMostController(), handler: self.fbLoginHandler())
    }
    
    // Logout
    // If you have been logined once, the accessToken was saved in the device.
    // So if you try to refresh profile, you have to execute 'logout' method.

    // for Line
    func logoutWithLine(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        
        LoginManager.shared.logout { result in
            switch result {
            case .success:
                let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:"logout")
                self.commandDelegate.send(result, callbackId:self.callbackId)
                print("Logout from LINE")
            case .failure(let error):
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs:"error")
                self.commandDelegate.send(result, callbackId:self.callbackId)
            }
        }

    }

    // for Twitter
    func logoutWithTwitter(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        let store = TWTRTwitter.sharedInstance().sessionStore

        if let userID = store.session()?.userID {
            store.logOutUserID(userID)
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:"logout")
        self.commandDelegate.send(result, callbackId:self.callbackId)
    }

    // for Facebook
    func logoutWithFacebook(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        
        if (FBSDKAccessToken.current() != nil) {
            let loginManger:FBSDKLoginManager = FBSDKLoginManager();
            loginManger.logOut();
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:"logout")
        self.commandDelegate.send(result, callbackId:self.callbackId)
    }
    
    // facebook login handler
    private func fbLoginHandler() -> FBSDKLoginManagerRequestTokenHandler {
        let loginHandler: FBSDKLoginManagerRequestTokenHandler = { (result, error) -> Void in
            if (error != nil) {
                // If the SDK has a message for the user, surface it.
                let errorMessage = "There was a problem logging you in."
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: errorMessage)
                self.commandDelegate.send(result, callbackId:self.callbackId)
                return
            }
            else if (result?.isCancelled)! {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "User cancelled")
                self.commandDelegate.send(result, callbackId:self.callbackId)
            }
            else {
                let res = self.fbResponseObject();
    
                if (res["status"] as! String == "connected") {
                    let sendData = res["authResponse"]
                    let cordovaResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: sendData as! [AnyHashable : Any])
                    self.commandDelegate.send(cordovaResult, callbackId:self.callbackId)
                }
                else {
                    let cordovaResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "occur error when get User data")
                    self.commandDelegate.send(cordovaResult, callbackId:self.callbackId)
                }
            }
        }
        return loginHandler
    }
    
    private func twResponseObject(_ session:TWTRSession? , _ user:TWTRUser? ) -> Dictionary<String, Any> {
        var data = ["name": nil, "screenName": nil, "userId": nil, "image": nil, "secret": nil, "token": nil] as [String: Any?]
        if let name = user?.name {
            data.updateValue(name, forKey: "name")
        }
        if let screenName = user?.screenName {
            data.updateValue(screenName, forKey: "screenName")
        }
        if let userID = user?.userID {
            data.updateValue(userID, forKey: "userId")
        }
        if let image = user?.profileImageURL {
            data.updateValue(image, forKey: "image")
        }
        if let secret = session?.authTokenSecret {
            data.updateValue(secret, forKey: "secret")
        }
        if let token = session?.authToken {
            data.updateValue(token, forKey: "token")
        }
        
        return data
    }
    
    private func lineResponseObject(result: LoginResult) -> Dictionary<String, String> {
        
        var data = [:] as! [String : String]
        
        
        if let displayName = result.userProfile?.displayName {
            data.updateValue(displayName, forKey: "name")
        }
        if let userID = result.userProfile?.userID {
            data.updateValue(userID, forKey: "userId")
        }
        if let pictureURL = result.userProfile?.pictureURLLarge {
            data.updateValue(String(describing: pictureURL), forKey: "image")
        }
        
        
        data.updateValue(result.accessToken.value, forKey: "token")

        return data
    }
    
    private func fbResponseObject() -> Dictionary<String, Any> {
        
        if (!(FBSDKAccessToken.current() != nil)) {
            return [ "status": "unknown" ]
        }
        
        var response:Dictionary = ["status" : nil, "authResponse": nil] as [String : Any?]
        
        
        let token = FBSDKAccessToken.current()
        let expiresTimeInterval = token?.expirationDate.timeIntervalSinceNow
        var expiresIn = "0"

        if (expiresTimeInterval! > 0) {
            expiresIn = NSString(format: "%0.0f", expiresTimeInterval!) as String
        }
        var responseAuth:Dictionary<String, Any> = [
            "name": "",
            "image": "",
            "first_name": "",
            "last_name": "",
            "token": token?.tokenString as Any,
            "expiresIn": expiresIn,
            "secret": "...",
            "session_key" : true,
            "sig": "...",
            "userId" : token?.userID as Any,
        ]
        
        var keepAlive = true
        let runRoop = RunLoop.current
        var profileError:Error?
    
        FBSDKProfile.loadCurrentProfile { (profile, error) in
            if (error != nil) {
                profileError = error
            }
            else {
                if let firstname = profile?.firstName, let lastname = profile?.lastName {
                    let name = firstname + lastname
                    responseAuth.updateValue(name, forKey: "name")
                }
                if let firstname = profile?.firstName {
                    responseAuth.updateValue(firstname, forKey: "first_name")
                }
                if let lastName = profile?.lastName {
                    responseAuth.updateValue(lastName, forKey: "last_name")
                }
                if (profile != nil) {
                    let image:String? = profile?.imageURL(for: FBSDKProfilePictureMode.square, size: CGSize(width: 320, height: 320)).absoluteString
                    responseAuth.updateValue(image as Any, forKey: "image")
                }
            }
            keepAlive = false
        }

        while keepAlive && runRoop.run(mode: .defaultRunLoopMode, before: NSDate(timeIntervalSinceNow: 0.1) as Date) {
            //wait...
        }

        if (profileError != nil) {
            return [ "status": "unknown" ]
        }
        else {
            response.updateValue("connected", forKey: "status")
            response.updateValue(responseAuth, forKey: "authResponse")
            return response as Any as! Dictionary<String, Any>
        }
    }

    private func topMostController() -> UIViewController {
        var topController:UIViewController  = (UIApplication.shared.keyWindow?.rootViewController)!;
        while ((topController.presentedViewController) != nil) {
            topController = topController.presentedViewController!
        }
        
        return topController
    }
    
    func notifyFromAppDelegate(notification: Notification) {
        if let object = notification.object {
            let url = ((object as! [String: Any])["url"])!
            let isFromTwitter = (url as! NSURL).absoluteString!.contains("twitterkit")
            let isFromLine = (url as! NSURL).absoluteString!.contains("line3rdp")
            let isFromFacebook = (url as! NSURL).absoluteString!.prefix(2) == "fb";
            
            
            let sourceApplication = ((object as! [String: Any])["sourceApplication"])!
            let annotation = ((object as! [String: Any])["annotation"])
            var options:[UIApplication.OpenURLOptionsKey:Any] = [:]
            
            options[UIApplication.OpenURLOptionsKey.sourceApplication] = sourceApplication
            
            if let an = annotation {
                options[UIApplication.OpenURLOptionsKey.openInPlace] = an
                return
            }
            else {
                options[UIApplication.OpenURLOptionsKey.openInPlace] = 0
            }
            
            
            if isFromTwitter {
                TWTRTwitter().application(UIApplication.shared, open: url as! URL, options: options)
            }
            
            if isFromLine {
                LoginManager.shared.application(UIApplication.shared, open: url as? URL, options: options)  
            }
            
            if isFromFacebook {
                FBSDKApplicationDelegate.sharedInstance()?.application(UIApplication.shared, open: url as? URL, sourceApplication: sourceApplication as? String, annotation: options[UIApplication.OpenURLOptionsKey.openInPlace])
            }
        }
    }
}
