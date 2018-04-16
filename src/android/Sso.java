package com.singlesignon;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInApi;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.linecorp.linesdk.LineApiResponseCode;
import com.linecorp.linesdk.LineProfile;
import com.linecorp.linesdk.api.LineApiClient;
import com.linecorp.linesdk.api.LineApiClientBuilder;
import com.linecorp.linesdk.auth.LineLoginApi;
import com.linecorp.linesdk.auth.LineLoginResult;

import com.twitter.sdk.android.core.*;
import com.twitter.sdk.android.core.identity.TwitterAuthClient;
import com.twitter.sdk.android.core.identity.TwitterLoginButton;
import com.twitter.sdk.android.core.internal.TwitterApi;
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

import com.google.android.gms.auth.api.Auth;
import com.google.android.gms.auth.api.signin.GoogleSignInResult;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.common.api.Status;
import com.google.android.gms.common.api.Scope;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CallbackContext;

import jdk.nashorn.api.scripting.JSObject;
import jdk.nashorn.internal.runtime.JSONListAdapter;
import android.accounts.Account;
import android.accounts.AccountManager;
import android.accounts.AccountManagerFuture;
import android.accounts.AuthenticatorException;
import android.accounts.OperationCanceledException;
import android.app.Activity;

import android.content.Context;
import android.content.Intent;

import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;

import android.os.AsyncTask;
import android.os.Bundle;
import android.net.Uri;
import android.support.annotation.NonNull;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import retrofit2.Call;

import com.google.gson.Gson;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.MessageDigest;
import java.util.Arrays;


public class Sso extends CordovaPlugin {

	private static final String LOG_TAG = "Twitter Connect";
	private String action;
	private CallbackContext callbackContext;
	private CallbackManager fbCallbackManager;
	private LineApiClient lineApiClient;
	private GoogleSignInClient mGoogleSignInClient;

	private final static String FIELD_GOOGLE_ACCESS_TOKEN      = "accessToken";
	private final static String FIELD_GOOGLE_TOKEN_EXPIRES     = "expires";
	private final static String FIELD_GOOGLE_TOKEN_EXPIRES_IN  = "expires_in";
	private final static String VERIFY_GOOGLE_TOKEN_URL        = "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=";

	public static final int RC_GOOGLEPLUS = 77552;

