package com.example.senior_checkin_app

import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.seniorcare/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendSMS") {
                val phone = call.argument<String>("phone")
                val msg = call.argument<String>("msg")
                
                if (phone != null && msg != null) {
                    try {
                        val smsManager: SmsManager = SmsManager.getDefault()
                        
                        // Send multipart SMS for long messages (e.g. Google Maps links + text)
                        val parts = smsManager.divideMessage(msg)
                        if (parts.size > 1) {
                            smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
                        } else {
                            smsManager.sendTextMessage(phone, null, msg, null, null)
                        }
                        
                        result.success("SMS Sent Natively")
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "Phone and Message cannot be null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
