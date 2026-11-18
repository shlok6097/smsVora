package com.example.smsvora

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.provider.Telephony
import android.telephony.SmsManager

/**
 * Service to handle RESPOND_VIA_MESSAGE intents when SMS needs to be sent headlessly
 * or during automated device verification (such as UPI registration binding).
 */
class HeadlessSmsSendService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == Telephony.Sms.Intents.RESPOND_VIA_MESSAGE_ACTION) {
            val extras = intent.extras
            if (extras != null) {
                val message = extras.getString(Intent.EXTRA_TEXT)
                val recipientUri = intent.data
                val recipient = recipientUri?.schemeSpecificPart
                if (!message.isNullOrEmpty() && !recipient.isNullOrEmpty()) {
                    try {
                        val smsManager = SmsManager.getDefault()
                        smsManager.sendTextMessage(recipient, null, message, null, null)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        }
        stopSelf(startId)
        return START_NOT_STICKY
    }
}
