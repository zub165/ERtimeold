package com.easytechnologiez.ERTime;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ProgressBar;
import android.widget.Toast;

public class WebActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_web);
        WebView webView = (WebView) findViewById(R.id.webView);
        ProgressBar bar = (ProgressBar) findViewById(R.id.progressBar);
        String url = getIntent().getExtras().getString("url");
        webView.getSettings().setAllowContentAccess(true);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setGeolocationEnabled(true);
        webView.getSettings().setSupportZoom(true);
        if (url != null) {
            webView.loadUrl(url);
        }else{
            Toast.makeText(this, "URL not found" , Toast.LENGTH_SHORT).show();
        }
        webView.setWebViewClient(new myWebClient(bar));

    }

    class myWebClient extends WebViewClient
    {
        ProgressBar progressBar;
        myWebClient(ProgressBar bar){
            progressBar = bar;
        }
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            view.loadUrl(url);
            return true;
        }

        @Override
        public void onPageCommitVisible(WebView view, String url) {
            super.onPageCommitVisible(view, url);
            if (progressBar != null && progressBar.isShown())
            {
                progressBar.setVisibility(View.GONE);
            }
        }

        @Override
        public void onPageFinished(WebView view, String url) {
            // TODO Auto-generated method stub
            super.onPageFinished(view, url);
            if (progressBar != null && progressBar.isShown())
            {
                progressBar.setVisibility(View.GONE);
            }
        }
    }
}
