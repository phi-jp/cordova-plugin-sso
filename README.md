# cordova-plugin-sso


## What ?

If you use this plugin, you can be available for realizing SSO (Single Sign On) at Twitter, Facebook and LINE

## Install

```
$ cordova plguin add cordova-plugin-sso
```

And add config.xml below code

```xml
<plugin name="cordova-plugin-sso" spec="0.0.9">
    <variable name="LINE_BUNDLE_ID" value="line3rdp.[YOUR BUNDLE ID]" />
    <variable name="LINE_CHANNEL_ID" value=[LINE_CHANNLE_ID] />
    <variable name="TWITTER_KEY" value=[Twitter Consumer Key] />
    <variable name="TWITTER_SECRET" value=[Twitter Consumer Secret] />
    <variable name="FACEBOOK_APP_ID" value=[Facebook app id] />
    <variable name="FACEBOOK_APP_NAME" value=[Facebook app name] />
</plugin>

```

## Service Settings 

### LINE

- To get Signiture, you execute below code

```
$ keytool -exportcert -alias androiddebugkey -keystore .keystore | openssl sha1 -binary | openssl md5
```

### Twitter

### Facebook


#### for iOS

To get client id & reversed client id, you have to register your project to Google firebase console.

https://developers.google.com/identity/sign-in/ios/sdk/

As regster your appliction, you get GoogleService-Info.plist.

You can see client id & reversed client id on the text editor.


#### for Android

https://developers.google.com/mobile/add?platform=android&cntapi=signin

When you regster your appliction, you have to set the SHA1 fingerprint.

`keytool -exportcert -keystore <path-to-debug-or-production-keystore> -list -v -alias <alias-name>`

If your project is only debug, only you have to do is entering below code on the console.

`keytool -exportcert -keystore ~/.android/debug.keystore -list -v`



## Usage



### Available Service

- Twitter
- Line
- Facebook
- Google

### Login Example

```javascript
if (window.sso) {
  sso.twitter.login(function(result) {
    // success
    var data = {
      name: result.name,
      id: result.userId,
      token: result.token,
      image: result.image
    };

  }, function(error) {
    // error
    console.log(error);
  });
}
```

### Available Parameter


Every service has below parameters

- name 
- userId
- token
- image


Optional parameters below

### Logout

If you have been logined once, the accessToken was saved in the device.
So if you want to get the Token, profile, or etc.. from the beginning, you have to execute 'logout' method.


```javascript
if (window.sso) {
  sso.twitter.logout(function(message) {
    // success
    console.log(message) // -> display logout
  }, function(error) {
    // error
    console.log(error);
  });
}
```