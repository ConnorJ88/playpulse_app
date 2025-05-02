package com.playpulse.app

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.content.Context
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform

class PythonBridgePlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var python: Python? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.playpulse/python")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }
    
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initializePython" -> {
                try {
                    if (!Python.isStarted()) {
                        Python.start(AndroidPlatform(context))
                    }
                    python = Python.getInstance()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("PYTHON_INIT_ERROR", "Failed to initialize Python: ${e.message}", null)
                }
            }
            "executePython" -> {
                try {
                    if (python == null) {
                        if (!Python.isStarted()) {
                            Python.start(AndroidPlatform(context))
                        }
                        python = Python.getInstance()
                    }
                    
                    val moduleName = call.argument<String>("module") ?: throw Exception("Module name is required")
                    val functionName = call.argument<String>("function") ?: throw Exception("Function name is required")
                    val args = call.argument<List<Any>>("args") ?: listOf<Any>()
                    
                    val pyModule = python!!.getModule(moduleName)
                    val pyFunction = pyModule.callAttr(functionName, *args.toTypedArray())
                    
                    result.success(pyFunction.toString())
                } catch (e: Exception) {
                    result.error("PYTHON_EXEC_ERROR", "Failed to execute Python code: ${e.message}", null)
                }
            }
            else -> result.notImplemented()
        }
    }
}