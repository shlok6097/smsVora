package com.example.smsvora

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

/**
 * Standard Android BroadcastReceiver for WAP PUSH / MMS (WAP_PUSH_DELIVER_ACTION).
 * Required by Android to register smsVora as the Default SMS Application.
 */
class MmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.WAP_PUSH_DELIVER_ACTION) {
            // Incoming MMS / WAP push message
        }
    }
}
