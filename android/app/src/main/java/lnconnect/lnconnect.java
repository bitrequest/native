package lnconnect;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import androidx.browser.customtabs.CustomTabsIntent;
import java.util.Base64;

public class lnconnect extends Activity {
    protected void onCreate() {
        checkForSchemes();
    }

    private void checkForSchemes() {
        Uri schemuri = null;
        Intent getintent = getIntent();
        schemuri = getintent.getData();
        if (schemuri != null) {
            String parseduri = schemuri.toString();
            byte[] bytes = null;
            bytes = parseduri.getBytes();
            if (bytes != null) {
                String encodedString = null;
                encodedString = new String(Base64.getEncoder().encode(bytes));
                if (encodedString != null) {
                    StringBuilder CurrentPage = null;
                    CurrentPage = new StringBuilder();
                    if (CurrentPage != null) {
                        CurrentPage.append("https://bitrequest.github.io?p=home&scheme=").append(encodedString);
                        CurrentPage.toString();
                        String Current_page = null;
                        Current_page = String.valueOf(CurrentPage);
                        if (Current_page != null) {
                            CustomTabsIntent.Builder builder = new CustomTabsIntent.Builder();
                            CustomTabsIntent customTabsIntent = builder.build();
                            customTabsIntent.launchUrl(lnconnect.this, Uri.parse(Current_page));
                        }
                    }
                }
            }
        }
    }

    @Override
    protected void onStart() {
        super.onStart();
        checkForSchemes();
    }

    @Override
    protected void onResume() {
        super.onResume();
        checkForSchemes();
    }

}