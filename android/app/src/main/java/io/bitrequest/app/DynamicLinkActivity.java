package io.bitrequest.app;

import android.app.Activity;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.util.StatsLog;

import androidx.annotation.NonNull;
import androidx.browser.customtabs.CustomTabsIntent;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.dynamiclinks.FirebaseDynamicLinks;
import com.google.firebase.dynamiclinks.PendingDynamicLinkData;
import com.google.firebase.analytics.FirebaseAnalytics;

public class DynamicLinkActivity extends Activity {
    private FirebaseAnalytics mFirebaseAnalytics;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mFirebaseAnalytics = FirebaseAnalytics.getInstance(this);
        checkForDynamicLinks();
    }

    private void checkForDynamicLinks() {
        FirebaseDynamicLinks.getInstance().getDynamicLink(getIntent()).addOnSuccessListener(
                this, new OnSuccessListener<PendingDynamicLinkData>() {
                    @Override
                    public void onSuccess(PendingDynamicLinkData pendingDynamicLinkData) {
                        Log.w("DynamicLinkActivity", "we have a dynamic link!");
                        // Get deepLink from result (may be null if no link mis found).
                        String CurrentPage = "Android_URL";
                        Uri deepLink = null;
                        if (pendingDynamicLinkData != null) {
                            deepLink = pendingDynamicLinkData.getLink();
                        }
                        // Handle the deep link by extracting the url
                        if (deepLink != null) {
                            Log.i("DynamicLinkActivity", "Here's the deeplink URL:\n" + deepLink.toString());
                            CurrentPage = deepLink.toString();
                            CustomTabsIntent.Builder builder = new CustomTabsIntent.Builder();
                            CustomTabsIntent customTabsIntent = builder.build();
                            customTabsIntent.launchUrl(DynamicLinkActivity.this, Uri.parse(CurrentPage));
                        }
                        Bundle params = new Bundle();
                        params.putString("br_url", CurrentPage);
                        mFirebaseAnalytics.logEvent("custom_app_open", params);
                    }
                }).addOnFailureListener(this, new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
                Log.e("DynamicLinkActivity", "Oops, we couldn't retrieve dynamic link data");
            }
        });
    }

    @Override
    protected void onStart() {
        super.onStart();
        checkForDynamicLinks();
    }

    @Override
    protected void onResume() {
        super.onResume();
        checkForDynamicLinks();
    }

}