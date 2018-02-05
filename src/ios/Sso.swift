import Foundation
import LineSDK

@objc(Sso) class Sso : CDVPlugin, LineSDKLoginDelegate {
    
    var callbackId:String?
    

    override func pluginInitialize() {
        LineSDKLogin.sharedInstance().delegate = self
        
        // let result = CDVPluginResult(status: CDVCommandStatus_OK)
        // commandDelegate.send(result, callbackId:command.callbackId)
    }

    func loginWithLine(_ command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        LineSDKLogin.sharedInstance().start()
    }
    
    func didLogin(_ login: LineSDKLogin, credential: LineSDKCredential?, profile: LineSDKProfile?, error: Error?) {
        
        if error != nil {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.debugDescription)
            commandDelegate.send(result, callbackId:self.callbackId)
        } else {
            var data = ["userID":nil, "displayName":nil, "pictureURL":nil, "accessToken":nil] as [String : Any?]
            if let displayName = profile?.displayName {
                data.updateValue(displayName, forKey: "displayName")
            }
            if let userID = profile?.userID {
                data.updateValue(userID, forKey: "userID")
            }
            if let pictureURL = profile?.pictureURL {
                data.updateValue(String(describing: pictureURL), forKey: "pictureURL")
            }
            if let _acessToken = credential?.accessToken?.accessToken as? String {
                data.updateValue(_acessToken, forKey: "accessToken")
            }

            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:data)
            commandDelegate.send(result, callbackId:self.callbackId)
        }
    }
}
