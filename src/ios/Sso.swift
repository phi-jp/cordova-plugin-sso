import Foundation
import LineSDK
import TwitterKit
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn


@objc(Sso) class Sso :CDVPlugin, LineSDKLoginDelegate, GIDSignInDelegate, GIDSignInUIDelegate {

    
    
    var callbackId:String?
    var lineSDKApi: LineSDKAPI?
    var googleSignin: GIDSignIn?
    
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

        // for Google
        googleSignin = GIDSignIn.sharedInstance()
        googleSignin?.clientID = self.commandDelegate.settings["googleclientid"] as? String
        googleSignin?.delegate = self
        googleSignin?.uiDelegate = self
    }


    
    // for LINE
    func loginWithLine(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        
        let lineSDKLogin = LineSDKLogin.sharedInstance()
        
        if (lineSDKLogin.canLoginWithLineApp()) {
            lineSDKLogin.start()
        }
        else {
            lineSDKLogin.startWebLogin(withSafariViewController: true)
        }
    }
    
    // for Twitter
    func loginWithTwitter(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        Twitter.sharedInstance().logIn(completion: { (session, error) in
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
        FBSDKAccessToken.refreshCurrentAccessToken(nil)
        FBSDKLoginManager().logIn(withReadPermissions: ["public_profile"], from: self.topMostController(), handler: self.fbLoginHandler())
    }
    
    // for Google
    func loginWithGoogle(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        googleSignin?.signIn()
    }
    
    

    
    // Logout
    // If you have been logined once, the accessToken was saved in the device.
    // So if you try to refresh profile, you have to execute 'logout' method.

    // for Line
    func logoutWithLine(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        lineSDKApi?.logout(queue: .main, completion:{ success, error in
            if (error != nil) {
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs:"error")
                self.commandDelegate.send(result, callbackId:self.callbackId)
            }
            else {
                let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:"logout")
                self.commandDelegate.send(result, callbackId:self.callbackId)
            }
        })
    }

    // for Twitter
    func logoutWithTwitter(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        let store = Twitter.sharedInstance().sessionStore

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

    func logoutWithGoogle(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        GIDSignIn.sharedInstance().signOut()
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:"logout")
        self.commandDelegate.send(result, callbackId:self.callbackId)
    }



    

    // line after login
    func didLogin(_ login: LineSDKLogin, credential: LineSDKCredential?, profile: LineSDKProfile?, error: Error?) {
        
        if error != nil {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.debugDescription)
            commandDelegate.send(result, callbackId:self.callbackId)
        } else {
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:self.lineResponseObject(credential, profile))
            commandDelegate.send(result, callbackId:self.callbackId)
            
            self.lineSDKApi = LineSDKAPI.init(configuration: LineSDKConfiguration.defaultConfig())
            
        }
    }
    
    
    // google after login
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("\(error.localizedDescription)")
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
            commandDelegate.send(result, callbackId:self.callbackId)
        } else {
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:self.googleResponseObject(didSignInFor: user))
            commandDelegate.send(result, callbackId:self.callbackId)
        }
    }
    
    // Present a view that prompts the user to sign in with Google
    func sign(_ signIn: GIDSignIn!,
              present viewController: UIViewController!) {
        self.viewController.present(viewController, animated: true, completion: nil)
    }
    
    // Dismiss the "Sign in with Google" view
    func sign(_ signIn: GIDSignIn!,
              dismiss viewController: UIViewController!) {
        self.viewController.dismiss(animated: true, completion: nil)
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
    
    private func lineResponseObject(_ credential: LineSDKCredential?, _ profile: LineSDKProfile?) -> Dictionary<String, Any> {
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
    
    private func googleResponseObject(didSignInFor user: GIDGoogleUser!)-> Dictionary<String, Any> {
        var data = ["name": nil, "first_name": nil, "last_name": nil, "token": nil ,"userId": nil, "image": nil, "email": nil] as [String: Any?]
        if let userId = user.userID {
            data.updateValue(userId, forKey: "userId")
        }
        if let idToken = user.authentication.idToken {
            data.updateValue(idToken, forKey: "token")
        }
        if let fullName = user.profile.name {
            data.updateValue(fullName, forKey: "name")
        }
        if let givenName = user.profile.givenName {
            data.updateValue(givenName, forKey: "first_name")
        }
        if let familyName = user.profile.familyName {
            data.updateValue(familyName, forKey: "last_name")
        }
        if let email = user.profile.email {
            data.updateValue(email, forKey: "email")
        }
        if let image = user.profile.imageURL(withDimension: 512) {
            data.updateValue(image.absoluteString, forKey: "image")
        }
        
        return data
    }

    private func topMostController() -> UIViewController {
        var topController:UIViewController  = (UIApplication.shared.keyWindow?.rootViewController)!;
        while ((topController.presentedViewController) != nil) {
            topController = topController.presentedViewController!
        }
        
        return topController
    }
    
}
