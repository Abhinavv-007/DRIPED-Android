package com.abhnv.driped

import android.content.Context
import android.util.Log
import java.io.File

class LocalMailExtractor(private val context: Context) : AutoCloseable {
    private val modelNames = listOf(
        "local_mail_extractor.litertlm",
        "functiongemma_270m.litertlm",
        "mobile_actions_q8_ekv1024.litertlm",
        "mobile-actions_q8_ekv1024.litertlm"
    )
    private val lock = Any()
    private var engine: Any? = null
    private var loadedModelPath: String? = null

    fun isAvailable(): Boolean {
        if (!isLiteRtLmPresent()) return false
        return findModelFile() != null || findBundledAssetName() != null
    }

    fun extract(input: Map<String, Any?>): String {
        val modelPath = ensureModelFile()
            ?: throw IllegalStateException("Offline AI model file was not found on this device.")
        val prompt = buildPrompt(input)
        val response = runInference(modelPath.absolutePath, prompt)
        return extractJson(response)
    }

    private fun runInference(modelPath: String, prompt: String): String {
        val localEngine = getEngine(modelPath)
        val conversation = createConversation(localEngine)
        try {
            val message = conversation.javaClass
                .getMethod("sendMessage", String::class.java, Map::class.java)
                .invoke(conversation, prompt, emptyMap<String, Any>())
            return messageToText(message)
        } finally {
            (conversation as? AutoCloseable)?.close()
        }
    }

    private fun getEngine(modelPath: String): Any {
        synchronized(lock) {
            val existing = engine
            if (existing != null && loadedModelPath == modelPath) return existing

            (existing as? AutoCloseable)?.close()
            val cacheDir = File(context.cacheDir, "litertlm").apply { mkdirs() }
            val backend = newInstance("com.google.ai.edge.litertlm.Backend\$CPU")
            val backendClass = Class.forName("com.google.ai.edge.litertlm.Backend")
            val engineConfigClass = Class.forName("com.google.ai.edge.litertlm.EngineConfig")
            val engineConfig = engineConfigClass
                .getConstructor(
                    String::class.java,
                    backendClass,
                    backendClass,
                    backendClass,
                    Integer::class.java,
                    Integer::class.java,
                    String::class.java,
                )
                .newInstance(
                    modelPath,
                    backend,
                    null,
                    null,
                    Integer.valueOf(1024),
                    null,
                    cacheDir.absolutePath,
                )
            val engineClass = Class.forName("com.google.ai.edge.litertlm.Engine")
            val nextEngine = engineClass.getConstructor(engineConfigClass)
                .newInstance(engineConfig)
            engineClass.getMethod("initialize").invoke(nextEngine)
            engine = nextEngine
            loadedModelPath = modelPath
            return nextEngine
        }
    }

    private fun createConversation(localEngine: Any): Any {
        val configClass = Class.forName("com.google.ai.edge.litertlm.ConversationConfig")
        val config = configClass.getConstructor().newInstance()
        return localEngine.javaClass.getMethod("createConversation", configClass)
            .invoke(localEngine, config)
    }

    private fun messageToText(message: Any?): String {
        if (message == null) return ""
        val contents = message.javaClass.getMethod("getContents").invoke(message)
        val contentList = contents.javaClass.getMethod("getContents").invoke(contents) as? List<*>
            ?: return message.toString()
        val parts = contentList.mapNotNull { content ->
            if (content == null) return@mapNotNull null
            val getText = content.javaClass.methods.firstOrNull { it.name == "getText" }
            getText?.invoke(content)?.toString()
        }
        return parts.joinToString("\n").ifBlank { message.toString() }
    }

