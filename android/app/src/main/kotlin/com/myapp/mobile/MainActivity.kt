package com.myapp.mobile

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.myapp.mobile/security"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable privacy screen protection by default
        // This prevents screenshots and screen recording
        enablePrivacyProtection()
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enablePrivacyProtection" -> {
                    enablePrivacyProtection()
                    result.success(true)
                }
                "disablePrivacyProtection" -> {
                    disablePrivacyProtection()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    /**
     * Enable privacy protection
     * Prevents screenshots, screen recording, and content visibility in app switcher
     */
    private fun enablePrivacyProtection() {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
    
    /**
     * Disable privacy protection
     * Allows screenshots and screen recording (use with caution)
     */
    private fun disablePrivacyProtection() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
