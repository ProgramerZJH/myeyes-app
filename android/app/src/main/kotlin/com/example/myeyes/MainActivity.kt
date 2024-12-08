package com.example.myeyes
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.wifi.WifiManager
import android.content.Context
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.net.Uri
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.content.ComponentName

class MainActivity: FlutterActivity() {
    private lateinit var wifiManager: WifiManager
    private val PERMISSION_REQUEST_CODE = 123
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        
        // 热点设置的 MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.myeyes/hotspot").setMethodCallHandler { call, result ->
            if (call.method == "openHotspotSettings") {
                try {
                    // 打开移动网络设置页面
                    val intent = Intent()
                    intent.component = ComponentName(
                        "com.android.settings",
                        "com.android.settings.RadioInfo"
                    )
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success("已打开移动网络设置")
                } catch (e: Exception) {
                    try {
                        // 备选方案：使用系统网络设置
                        val alternativeIntent = Intent(Settings.ACTION_NETWORK_OPERATOR_SETTINGS)
                        alternativeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(alternativeIntent)
                        result.success("已打开移动网络设置")
                    } catch (e2: Exception) {
                        Log.e("Hotspot", "打开移动网络设置失败: ${e2.message}")
                        result.error("ERROR", "无法打开移动网络设置", e2.message)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
        
        // SOS 紧急援助的 MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.myeyes/sos").setMethodCallHandler { call, result ->
            Log.d("SOS", "Method called: ${call.method}")
            
            when (call.method) {
                "openDialer" -> {
                    try {
                        val intent = Intent(Intent.ACTION_DIAL)
                        intent.data = Uri.parse("tel:110")
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("SOS", "Error opening dialer: ${e.message}")
                        result.error("ERROR", "无法打开拨号界面", e.message)
                    }
                }
                "openDialer120" -> {
                    try {
                        val intent = Intent(Intent.ACTION_DIAL)
                        intent.data = Uri.parse("tel:120")
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("SOS", "Error opening dialer: ${e.message}")
                        result.error("ERROR", "无法打开拨号界面", e.message)
                    }
                }
                "openDialer119" -> {
                    try {
                        val intent = Intent(Intent.ACTION_DIAL)
                        intent.data = Uri.parse("tel:119")
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("SOS", "Error opening dialer: ${e.message}")
                        result.error("ERROR", "无法打开拨号界面", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun checkPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            ContextCompat.checkSelfPermission(context, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(context, android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
    
    private fun requestPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(
                    android.Manifest.permission.ACCESS_FINE_LOCATION,
                    android.Manifest.permission.ACCESS_COARSE_LOCATION
                ),
                PERMISSION_REQUEST_CODE
            )
        }
    }
}