    private fun ensureModelFile(): File? {
        findModelFile()?.let { return it }

        val assetName = findBundledAssetName() ?: return null
        val outputName = if (assetName.substringAfterLast('/').isNotBlank()) {
            assetName.substringAfterLast('/')
        } else {
            "local_mail_extractor.litertlm"
        }
        val modelsDir = File(context.filesDir, "models").apply { mkdirs() }
        val target = File(modelsDir, outputName)

        return try {
            context.assets.open(assetName).use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            }
            target.takeIf { it.length() > 0L }
        } catch (error: Throwable) {
            Log.w(TAG, "Failed to copy bundled local AI model", error)
            null
        }
    }

    private fun findModelFile(): File? {
        val modelsDir = File(context.filesDir, "models")
        for (name in modelNames) {
            val file = File(modelsDir, name)
            if (file.exists() && file.length() > 0L) return file
        }
        return null
    }

    private fun findBundledAssetName(): String? {
        return try {
            val listed = context.assets.list("models")?.toSet().orEmpty()
            modelNames.firstOrNull { listed.contains(it) }?.let { "models/$it" }
                ?: modelNames.firstOrNull { assetExists(it) }
        } catch (_: Throwable) {
            null
        }
    }

    private fun assetExists(assetName: String): Boolean {
        return try {
            context.assets.open(assetName).close()
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun buildPrompt(input: Map<String, Any?>): String {
        val from = safeField(input["from"], 320)
        val subject = safeField(input["subject"], 320)
        val date = safeField(input["date"], 80)
        val snippet = safeField(input["snippet"], 600)
        val body = safeField(input["body"], 8000)

        return """
            You are a private on-device parser for subscription billing emails.
            Extract recurring subscription billing data from this one email.

            Return JSON only. Do not explain.
            Use null when a value is not explicitly present.
            Do not guess amount, date, billing cycle, service name, or payment method.
            The service name must appear in the email sender, subject, snippet, or body.
            Never invent popular subscriptions that are not named in the email.
            Do not use payment processors, banks, cards, app stores, or generic words as the service name.
            Set is_recurring_subscription to false if the email does not contain clear recurring billing, renewal, membership, subscription, or trial evidence.
            Only set is_recurring_subscription to true when the email contains:
            1. the actual service/app/product name,
            2. a recurring subscription or membership signal,
            3. either a billed amount, a trial end date, or a next renewal/billing date.
            Evidence values must be short exact phrases copied from the email.
            If any required evidence is missing, return false with null fields.
            Reject newsletters, marketing emails, one-time purchases, refunds, failed payments, delivery emails, and login/security emails.

            JSON shape:
            {
              "is_recurring_subscription": boolean,
              "confidence": number,
              "service_name": string|null,
              "amount": number|null,
              "currency": "INR"|"USD"|"EUR"|"GBP"|null,
              "billing_cycle": "weekly"|"monthly"|"quarterly"|"yearly"|"lifetime"|"unknown",
              "renewal_date": "YYYY-MM-DD"|null,
              "payment_method_label": string|null,
              "status": "active"|"trial"|"cancelled"|"refund"|"failed_payment"|"one_time"|"unknown",
              "evidence": {
                "service": string|null,
                "amount": string|null,
                "cycle": string|null,
                "renewal_date": string|null,
                "payment_method": string|null
              }
            }

            Email:
            From: $from
            Subject: $subject
            Date: $date
            Snippet: $snippet
            Body:
            $body
        """.trimIndent()
    }

    private fun safeField(value: Any?, maxChars: Int): String {
        val raw = value?.toString().orEmpty()
            .replace(Regex("[\\u0000-\\u001F\\u007F]+"), " ")
            .replace(Regex("\\s+"), " ")
            .trim()
        return if (raw.length <= maxChars) raw else raw.substring(0, maxChars)
    }

    private fun extractJson(raw: String): String {
        val start = raw.indexOf('{')
        val end = raw.lastIndexOf('}')
        if (start >= 0 && end > start) return raw.substring(start, end + 1)
        return raw.trim()
    }

    private fun newInstance(className: String): Any {
        return Class.forName(className).getConstructor().newInstance()
    }

    private fun isLiteRtLmPresent(): Boolean {
        return try {
            Class.forName("com.google.ai.edge.litertlm.Engine")
            true
        } catch (_: Throwable) {
            false
        }
    }

    override fun close() {
        synchronized(lock) {
            (engine as? AutoCloseable)?.close()
            engine = null
            loadedModelPath = null
        }
    }

    companion object {
        private const val TAG = "LocalMailExtractor"
    }
}
