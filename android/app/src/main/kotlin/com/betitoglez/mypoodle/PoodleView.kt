package com.betitoglez.mypoodle

import android.content.Context
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.json.JSONArray
import org.json.JSONObject

class PoodleViewFactory(private val messenger: BinaryMessenger) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        PoodleView(context, MethodChannel(messenger, "my_poodle/3d/$viewId"))
}

private class PoodleView(context: Context, private val channel: MethodChannel) : PlatformView {
    private val web = WebView(context)
    private var configuration: String? = null
    private var ready = false
    private var disposed = false

    init {
        web.setBackgroundColor(android.graphics.Color.TRANSPARENT)
        web.settings.javaScriptEnabled = true
        web.settings.allowFileAccess = false
        web.settings.allowContentAccess = false
        web.settings.setSupportZoom(false)
        web.addJavascriptInterface(Bridge(), "PoodleHost")
        web.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest) = true

            override fun shouldInterceptRequest(
                view: WebView, request: WebResourceRequest
            ): WebResourceResponse {
                val url = request.url
                val path = url.path.orEmpty().removePrefix("/")
                if (url.scheme == "https" && url.host == "appassets.androidplatform.net" &&
                    path.matches(Regex("[a-zA-Z0-9_./-]+")) && !path.contains("..")) {
                    val type = when (path.substringAfterLast('.')) {
                        "html" -> "text/html"
                        "js" -> "text/javascript"
                        "glb" -> "model/gltf-binary"
                        else -> "application/octet-stream"
                    }
                    try {
                        return WebResourceResponse(type, null,
                            context.assets.open("flutter_assets/assets/wardrobe_live/$path"))
                    } catch (_: java.io.IOException) { }
                }
                return WebResourceResponse("text/plain", "UTF-8", 404, "Not Found", emptyMap(),
                    "".byteInputStream())
            }
        }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "configure" -> {
                    configuration = JSONObject(call.arguments as Map<*, *>).toString()
                    execute("configure($configuration)")
                }
                "rotate" -> {
                    val delta = (call.arguments as Number).toDouble()
                    if (delta.isFinite()) execute("rotate($delta)")
                }
                "pet" -> execute("pet()")
                "petAt" -> {
                    val point = (call.arguments as List<*>).map { (it as Number).toDouble() }
                    if (ready && !disposed && point.size == 2 &&
                        point.all { it.isFinite() && it in 0.0..1.0 }) {
                        web.evaluateJavascript("window.poodle.petAt(${JSONArray(point)})") {
                            result.success(it.toIntOrNull() ?: 0)
                        }
                    } else {
                        result.success(0)
                    }
                    return@setMethodCallHandler
                }
                "front" -> execute("front()")
                "feed" -> execute("feed(${JSONArray(call.arguments as List<*>)})")
                "bath" -> execute("bath(${JSONArray(call.arguments as List<*>)})")
                "vet" -> execute("vet(${JSONArray(call.arguments as List<*>)})")
                "groom" -> execute("groom(${JSONArray(call.arguments as List<*>)})")
                "sleep" -> execute("sleep(${JSONArray(call.arguments as List<*>)})")
                "walk" -> execute("walk(${JSONArray(call.arguments as List<*>)})")
                "orchard" -> execute("orchard(${JSONArray(call.arguments as List<*>)})")
                "frisbee" -> execute("frisbee(${JSONArray(call.arguments as List<*>)})")
                else -> {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
            }
            result.success(null)
        }
        web.loadUrl("https://appassets.androidplatform.net/index.html")
    }

    private fun execute(command: String) {
        if (ready && !disposed) web.evaluateJavascript("window.poodle.$command", null)
    }

    private inner class Bridge {
        @JavascriptInterface
        fun ready() {
            web.post {
                if (!disposed) {
                    ready = true
                    configuration?.let { execute("configure($it)") }
                }
            }
        }
        @JavascriptInterface
        fun rendered() {
            web.post {
                if (!disposed) channel.invokeMethod("ready", null)
            }
        }
        @JavascriptInterface
        fun failed() {
            web.post {
                if (!disposed) channel.invokeMethod("failed", null)
            }
        }

        @JavascriptInterface
        fun bowlBounds(left: Double, top: Double, right: Double, bottom: Double) {
            val bounds = listOf(left, top, right, bottom)
            if (bounds.any { !it.isFinite() }) return
            web.post {
                if (!disposed) channel.invokeMethod("bowlBounds", bounds)
            }
        }

        @JavascriptInterface
        fun bathTargets(json: String) = sendTargets("bathTargets", json, 16)

        @JavascriptInterface
        fun vetTargets(json: String) = sendTargets("vetTargets", json, 6)

        @JavascriptInterface
        fun groomTargets(json: String) = sendTargets("groomTargets", json, 6)

        @JavascriptInterface
        fun sleepBounds(json: String) = sendTargets("sleepBounds", json, 4)

        private fun sendTargets(method: String, json: String, coordinateCount: Int) {
            val payload = JSONArray(json)
            if (payload.length() != coordinateCount) return
            val targetCoordinates = List(coordinateCount) { payload.getDouble(it) }
            if (targetCoordinates.any { !it.isFinite() }) return
            web.post {
                if (!disposed) channel.invokeMethod(method, targetCoordinates)
            }
        }
    }

    override fun getView(): View = web

    override fun dispose() {
        disposed = true
        channel.setMethodCallHandler(null)
        web.removeJavascriptInterface("PoodleHost")
        web.stopLoading()
        web.destroy()
    }
}
