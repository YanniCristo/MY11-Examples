package com.stefanofancello.smashcrop

import com.google.android.gms.auth.blockstore.Blockstore
import com.google.android.gms.auth.blockstore.RetrieveBytesRequest
import com.google.android.gms.auth.blockstore.StoreBytesData
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Contatore delle macerie in Google Block Store: niente login, torna da
        // solo reinstallando l'app o configurando un telefono nuovo.
        val client = Blockstore.getClient(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smashcrop/cloud")
            .setMethodCallHandler { call, result ->
                val key = call.argument<String>("key")
                if (key == null) {
                    result.success(null)
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "read" -> {
                        val request = RetrieveBytesRequest.Builder().setKeys(listOf(key)).build()
                        client.retrieveBytes(request)
                            .addOnSuccessListener { r ->
                                val bytes = r.blockstoreDataMap[key]?.bytes
                                result.success(bytes?.toString(Charsets.UTF_8))
                            }
                            .addOnFailureListener { result.success(null) }
                    }
                    "write" -> {
                        val value = call.argument<String>("value") ?: ""
                        client.isEndToEndEncryptionAvailable
                            .continueWithTask { e2e ->
                                val data = StoreBytesData.Builder()
                                    .setKey(key)
                                    .setBytes(value.toByteArray(Charsets.UTF_8))
                                    // copia anche nel backup Google solo se cifrata
                                    .setShouldBackupToCloud(e2e.isSuccessful && e2e.result == true)
                                    .build()
                                client.storeBytes(data)
                            }
                            .addOnCompleteListener { result.success(null) }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
