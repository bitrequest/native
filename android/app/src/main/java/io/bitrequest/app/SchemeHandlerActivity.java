package io.bitrequest.app;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Base64;
import com.google.firebase.analytics.FirebaseAnalytics;

public class SchemeHandlerActivity extends Activity {

    private FirebaseAnalytics analytics;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        analytics = FirebaseAnalytics.getInstance(this);
        handleSchemeIntent(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        handleSchemeIntent(intent);
    }

    private void handleSchemeIntent(Intent intent) {
        Uri uri = intent.getData();
        if (uri == null) {
            finish();
            return;
        }

        // Log the scheme type
        Bundle params = new Bundle();
        params.putString("scheme", uri.getScheme());
        analytics.logEvent("scheme_intent", params);

        String encoded = Base64.encodeToString(
                uri.toString().getBytes(),
                Base64.URL_SAFE | Base64.NO_WRAP
        );

        String targetUrl = "https://bitrequest.github.io?p=home&scheme=" + encoded;

        // Open in TWA (not Custom Tabs)
        Intent twaIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(targetUrl));
        twaIntent.setPackage(getPackageName());
        startActivity(twaIntent);

        finish();
    }
}