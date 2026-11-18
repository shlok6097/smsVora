package com.example.smsvora

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

/**
 * Standard Android BroadcastReceiver for incoming SMS (SMS_DELIVER_ACTION).
 * Required by Android to register smsVora as the Default SMS Application.
 */
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_DELIVER_ACTION) {
            // Incoming SMS delivered by Android Telephony
        }
    }
}
