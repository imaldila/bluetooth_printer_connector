package com.example.bluetooth_printer_connector

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.util.*

class BluetoothPrinterConnectorPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private var bluetoothAdapter: BluetoothAdapter? = null
  private var bluetoothSocket: BluetoothSocket? = null
  
  // UUID for Serial Port Profile (SPP)
  private val SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "bluetooth_printer_connector")
    context = flutterPluginBinding.applicationContext
    channel.setMethodCallHandler(this)
    
    val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    bluetoothAdapter = bluetoothManager.adapter
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "isBluetoothEnabled" -> {
        result.success(bluetoothAdapter?.isEnabled == true)
      }
      "enableBluetooth" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            !hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) {
          result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
          return
        }
        result.success(bluetoothAdapter?.enable() == true)
      }
      "getBondedDevices" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            !hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) {
          result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
          return
        }
        
        val bondedDevices = bluetoothAdapter?.bondedDevices
        val devicesList = bondedDevices?.map {
          mapOf(
            "name" to (it.name ?: "Unknown"),
            "address" to it.address,
            "isConnected" to (bluetoothSocket?.remoteDevice?.address == it.address)
          )
        }
        result.success(devicesList?.toList() ?: listOf<Map<String, Any>>())
      }
      "startDiscovery" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            !hasPermission(Manifest.permission.BLUETOOTH_SCAN)) {
          result.error("PERMISSION_DENIED", "Bluetooth scan permission not granted", null)
          return
        }
        
        bluetoothAdapter?.startDiscovery()
        result.success(null)
      }
      "stopDiscovery" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            !hasPermission(Manifest.permission.BLUETOOTH_SCAN)) {
          result.error("PERMISSION_DENIED", "Bluetooth scan permission not granted", null)
          return
        }
        
        bluetoothAdapter?.cancelDiscovery()
        result.success(null)
      }
      "connect" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            !hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) {
          result.error("PERMISSION_DENIED", "Bluetooth permission not granted", null)
          return
        }
        
        val address = call.argument<String>("address")
        if (address == null) {
          result.error("INVALID_ARGUMENT", "Device address is required", null)
          return
        }

        try {
          val device = bluetoothAdapter?.getRemoteDevice(address)
          bluetoothSocket = device?.createRfcommSocketToServiceRecord(SPP_UUID)
          bluetoothSocket?.connect()
          result.success(true)
        } catch (e: IOException) {
          try {
            bluetoothSocket?.close()
          } catch (ce: IOException) {
            ce.printStackTrace()
          }
          bluetoothSocket = null
          result.error("CONNECTION_FAILED", e.message, null)
        }
      }
      "disconnect" -> {
        try {
          bluetoothSocket?.close()
          bluetoothSocket = null
          result.success(true)
        } catch (e: IOException) {
          result.error("DISCONNECT_FAILED", e.message, null)
        }
      }
      "getConnectionState" -> {
        val state = when {
          bluetoothSocket?.isConnected == true -> "connected"
          bluetoothSocket != null -> "connecting"
          else -> "disconnected"
        }
        result.success(state)
      }
      "write" -> {
        if (bluetoothSocket == null || bluetoothSocket?.isConnected != true) {
          result.error("NOT_CONNECTED", "Printer is not connected", null)
          return
        }

        try {
          val data = call.argument<List<Int>>("data")
          if (data == null) {
            result.error("INVALID_ARGUMENT", "Data is required", null)
            return
          }

          bluetoothSocket?.outputStream?.write(data.map { it.toByte() }.toByteArray())
          bluetoothSocket?.outputStream?.flush()
          result.success(true)
        } catch (e: IOException) {
          result.error("WRITE_FAILED", e.message, null)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun hasPermission(permission: String): Boolean {
    return ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
