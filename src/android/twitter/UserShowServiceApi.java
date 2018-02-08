
package com.singlesignon;

import com.twitter.sdk.android.core.*;
import com.twitter.sdk.android.core.models.User;

import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Query;

public class UserShowServiceApi extends TwitterApiClient {
    public UserShowServiceApi(TwitterSession session) {
        super(session);
    }

    public UserShowService getCustomService() {
        return getService(UserShowService.class);
    }
}

interface UserShowService {
    @GET("/1.1/users/show.json")
    Call<User> show(@Query("user_id") long userId,
                    @Query("include_entities") boolean includeEntities);
}