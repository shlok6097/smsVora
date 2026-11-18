package com.example.smsvora

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "smsvora/telephony"
    private val REQ_CODE_DEFAULT_SMS = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDefaultSmsApp" -> {
                    val defaultSmsPackage = Telephony.Sms.getDefaultSmsPackage(this)
                    result.success(defaultSmsPackage == packageName)
                }
                "requestDefaultSmsApp" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val roleManager = getSystemService(Context.ROLE_SERVICE) as? RoleManager
                            if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_SMS)) {
                                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS)
                                startActivityForResult(intent, REQ_CODE_DEFAULT_SMS)
                                result.success(true)
                                return@setMethodCallHandler
                            }
                        }
                        val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
                        intent.putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, packageName)
                        startActivityForResult(intent, REQ_CODE_DEFAULT_SMS)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DEFAULT_SMS_ERROR", e.localizedMessage, null)
                    }
                }
                "sendSms" -> {
                    val phone = call.argument<String>("phone")
                    val message = call.argument<String>("message")
                    val subId = call.argument<Int>("subId") // For dual-SIM selection

                    if (phone.isNullOrEmpty() || message.isNullOrEmpty()) {
                        result.error("INVALID_ARGS", "Phone and message cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val smsManager = if (subId != null && subId != -1 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                            SmsManager.getSmsManagerForSubscriptionId(subId)
                        } else {
                            SmsManager.getDefault()
                        }
                        smsManager.sendTextMessage(phone, null, message, null, null)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SEND_SMS_FAILED", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
