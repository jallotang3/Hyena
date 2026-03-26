package com.hyena.hyena

import com.HyenaCore.core.mobile.Mobile
import com.HyenaCore.core.mobile.MobileSetupOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * HyenaCore Android MethodChannel 插件
 * 通过 gomobile bind 生成的 AAR 调用 HyenaCore（上游 mobile 包）
 *
 * AAR 包名: com.HyenaCore.core
 * 主要类:   com.HyenaCore.core.mobile.Mobile
 *           com.HyenaCore.core.mobile.MobileSetupOptions
 */
class HyenaCorePlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.hyena/core")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "setup" -> handleSetup(call, result)
                "start" -> handleStart(call, result)
                "stop"  -> handleStop(result)
                "pause" -> { Mobile.pause(); result.success(null) }
                "wake"  -> { Mobile.wake(); result.success(null) }
                else    -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("HYENA_CORE_ERROR", e.message, null)
        }
    }

    private fun handleSetup(call: MethodCall, result: Result) {
        val opt = MobileSetupOptions()
        opt.basePath   = call.argument<String>("basePath")   ?: ""
        opt.workingDir = call.argument<String>("workingDir") ?: ""
        opt.tempDir    = call.argument<String>("tempDir")    ?: ""
        opt.listen     = call.argument<String>("listen")     ?: ""
        opt.secret     = call.argument<String>("secret")     ?: ""
        opt.mode       = (call.argument<Int>("mode") ?: 0).toLong()
        opt.debug      = call.argument<Boolean>("debug") ?: false
        opt.fixAndroidStack = true

        Mobile.setup(opt, null)
        result.success(null)
    }

    private fun handleStart(call: MethodCall, result: Result) {
        val configPath    = call.argument<String>("configPath")    ?: ""
        val configContent = call.argument<String>("configContent") ?: ""
        Mobile.start(configPath, configContent)
        result.success(null)
    }

    private fun handleStop(result: Result) {
        Mobile.stop()
        result.success(null)
    }
}
