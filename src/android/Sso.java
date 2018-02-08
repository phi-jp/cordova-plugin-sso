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

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CallbackContext;

import android.util.Log;
import jdk.nashorn.api.scripting.JSObject;
import jdk.nashorn.internal.runtime.JSONListAdapter;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import retrofit2.Call;

import com.google.gson.Gson;

public class Sso extends CordovaPlugin {

	private static final String LOG_TAG = "Twitter Connect";
	private String action;
	private CallbackContext callbackContext;

	public void initialize(CordovaInterface cordova, CordovaWebView webView) {
		TwitterConfig config = new TwitterConfig.Builder(cordova.getActivity().getApplicationContext())
    		.twitterAuthConfig(new TwitterAuthConfig(getTwitterKey(), getTwitterSecret()))
    		.build();
		Twitter.initialize(config);


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
	public boolean execute(final String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
		this.action = action;
		final Activity activity = this.cordova.getActivity();
		final Context context = activity.getApplicationContext();
		cordova.setActivityResultCallback(this);

		if (action.equals("loginWithTwitter")) {
			loginWithTwitter(activity, callbackContext);
			return true;
		}
		else if (action.equals("loginWithLine")) {
			this.callbackContext = callbackContext;
			loginWithLine(activity, callbackContext);
			return true;
		}
		return false;
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

	private void handleTwitterLoginResult(int requestCode, int resultCode, Intent intent) {
		TwitterLoginButton twitterLoginButton = new TwitterLoginButton(cordova.getActivity());
		twitterLoginButton.onActivityResult(requestCode, resultCode, intent);
	}

	public void onActivityResult(int requestCode, int resultCode, Intent intent) {
		super.onActivityResult(requestCode, resultCode, intent);
		if (action.equals("loginWithTwitter")) {
			handleTwitterLoginResult(requestCode, resultCode, intent);
		}
		else if (action.equals("loginWithLine")) {
			LineLoginResult result = LineLoginApi.getLoginResultFromIntent(intent);
			this.callbackContext.success(getLineBaseUserData(result));
		}

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

}