package com.myallergybuddy.app

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Add a 5-second delay before showing the Flutter UI
        Handler(Looper.getMainLooper()).postDelayed({
            // The delay is handled by the Flutter engine
        }, 5000) // 5000 milliseconds = 5 seconds
    }
} 