package com.nearby.app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.Build
import android.os.ParcelUuid
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nearby.app/ble_advertiser"
    private var advertiser: BluetoothLeAdvertiser? = null
    private var advertiseCallback: AdvertiseCallback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAdvertising" -> {
                    val serviceUuid = call.argument<String>("serviceUuid")
                    val ephemeralId = call.argument<String>("ephemeralId")
                    if (serviceUuid != null && ephemeralId != null) {
                        val started = startBleAdvertising(serviceUuid, ephemeralId)
                        result.success(started)
                    } else {
                        result.error("INVALID_ARGS", "Missing serviceUuid or ephemeralId", null)
                    }
                }
                "stopAdvertising" -> {
                    stopBleAdvertising()
                    result.success(null)
                }
                "isAdvertisingSupported" -> {
                    result.success(isAdvertisingSupported())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAdvertisingSupported(): Boolean {
        val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
        val btAdapter = btManager?.adapter ?: return false
        return btAdapter.isEnabled && btAdapter.isMultipleAdvertisementSupported
    }

    private fun startBleAdvertising(serviceUuid: String, ephemeralId: String): Boolean {
        return try {
            val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
            val btAdapter = btManager?.adapter ?: return false
            advertiser = btAdapter.bluetoothLeAdvertiser ?: return false

            val settings = AdvertiseSettings.Builder()
                .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
                .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
                .setConnectable(false)
                .build()

            val uuid = ParcelUuid(UUID.fromString(serviceUuid))
            // ephemeralId is now a 12-char hex string (12 bytes).
            // addServiceData already embeds the UUID, so addServiceUuid is redundant
            // and would push the packet over the 31-byte BLE advertising limit.
            val idBytes = ephemeralId.toByteArray(Charsets.UTF_8)

            val data = AdvertiseData.Builder()
                .setIncludeDeviceName(false)
                .addServiceData(uuid, idBytes)
                .build()

            val callback = object : AdvertiseCallback() {
                override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {}
                override fun onStartFailure(errorCode: Int) {
                    advertiser = null
                }
            }
            advertiseCallback = callback
            advertiser?.startAdvertising(settings, data, callback)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun stopBleAdvertising() {
        try {
            advertiseCallback?.let { advertiser?.stopAdvertising(it) }
        } catch (_: Exception) {}
        advertiser = null
        advertiseCallback = null
    }

    override fun onDestroy() {
        stopBleAdvertising()
        super.onDestroy()
    }
}
