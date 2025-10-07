package com.example.appmaker;

import android.os.Bundle;
import android.webkit.WebView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    WebView webView;
    @Override
    protected void onCreate(Bundle s) {
        super.onCreate(s);
        setContentView(android.R.layout.content);
        // Keep it minimal; actual UI in template's res/layout if present
    }
}
