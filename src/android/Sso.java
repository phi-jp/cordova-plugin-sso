package com.singlesignon;

import com.linecorp.linesdk.LineApiResponseCode;
import com.linecorp.linesdk.LineProfile;
import com.linecorp.linesdk.auth.LineLoginApi;
import com.linecorp.linesdk.auth.LineLoginResult;

import com.twitter.sdk.android.core.*;
import com.twitter.sdk.android.core.identity.TwitterAuthClient;
import com.twitter.sdk.android.core.identity.TwitterLoginButton;
import com.twitter.sdk.android.core.models.*;
import com.twitter.sdk.android.core.services.*;

import com.facebook.Profile;
import com.facebook.ProfileManager;
import com.facebook.AccessToken;
import com.facebook.CallbackManager;
import com.facebook.FacebookCallback;
import com.facebook.FacebookDialogException;
import com.facebook.FacebookException;
import com.facebook.FacebookOperationCanceledException;
import com.facebook.FacebookRequestError;
import com.facebook.FacebookSdk;
import com.facebook.FacebookServiceException;
import com.facebook.GraphRequest;
import com.facebook.GraphResponse;
import com.facebook.FacebookAuthorizationException;
import com.facebook.appevents.AppEventsLogger;
import com.facebook.applinks.AppLinkData;
import com.facebook.login.LoginManager;
import com.facebook.login.LoginResult;
import com.facebook.share.ShareApi;
import com.facebook.share.Sharer;
import com.facebook.share.model.GameRequestContent;
import com.facebook.share.model.ShareHashtag;
import com.facebook.share.model.ShareLinkContent;
import com.facebook.share.model.ShareOpenGraphObject;
import com.facebook.share.model.ShareOpenGraphAction;
import com.facebook.share.model.ShareOpenGraphContent;
import com.facebook.share.model.AppInviteContent;
import com.facebook.share.widget.GameRequestDialog;
import com.facebook.share.widget.MessageDialog;
import com.facebook.share.widget.ShareDialog;
import com.facebook.share.widget.AppInviteDialog;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CallbackContext;

import jdk.nashorn.api.scripting.JSObject;
import jdk.nashorn.internal.runtime.JSONListAdapter;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import retrofit2.Call;

import com.google.gson.Gson;

import java.util.Arrays;

public class Sso extends CordovaPlugin {
	private static final String LOG_TAG = "Twitter Connect";
	private String action;
	private CallbackContext callbackContext;
	private CallbackManager fbCallbackManager;

	public void initialize(CordovaInterface cordova, CordovaWebView webView) {
		TwitterConfig config = new TwitterConfig.Builder(cordova.getActivity().getApplicationContext())
    		.twitterAuthConfig(new TwitterAuthConfig(getTwitterKey(), getTwitterSecret()))
    		.build();
		Twitter.initialize(config);
	}