	public static final int KAssumeStaleTokenSec = 60;

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
		else if (action.equals("loginWithGoogle")) {
			cordova.setActivityResultCallback(this);
			// for Google signin
			GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN).requestEmail().build();
			mGoogleSignInClient = GoogleSignIn.getClient(activity, gso);
			Intent loginIntent = mGoogleSignInClient.getSignInIntent();
			this.cordova.getActivity().startActivityForResult(loginIntent, RC_GOOGLEPLUS);
			return true;
		}
		else if (action.equals("logoutWithTwitter")) {
			cordova.setActivityResultCallback(this);
			logoutWithTwitter(activity, callbackContext);
			return true;
		}
		else if (action.equals("logoutWithLine")) {
			cordova.setActivityResultCallback(this);
			logoutWithLine(activity, callbackContext);
			return true;
		}
		else if (action.equals("logoutWithFacebook")) {
			cordova.setActivityResultCallback(this);
			logoutWithFacebook(activity, callbackContext);
			return true;
		}
		else if (action.equals(("logoutWithGoogle"))) {
			cordova.setActivityResultCallback(this);
			logoutWithGoogle(activity, callbackContext);
			return true;
		}
		else
		{
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
			if (result.isSuccess()) {
				callbackContext.success(getLineBaseUserData(result));
			}
			else {
				callbackContext.error("error");
			}
		}
		else if (action.equals("loginWithFacebook")) {
			fbCallbackManager.onActivityResult(requestCode, resultCode, intent);
		}
		else if (action.equals("loginWithGoogle")){
			if (intent == null) return;
			GoogleSignInResult result = Auth.GoogleSignInApi.getSignInResultFromIntent(intent);
			handleGoogleSignInResult(result);
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
		LineApiClientBuilder apiClientBuilder = new LineApiClientBuilder(context, getLineChannelId());
		lineApiClient = apiClientBuilder.build();
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
						callbackContext.error("User cancelled");
					}

					@Override
					public void onError(FacebookException error) {
						callbackContext.error("Failed login session");
					}
				});
			}
		});
	}

	private void logoutWithTwitter(final Activity activity, final CallbackContext callbackContext) {
		cordova.getThreadPool().execute(new Runnable() {
			@Override
			public void run() {
				TwitterCore twitterCore = TwitterCore.getInstance();
				long id = twitterCore.getSessionManager().getActiveSession().getId();
				twitterCore.getSessionManager().clearSession(id);
				callbackContext.success("logout");
			}
		});
	}

	private void logoutWithLine(final Activity activity, final CallbackContext callbackContext) {
		if (lineApiClient != null) {
			lineApiClient.logout();
			callbackContext.success("logout");
		}
		else {
			callbackContext.error("error");
		}

	}

	private void logoutWithFacebook(final Activity activity, final CallbackContext callbackContext) {
		if (fbHasAccessToken()) {
			LoginManager.getInstance().logOut();
			callbackContext.success("logout");
		} else {
			callbackContext.error("error");
		}
	}

	private void logoutWithGoogle(final Activity activity, final CallbackContext callbackContext) {
		if (mGoogleSignInClient == null) {
			callbackContext.error("Please use login or trySilentLogin before logging out");
			return;
		};

		mGoogleSignInClient.revokeAccess();

		mGoogleSignInClient.signOut().addOnCompleteListener(activity, new OnCompleteListener<Void>() {
			@Override
			public void onComplete(@NonNull Task<Void> task) {
				callbackContext.success("logout");
			}
		});


	}


	private void handleGoogleSignInResult(final GoogleSignInResult result) {
		if (mGoogleSignInClient == null) {
			callbackContext.error("GoogleApiClient was never initialized");
			return;
		}

		if (result == null) {
			callbackContext.error("result is null");
			return;
		}

		if (!result.isSuccess()) {
			String message;
			Integer statusCode = result.getStatus().getStatusCode();


			if (statusCode == 12501) {
				message = "user canceled";
			}
			else if (statusCode == 8) {
				message = "internal error has been occered";
			}
			else {
				message = "error has been occered" + statusCode;
			}
			
			callbackContext.error(message);
		}
		else {
			new AsyncTask<Void, Void, Void>() {
				@Override
				protected Void doInBackground(Void... params) {
					GoogleSignInAccount acct = result.getSignInAccount();
					JSONObject result = new JSONObject();
					try {
						JSONObject accessTokenBundle = getGoogleAuthToken(
								cordova.getActivity(), acct.getAccount(), true
						);
						result.put(FIELD_GOOGLE_ACCESS_TOKEN, accessTokenBundle.get(FIELD_GOOGLE_ACCESS_TOKEN));
						result.put(FIELD_GOOGLE_TOKEN_EXPIRES, accessTokenBundle.get(FIELD_GOOGLE_TOKEN_EXPIRES));
						result.put(FIELD_GOOGLE_TOKEN_EXPIRES_IN, accessTokenBundle.get(FIELD_GOOGLE_TOKEN_EXPIRES_IN));
						result.put("email", acct.getEmail());
						result.put("token", acct.getIdToken());
						result.put("serverAuthCode", acct.getServerAuthCode());
						result.put("userId", acct.getId());
						result.put("name", acct.getDisplayName());
						result.put("last_name", acct.getFamilyName());
						result.put("first_name", acct.getGivenName());
						result.put("image", acct.getPhotoUrl());
						callbackContext.success(result);
					} catch (Exception e) {
						callbackContext.error("Trouble obtaining result, error: " + e.getMessage());
					}
					return null;
				}
			}.execute();


		}

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


	private boolean fbHasAccessToken() {
		return AccessToken.getCurrentAccessToken() != null;
	}


	// for Google sign in
	private JSONObject getGoogleAuthToken(Activity activity, Account account, boolean retry) throws Exception {
		AccountManager manager = AccountManager.get(activity);
		AccountManagerFuture<Bundle> future = manager.getAuthToken(account, "oauth2:profile email", null, activity, null, null);
		Bundle bundle = future.getResult();
		String authToken = bundle.getString(AccountManager.KEY_AUTHTOKEN);
		try {
			return verifyToken(authToken);
		} catch (IOException e) {
			if (retry) {
				manager.invalidateAuthToken("com.google", authToken);
				return getGoogleAuthToken(activity, account, false);
			} else {
				throw e;
			}
		}
	}
	private JSONObject verifyToken(String authToken) throws IOException, JSONException {
		URL url = new URL(VERIFY_GOOGLE_TOKEN_URL+authToken);
		HttpURLConnection urlConnection = (HttpURLConnection) url.openConnection();
		urlConnection.setInstanceFollowRedirects(true);
		String stringResponse = fromStream(
				new BufferedInputStream(urlConnection.getInputStream())
		);
        /* expecting:
        {
            "issued_to": "608941808256-43vtfndets79kf5hac8ieujto8837660.apps.googleusercontent.com",
            "audience": "608941808256-43vtfndets79kf5hac8ieujto8837660.apps.googleusercontent.com",
            "user_id": "107046534809469736555",
            "scope": "https://www.googleapis.com/auth/userinfo.profile",
            "expires_in": 3595,
            "access_type": "offline"
        }*/

		Log.d("AuthenticatedBackend", "token: " + authToken + ", verification: " + stringResponse);
		JSONObject jsonResponse = new JSONObject(
				stringResponse
		);
		int expires_in = jsonResponse.getInt(FIELD_GOOGLE_TOKEN_EXPIRES_IN);
		if (expires_in < KAssumeStaleTokenSec) {
			throw new IOException("Auth token soon expiring.");
		}
		jsonResponse.put(FIELD_GOOGLE_ACCESS_TOKEN, authToken);
		jsonResponse.put(FIELD_GOOGLE_TOKEN_EXPIRES, expires_in + (System.currentTimeMillis()/1000));
		return jsonResponse;
	}
	public static String fromStream(InputStream is) throws IOException {
		BufferedReader reader = new BufferedReader(new InputStreamReader(is));
		StringBuilder sb = new StringBuilder();
		String line = null;
		while ((line = reader.readLine()) != null) {
			sb.append(line).append("\n");
		}
		reader.close();
		return sb.toString();
	}


}