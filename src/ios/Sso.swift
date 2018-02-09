import Foundation
import LineSDK
import TwitterKit
import FBSDKCoreKit
import FBSDKLoginKit

@objc(Sso) class Sso : CDVPlugin, LineSDKLoginDelegate {
    
    var callbackId:String?
    
    // init
    override func pluginInitialize() {
        // for LINE
        LineSDKLogin.sharedInstance().delegate = self
        // let result = CDVPluginResult(status: CDVCommandStatus_OK)
        // commandDelegate.send(result, callbackId:command.callbackId)
        
        
        // for Twitter
        let consumerKey = self.commandDelegate.settings["twitterconsumerkey"] as? String
        let consumerSecret = self.commandDelegate.settings["twitterconsumersecret"] as? String
        Twitter.sharedInstance().start(withConsumerKey: consumerKey!, consumerSecret: consumerSecret!);

        // for Facebook
        FBSDKApplicationDelegate.sharedInstance().application(UIApplication.shared, didFinishLaunchingWithOptions: [:])
    }


    
    // for LINE
    func loginWithLine(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        LineSDKLogin.sharedInstance().start()
    }
    
    // for Twitter
    func loginWithTwitter(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        Twitter.sharedInstance().logIn(completion: { (session, error) in
            if (session != nil) {
                var data = ["name": nil, "screenName": nil, "userId": nil, "image": nil, "secret": nil, "token": nil] as [String: Any?]
                
                let client = TWTRAPIClient(userID: session?.userID)
                client.loadUser(withID: (session?.userID)!) { (user, error) -> Void in
                    if (error != nil) {
                        let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.debugDescription)
                        self.commandDelegate.send(result, callbackId:self.callbackId)
                    }
                    else {

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
                        
                        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data)
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
        FBSDKAccessToken.refreshCurrentAccessToken(nil)
        FBSDKLoginManager().logIn(withReadPermissions: ["public_profile"], from: self.topMostController(), handler: self.fbLoginHandler())
    }
    
    func didLogin(_ login: LineSDKLogin, credential: LineSDKCredential?, profile: LineSDKProfile?, error: Error?) {
        
        if error != nil {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.debugDescription)
            commandDelegate.send(result, callbackId:self.callbackId)
        } else {
            var data = ["userId":nil, "name": nil, "image":nil, "token":nil] as [String : Any?]
            if let displayName = profile?.displayName {
                data.updateValue(displayName, forKey: "name")
            }
            if let userID = profile?.userID {
                data.updateValue(userID, forKey: "userId")
            }
            if let pictureURL = profile?.pictureURL {
                data.updateValue(String(describing: pictureURL), forKey: "image")
            }
            if let _acessToken = credential?.accessToken?.accessToken as? String {
                data.updateValue(_acessToken, forKey: "token")
            }

            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:data)
            commandDelegate.send(result, callbackId:self.callbackId)
        }
    }
    
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
        
        
        var profileError:Error?
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.global(qos: .default).async {
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
                
                semaphore.signal()
            }
        }

        semaphore.wait();
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
}





