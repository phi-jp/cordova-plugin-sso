import Foundation
import LineSDK
import TwitterKit
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import AuthenticationServices

@objc(Sso) class Sso :CDVPlugin, GIDSignInDelegate, GIDSignInUIDelegate, ASAuthorizationControllerDelegate {

    
    var callbackId:String?
    var twitterLogin: TWTRTwitter?
    var googleSignin: GIDSignIn?
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
        ApplicationDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: [:])
        
        // for Google Signin
        let gid = self.commandDelegate.settings["googleclientid"] as? String;
        self.googleSignin = GIDSignIn.sharedInstance();
        
        self.googleSignin?.clientID = gid;
        
        // notification from appDelegate application
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).notifyFromAppDelegate(notification:)), name: Notification.Name.CDVPluginHandleOpenURLWithAppSourceAndAnnotation, object: nil)
    
    

    }

    
    // for LINE
    @objc func loginWithLine(_ command: CDVInvokedUrlCommand) {
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
    @objc func loginWithTwitter(_ command: CDVInvokedUrlCommand) {
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
    @objc func loginWithFacebook(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        // Logout before login
        let loginManger = LoginManager();
        loginManger.logOut();
        LoginManager().logIn(permissions: ["public_profile"], from: self.topMostController(), handler: self.fbLoginHandler(cordovaCallbackId: command.callbackId))
    }
    
    // for google
    @objc func loginWithGoogle(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId;
        GIDSignIn.sharedInstance().delegate = self;
        GIDSignIn.sharedInstance().uiDelegate = self;
        GIDSignIn.sharedInstance().signIn();
    }
    // below two function has been needed when login for gogole
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        print("dismissing Google SignIn")
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        print("presenting Google SignIn")
    }
    
    @objc func signInWithApple(_ command: CDVInvokedUrlCommand){
        if #available(iOS 13, *) {
            self.callbackId = command.callbackId
            let provider:ASAuthorizationAppleIDProvider = ASAuthorizationAppleIDProvider.init();
            let request: ASAuthorizationAppleIDRequest = provider.createRequest()
            request.requestedScopes = [.fullName, .email];
            let controller: ASAuthorizationController = ASAuthorizationController.init(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
        else {
            let result: CDVPluginResult = CDVPluginResult.init(status: CDVCommandStatus.error, messageAs: "not available singin with apple on your device")
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
    }
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            var data = [:] as! [String : Any]
            var name = [:] as! [String : String]
            let token = appleIDCredential.identityToken ?? Data.init(capacity: 0);
            let authorizationCode = appleIDCredential.authorizationCode ?? Data.init(capacity: 0)
            let fullname = appleIDCredential.fullName;
            
            data.updateValue(appleIDCredential.email ?? "", forKey: "email")
            data.updateValue(appleIDCredential.state ?? "", forKey: "state")
            data.updateValue(appleIDCredential.user, forKey: "user")
            data.updateValue(String(data: authorizationCode, encoding: String.Encoding.utf8), forKey: "authorizationCode")
            data.updateValue(String(data: token, encoding: String.Encoding.utf8)!, forKey: "token")
            
            if fullname != nil {
                name.updateValue(fullname?.givenName ?? "", forKey: "given_name")
                name.updateValue(fullname?.middleName ?? "", forKey: "middle_name")
                name.updateValue(fullname?.familyName ?? "", forKey: "family_name")
                name.updateValue(fullname?.namePrefix ?? "", forKey: "name_prefix")
                name.updateValue(fullname?.nameSuffix ?? "", forKey: "name_suffix")
                name.updateValue(fullname?.nickname ?? "", forKey: "nickname")
            }
            
            data.updateValue(name, forKey: "name");
            
            let result = CDVPluginResult(status: CDVCommandStatus.ok, messageAs: data);
            self.commandDelegate.send(result, callbackId: self.callbackId);
        }
    }
    
    @available(iOS 13, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let data = [
            "error": "ASAUTHORIZATION_ERROR",
            "localizedDescription": error.localizedDescription,
        ]

        let result = CDVPluginResult(status: CDVCommandStatus.error, messageAs: data);
        self.commandDelegate.send(result, callbackId: self.callbackId);
    }
    
    // Logout
    // If you have been logined once, the accessToken was saved in the device.
    // So if you try to refresh profile, you have to execute 'logout' method.

    // for Line
    @objc func logoutWithLine(_ command: CDVInvokedUrlCommand) {
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
    @objc func logoutWithTwitter(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        let store = TWTRTwitter.sharedInstance().sessionStore

        if let userID = store.session()?.userID {
            store.logOutUserID(userID)
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:"logout")
        self.commandDelegate.send(result, callbackId:self.callbackId)
    }

    // for Facebook
    @objc func logoutWithFacebook(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        
        if (AccessToken.current != nil) {
            let loginManger = LoginManager();
            loginManger.logOut();
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:"logout")
        self.commandDelegate.send(result, callbackId:self.callbackId)
    }
    
    // for logout
    @objc func logoutWithGoogle(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        self.googleSignin?.signOut()
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:"logouted")
        self.commandDelegate.send(result, callbackId:self.callbackId)
    }
    
    // facebook login handler
    private func fbLoginHandler(cordovaCallbackId: String) -> LoginManagerLoginResultBlock {
        let loginHandler: LoginManagerLoginResultBlock = { (result, error) -> Void in
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
                let token = AccessToken.current
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

                Profile.loadCurrentProfile { (profile, error) in
                    var profileError: Error
                    if (error != nil) {
                        profileError = error!
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
                            let image:String? = profile?.imageURL(forMode: Profile.PictureMode.square, size: CGSize(width: 1280, height: 1280))?.absoluteString
                            responseAuth.updateValue(image as Any, forKey: "image")
                        }
                        
                        let sendData = responseAuth
                        let cordovaResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: sendData as! [AnyHashable : Any])
                        self.commandDelegate.send(cordovaResult, callbackId:self.callbackId)
                    }
                }
                
            }
        }
        return loginHandler
    }
    
    // google signin handler
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            let cordovaResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
            self.commandDelegate.send(cordovaResult, callbackId:self.callbackId)
        } else {
            let res = self.googResponseObject(user);
            let cordovaResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: res)
            self.commandDelegate.send(cordovaResult, callbackId:self.callbackId)
        }
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
        
        return data;
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
    
    private func googResponseObject(_ user: GIDGoogleUser ) -> Dictionary<String, String> {
        var data = [:] as! [String : String];
        
        // user Profile
        if let userId = user.userID {
            data.updateValue(userId, forKey: "userId")
        }
        if let name = user.profile.name {
            data.updateValue(name, forKey: "name")
        }
        if let givenName = user.profile.givenName {
            data.updateValue(givenName, forKey: "givenName")
        }
        if let familyName = user.profile.familyName {
            data.updateValue(familyName, forKey: "familyName")
        }
        if let email = user.profile.email {
            data.updateValue(email, forKey: "email")
        }
        if let image = user.profile.imageURL(withDimension: 320) {
            data.updateValue(image.absoluteString, forKey: "image")
        }
        
        // Token
        if let token = user.authentication.idToken {
            data.updateValue(token, forKey: "token")
        }
        if let idToken = user.authentication.idToken {
            data.updateValue(idToken, forKey: "idToken")
        }
        if let refreshToken = user.authentication.refreshToken {
            data.updateValue(refreshToken, forKey: "refreshtoken")
        }
        if let accessToken = user.authentication.accessToken {
            data.updateValue(accessToken, forKey: "accessToken")
        }
        
        return data;
    }
    
    private func topMostController() -> UIViewController {
        var topController:UIViewController  = (UIApplication.shared.keyWindow?.rootViewController)!;
        while ((topController.presentedViewController) != nil) {
            topController = topController.presentedViewController!
        }
        
        return topController
    }
    
    @objc func notifyFromAppDelegate(notification: Notification) {
        guard  let object = notification.object as? [String:Any],
            let url = object["url"] as? URL else { return }
    
        let isFromTwitter = url.absoluteString.contains("twitterkit")
        let isFromLine = url.absoluteString.contains("line3rdp")
        let isFromFacebook = url.absoluteString.prefix(2) == "fb"
        let isFromGoogle = url.absoluteString.contains("com.googleusercontent")
        
        var options:[UIApplication.OpenURLOptionsKey:Any] = [:]
        
        var sourceApplication: String
        if let sa = object["sourceApplication"] as? String {
            sourceApplication = sa
        } else {
            sourceApplication = ""
        }
        options[UIApplication.OpenURLOptionsKey.sourceApplication] = sourceApplication
        
        let an = object["annotation"]
        if an != nil {
            options[UIApplication.OpenURLOptionsKey.openInPlace] = an
        } else {
            options[UIApplication.OpenURLOptionsKey.openInPlace] = 0
        }
        
        // twitter 用
        if isFromTwitter {
            TWTRTwitter().application(UIApplication.shared,
                                      open: url,
                                      options: options)
        }
        
        // line 用
        if isFromLine {
            _ = LoginManager.shared.application(UIApplication.shared, open: url, options: options)
        }
        
        // facebook 用
        if isFromFacebook {
            ApplicationDelegate.shared.application(UIApplication.shared,
                                                   open: url,
                                                   sourceApplication: sourceApplication,
                                                   annotation: options[UIApplication.OpenURLOptionsKey.openInPlace])
        }
        
        // google 用
        if isFromGoogle {
            GIDSignIn.sharedInstance().handle(url,
                                              sourceApplication: sourceApplication,
                                              annotation: an);
        }
    }
}
