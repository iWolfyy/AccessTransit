package com.accesstransit.access_transit

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Notification
import android.os.Build
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    private val alias = "access_transit_report_outbox_v2"
    private val maxBytes = 16 * 1024 * 1024

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
        }.generateKey()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "access_transit/notification_channels").setMethodCallHandler { call, result ->
            if (call.method != "create") { result.notImplemented() }
            else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val channel = NotificationChannel("assistance_requests",
                        call.argument<String>("name") ?: "Boarding assistance",
                        NotificationManager.IMPORTANCE_HIGH)
                    channel.description = call.argument<String>("description") ?: "Assistance requests"
                    channel.lockscreenVisibility = Notification.VISIBILITY_PRIVATE
                    getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
                }
                result.success(null)
            }
        }
        val queue = flutterEngine.dartExecutor.binaryMessenger.makeBackgroundTaskQueue()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "access_transit/report_outbox", io.flutter.plugin.common.StandardMethodCodec.INSTANCE, queue)
            .setMethodCallHandler { call, result ->
                val sample = call.method == "readSample" || call.method == "writeSample"
                val file = AtomicFile(File(noBackupFilesDir,
                    if (sample) "sample-report-outbox-v2.enc" else "report-outbox-v2.enc"))
                try {
                    when (call.method) {
                        "read", "readSample" -> {
                            if (!file.baseFile.exists()) {
                                result.success(null)
                            } else {
                                require(file.baseFile.length() <= maxBytes + 128)
                                val payload = file.readFully()
                                require(payload.size >= 28)
                                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                                cipher.init(Cipher.DECRYPT_MODE, key(),
                                    GCMParameterSpec(128, payload.copyOfRange(0, 12)))
                                result.success(String(cipher.doFinal(payload.copyOfRange(12, payload.size)), Charsets.UTF_8))
                            }
                        }
                        "write", "writeSample" -> {
                            val bytes = (call.arguments as String).toByteArray(Charsets.UTF_8)
                            require(bytes.size <= maxBytes)
                            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                            cipher.init(Cipher.ENCRYPT_MODE, key())
                            val encrypted = cipher.iv + cipher.doFinal(bytes)
                            val output = file.startWrite()
                            try {
                                output.write(encrypted)
                                file.finishWrite(output)
                            } catch (error: Exception) {
                                file.failWrite(output)
                                throw error
                            }
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("private-storage", "Could not access private report drafts.", null)
                }
            }
    }
}