	public boolean execute(final String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
		this.action = action;
		final Activity activity = this.cordova.getActivity();
		final Context context = activity.getApplicationContext();
		this.callbackContext = callbackContext;

		if (action.equals("loginWithTwitter")) {
			cordova.setActivityResultCallback(this);
			loginWithTwitter(activity, callbackContext);
			return true;
		}
		else if (action.equals("loginWithLine")) {
			Intent loginIntent = LineLoginApi.getLoginIntent(context, getLineChannelId());
			loginWithLine(activity, callbackContext);
			return true;
		}
		else if (action.equals("loginWithFacebook")) {
			cordova.setActivityResultCallback(this);
			loginWithFacebook(activity, callbackContext);
			return true;
		}
		else {
			return false;
		}
	}

	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent intent) {
		super.onActivityResult(requestCode, resultCode, intent);
		if (action.equals("loginWithTwitter")) {
			handleTwitterLoginResult(requestCode, resultCode, intent);
		}
		else if (action.equals("loginWithLine")) {
			LineLoginResult result = LineLoginApi.getLoginResultFromIntent(intent);
			callbackContext.success(getLineBaseUserData(result));
		}
		else if (action.equals("loginWithFacebook")) {
			fbCallbackManager.onActivityResult(requestCode, resultCode, intent);

		}
	}

	private void loginWithTwitter(final Activity activity, final CallbackContext callbackContext) {
		cordova.getThreadPool().execute(new Runnable() {
			@Override
			public void run() {
				TwitterAuthClient twitterAuthClient = new TwitterAuthClient();
				twitterAuthClient.authorize(activity, new Callback<TwitterSession>() {
					@Override
					public void success(final Result<TwitterSession> loginResult) {
						Log.v(LOG_TAG, "Successful login session!");
						UserShowServiceApi twitterApiClient = new UserShowServiceApi(TwitterCore.getInstance().getSessionManager().getActiveSession());
						UserShowService userService = twitterApiClient.getCustomService();

						// for get user detail
						Call<User> call = userService.show(TwitterCore.getInstance().getSessionManager().getActiveSession().getUserId(), true);
						call.enqueue(new Callback<User>() {
								@Override
								public void success(Result<User> result) {
										Log.v(LOG_TAG, "ShowUser API call successful!");
										JSONObject jsonUser = TwitterUserObjectToJSON(result.data);
										try {
												jsonUser.put("token", loginResult.data.getAuthToken().secret);
												jsonUser.put("secret", loginResult.data.getAuthToken().token);
										}
										catch (JSONException e) {
												e.printStackTrace();
										}
										callbackContext.success(getTwitterBaseUserData(jsonUser));
								}
								@Override
								public void failure(TwitterException e) {
										Log.v(LOG_TAG, "ShowUser API call failed.");
										callbackContext.error(e.getLocalizedMessage());
								}
						});
					}

					@Override
					public void failure(final TwitterException e) {
						Log.v(LOG_TAG, "Failed login session.");
						callbackContext.error("Failed login session.");
					}
				});
			}
		});
	}

	private void loginWithLine(final Activity activity, final CallbackContext callbackContext) {
		Context context = this.cordova.getActivity().getApplicationContext();
		Intent loginIntent = LineLoginApi.getLoginIntent(context, getLineChannelId());
		this.cordova.startActivityForResult((CordovaPlugin) this, loginIntent, 0);
	}

	private void loginWithFacebook(final Activity activity, final CallbackContext callbackContext) {
		LoginManager.getInstance().logInWithReadPermissions(activity, Arrays.asList("public_profile", "email", "user_friends"));
		cordova.getThreadPool().execute(new Runnable() {
			@Override
			public void run() {
				fbCallbackManager = CallbackManager.Factory.create();
				LoginManager loginManager = LoginManager.getInstance();
				loginManager.registerCallback(fbCallbackManager, new FacebookCallback<LoginResult>() {
					@Override
					public void onSuccess(LoginResult loginResult) {
						JSONObject result = getFacebookBaseUserData(loginResult);

						callbackContext.success(result);
					}

					@Override
					public void onCancel() {

					}

					@Override
					public void onError(FacebookException error) {

					}
				});
			}
		});
	}

	private String getTwitterKey() {
		return preferences.getString("TwitterConsumerKey", "");
	}

	private String getTwitterSecret() {
		return preferences.getString("TwitterConsumerSecret", "");
	}

	private String getLineChannelId() {
		return preferences.getString("LineChannelId", "");
	}


	private JSONObject TwitterUserObjectToJSON(User user) {
		Gson gson = new Gson();
		String jsonString = gson.toJson(user);

		JSONObject jsonUser = new JSONObject();
		try {
			jsonUser = new JSONObject(jsonString);
		} catch (JSONException e) {
			e.printStackTrace();
		}

		return jsonUser;
	}

	private JSONObject getTwitterBaseUserData(JSONObject data) {
		JSONObject jsonUser = new JSONObject();
		try {
			jsonUser.put("name", data.getString("name"));
			jsonUser.put("screenName", data.getString("screen_name"));
			jsonUser.put("userId", data.getString("id"));
			jsonUser.put("image", data.getString("profile_image_url"));
			jsonUser.put("secret", data.getString("secret"));
			jsonUser.put("token", data.getString("token"));
		} catch(JSONException e) {
			e.printStackTrace();
		}
		return jsonUser;
	}

	private JSONObject getLineBaseUserData(LineLoginResult result) {
		JSONObject jsonUser = new JSONObject();
		LineProfile profile = result.getLineProfile();

		try {
			jsonUser.put("name", profile.getDisplayName());
			jsonUser.put("userId", profile.getUserId());
			jsonUser.put("image", profile.getPictureUrl());
			jsonUser.put("token", result.getLineCredential().getAccessToken().getAccessToken());
		} catch(JSONException e) {
			e.printStackTrace();
		}
		return jsonUser;
	}

	private JSONObject getFacebookBaseUserData(LoginResult result) {
		Profile profile = Profile.getCurrentProfile();
		Uri imageUri = Uri.parse(profile.getProfilePictureUri(320, 320).toString());

		JSONObject jsonUser = new JSONObject();
		try {
			jsonUser.put("name", profile.getName() );
			jsonUser.put("first_name", profile.getFirstName() );
			jsonUser.put("last_name", profile.getLastName() );
			jsonUser.put("token", result.getAccessToken().getToken());
			jsonUser.put("userId", result.getAccessToken().getUserId());
			jsonUser.put("image", imageUri.toString());

		} catch(JSONException e) {
			e.printStackTrace();
		}

		return jsonUser;
	}

	private JSONObject TweetObjectToJSON(Tweet tweet) {
		Gson gson = new Gson();
		String jsonString = gson.toJson(tweet);

		JSONObject jsonTweet = new JSONObject();
		try {
			jsonTweet = new JSONObject(jsonString);
		} catch (JSONException e) {
			e.printStackTrace();
		}

		return jsonTweet;
	}

	private void handleTwitterLoginResult(int requestCode, int resultCode, Intent intent) {
		TwitterLoginButton twitterLoginButton = new TwitterLoginButton(cordova.getActivity());
		twitterLoginButton.onActivityResult(requestCode, resultCode, intent);
	}

}