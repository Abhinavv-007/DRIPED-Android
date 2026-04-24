package com.abhnv.driped

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class LocalMailAiPlugin private constructor(context: Context) : MethodChannel.MethodCallHandler {
    private val appContext = context.applicationContext
    private val extractor = LocalMailExtractor(appContext)
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> executor.execute {
                postSuccess(result, extractor.isAvailable())
            }
            "extractSubscription" -> executor.execute {
                try {
                    val args = call.arguments as? Map<*, *>
                        ?: throw IllegalArgumentException("Expected map arguments")
                    val normalized = args.entries.associate { entry ->
                        entry.key.toString() to entry.value
                    }
                    postSuccess(result, extractor.extract(normalized))
                } catch (error: IllegalStateException) {
                    postError(result, "MODEL_UNAVAILABLE", error.message ?: "Offline model unavailable")
                } catch (error: Throwable) {
                    postError(result, "LOCAL_AI_FAILED", error.message ?: error.toString())
                }
            }
            "release" -> executor.execute {
                extractor.close()
                postSuccess(result, true)
            }
            else -> result.notImplemented()
        }
    }

    private fun postSuccess(result: MethodChannel.Result, value: Any?) {
        mainHandler.post { result.success(value) }
    }

    private fun postError(result: MethodChannel.Result, code: String, message: String) {
        mainHandler.post { result.error(code, message, null) }
    }

    companion object {
        private const val CHANNEL = "driped/local_mail_ai"

        fun register(flutterEngine: FlutterEngine, context: Context) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler(LocalMailAiPlugin(context))
        }
    }
}
