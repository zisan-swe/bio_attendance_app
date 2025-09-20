package com.example.bio_attendance_app

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Bundle
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.lang.StringBuilder
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume

import com.zkteco.android.biometric.core.device.ParameterHelper
import com.zkteco.android.biometric.core.device.TransportType
import com.zkteco.android.biometric.core.utils.LogHelper
import com.zkteco.android.biometric.module.fingerprintreader.FingerprintCaptureListener
import com.zkteco.android.biometric.module.fingerprintreader.FingerprintSensor
import com.zkteco.android.biometric.module.fingerprintreader.FingerprintFactory
import com.zkteco.android.biometric.module.fingerprintreader.ZKFingerService
import com.zkteco.android.biometric.module.fingerprintreader.exception.FingerprintException
import java.lang.reflect.Method
import java.util.HashMap

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.legendit.zkteco"
    private val TAG = "SLK20R"
    private val ACTION_USB_PERMISSION = "com.example.bio_attendance_app.USB_PERMISSION"

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private var fingerprintSensor: FingerprintSensor? = null
    private val VID = 6997 // 0x1B55
    private val PID = 288  // 0x0120

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "diagnoseUsb" -> {
                        scope.launch {
                            val sb = StringBuilder()
                            val um = usb()
                            um.deviceList.values.forEach {
                                sb.append("• name=${it.deviceName} id=${it.deviceId} VID=0x${it.vendorId.toString(16)} PID=0x${it.productId.toString(16)} perm=${um.hasPermission(it)}\n")
                            }
                            val slk = findSlk20r(um)
                            val has = slk?.let { um.hasPermission(it) } ?: false
                            val sdkPresent = hasVendorSdk()
                            val note = if (isEmulator()) "Running on emulator; OTG not supported." else null
                            postSuccessMap(result, mapOf(
                                "devices" to sb.toString().trim(),
                                "hasPermission" to has,
                                "sdkPresent" to sdkPresent,
                                "note" to note
                            ))
                        }
                    }

                    "scanFingerprint" -> {
                        if (isEmulator()) {
                            result.error("NO_OTG", "Use a real Android device with USB-OTG.", "Emulators cannot use USB-OTG.")
                            return@setMethodCallHandler
                        }
                        scope.launch {
                            val dbg = StringBuilder()
                            try {
                                // 1) First check current device status
                                val um = usb()
                                dbg.appendLine("Initial device scan:")
                                um.deviceList.values.forEach {
                                    dbg.appendLine("  - ${it.deviceName}: VID=0x${it.vendorId.toString(16)}, PID=0x${it.productId.toString(16)}, perm=${um.hasPermission(it)}")
                                }

                                var dev = findSlk20r(um)
                                val hasPerm = dev?.let { um.hasPermission(it) } ?: false

                                dbg.appendLine("Initial SLK20R found: $dev, hasPermission: $hasPerm")

                                if (dev == null) {
                                    postError(result, "NO_DEVICE", "SLK20R not detected.", dbg.toString()); return@launch
                                }

                                if (!hasPerm) {
                                    // 2) Request permission (this shows the dialog)
                                    dbg.appendLine("Requesting USB permission...")
                                    dev = withContext(Dispatchers.Main) { getDeviceWithPermission(dbg) }
                                    if (dev == null) {
                                        postError(result, "NO_DEVICE", "USB permission denied.", dbg.toString()); return@launch
                                    }

                                    // 3) After permission granted, re-check the device
                                    dbg.appendLine("Permission granted, re-scanning devices...")
                                    dev = findDeviceAfterPermission(um, dbg)
                                    if (dev == null) {
                                        postError(result, "NO_DEVICE", "Device not found after permission grant.", dbg.toString()); return@launch
                                    }
                                    dbg.appendLine("Device confirmed after permission: $dev")
                                }

                                // 4) Open/init SDK
                                ensureOpened(dev, dbg)

                                // 5) Turn on LED to indicate ready state
                                dbg.appendLine("Turning on scanner LED...")
                                controlScannerLed(true, dbg)

                                // 6) Capture with retries
                                var bytes: ByteArray? = captureWithRetries(dbg, totalMs = 15000, perAttemptMs = 5000)

                                // 7) Turn off LED after capture attempt
                                controlScannerLed(false, dbg)

                                if (bytes == null || bytes.isEmpty()) {
                                    postError(result, "CAPTURE_EMPTY", "No finger image captured.", dbg.toString()); return@launch
                                }

                                // If payload looks like a template already, return as-is
                                if (bytes.size < 2048) {
                                    dbg.appendLine("Heuristic: payload size ${bytes.size} → treat as TEMPLATE (skip extract).")
                                    postSuccess(result, Base64.encodeToString(bytes, Base64.NO_WRAP)); return@launch
                                }

                                // 8) Extract template from image (if needed; listener already extracts)
                                val tpl = extractTemplate(bytes, dbg)
                                if (tpl == null || tpl.isEmpty()) {
                                    postError(result, "EXTRACT_FAIL", "Template extraction failed.", dbg.toString()); return@launch
                                }

                                // 9) Return Base64 template
                                postSuccess(result, Base64.encodeToString(tpl, Base64.NO_WRAP))
                            } catch (t: Throwable) {
                                controlScannerLed(false, dbg) // Ensure LED is off on error
                                Log.e(TAG, "scanFingerprint failed", t)
                                dbg.appendLine("Exception: ${t.javaClass.simpleName}: ${t.message}")
                                postError(result, "SCAN_FAIL", t.message ?: t.toString(), dbg.toString())
                            } finally {
                                stopCaptureQuietly()
                            }
                        }
                    }

                    "dumpSdk" -> {
                        scope.launch {
                            val dump = dumpAllSdkInfo()
                            postSuccess(result, dump)
                        }
                    }

                    "ledOn" -> {
                        try {
                            controlScannerLed(true, StringBuilder())
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("LED_ON_ERROR", e.message, null)
                        }
                    }

                    "ledOff" -> {
                        try {
                            controlScannerLed(false, StringBuilder())
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("LED_OFF_ERROR", e.message, null)
                        }
                    }


                    // ✅ তোমার নতুন verifyFingerprint এখানে বসবে
                    "verifyFingerprint" -> {
                        scope.launch {
                            try {
                                val base64NewTpl = call.argument<String>("template") ?: ""
                                val base64StoredTpls = call.argument<List<String>>("stored") ?: emptyList()

                                if (base64NewTpl.isEmpty() || base64StoredTpls.isEmpty()) {
                                    result.error("VERIFY_INVALID", "Empty template provided", null)
                                    return@launch
                                }

                                val newTpl = Base64.decode(base64NewTpl, Base64.NO_WRAP)
                                var bestScore = 0
                                var matched = false
                                var matchedEmployeeId: Int? = null

                                Log.d(TAG, "🔍 New Template length: ${newTpl.size}")

                                for ((index, storedTplBase64) in base64StoredTpls.withIndex()) {
                                    val storedTpl = Base64.decode(storedTplBase64, Base64.NO_WRAP)

                                    Log.d(TAG, "👉 Comparing with stored[$index], length=${storedTpl.size}")

                                    // ✅ Use ZKFingerService verify
                                    val score = ZKFingerService.verify(newTpl, storedTpl)

                                    Log.d(TAG, "📊 Score with stored[$index] = $score")

                                    if (score >= 40) { // ✅ Lower threshold for debugging
                                        matched = true
                                        bestScore = score
                                        matchedEmployeeId = index
                                        break
                                    }

                                    if (score > bestScore) {
                                        bestScore = score // keep best score even if not matched
                                    }
                                }

                                if (matched) {
                                    Log.i(TAG, "✅ Match found! Employee=$matchedEmployeeId, Score=$bestScore")
                                } else {
                                    Log.w(TAG, "❌ No Match. Best Score=$bestScore")
                                }

                                result.success(
                                    mapOf(
                                        "matched" to matched,
                                        "score" to bestScore,
                                        "matchedEmployeeId" to matchedEmployeeId
                                    )
                                )
                            } catch (e: Exception) {
                                Log.e(TAG, "Verification failed", e)
                                result.error("VERIFY_FAIL", "Verification failed: ${e.message}", e.stackTraceToString())
                            }
                        }
                    }


                    else -> result.notImplemented()
                }
            }
    }

    /* --------------------------- USB permission flow --------------------------- */

    private suspend fun getDeviceWithPermission(dbg: StringBuilder? = null): UsbDevice? {
        val um = usb()
        val dev = findSlk20r(um)
        if (dev == null) {
            dbg?.appendLine("findSlk20r: no device with VID=0x1B55 found.")
            return null
        }
        if (um.hasPermission(dev)) return dev

        return suspendCancellableCoroutine { cont ->
            val pi = PendingIntent.getBroadcast(
                this, 0, Intent(ACTION_USB_PERMISSION),
                PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_MUTABLE else 0
            )

            val receiver = object : BroadcastReceiver() {
                override fun onReceive(ctx: Context?, intent: Intent?) {
                    if (intent?.action == ACTION_USB_PERMISSION) {
                        try { unregisterReceiver(this) } catch (_: Throwable) {}
                        val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                        val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)

                        dbg?.appendLine("USB permission result: granted=$granted, device=$device")

                        if (!cont.isCompleted) {
                            if (granted && device != null) {
                                cont.resume(device)
                            } else {
                                cont.resume(null)
                            }
                        }
                    }
                }
            }

            val filter = IntentFilter(ACTION_USB_PERMISSION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(receiver, filter)
            }

            dbg?.appendLine("Requesting USB permission for device: $dev")
            um.requestPermission(dev, pi)

            cont.invokeOnCancellation {
                try { unregisterReceiver(receiver) } catch (_: Throwable) {}
            }
        }
    }

    private fun findDeviceAfterPermission(um: UsbManager, dbg: StringBuilder? = null): UsbDevice? {
        val devices = um.deviceList.values
        dbg?.appendLine("Re-scanning devices after permission: ${devices.size} found")

        devices.forEach { device ->
            dbg?.appendLine("Device: ${device.deviceName}, VID=0x${device.vendorId.toString(16)}, " +
                    "PID=0x${device.productId.toString(16)}, perm=${um.hasPermission(device)}")
        }

        return findSlk20r(um).also {
            dbg?.appendLine("SLK20R found after permission: $it")
        }
    }

    // ✅ Any PID for ZKTeco vendor (0x1B55)
    private fun findSlk20r(um: UsbManager): UsbDevice? {
        // Preferred vendor IDs often used by ZKTeco/SilkID devices.
        val preferredVids = listOf(0x1B55, 0x1B96, 0x1B3F, 0x0401)
        // 1) Exact VID match
        um.deviceList.values.firstOrNull { d -> d.vendorId in preferredVids }?.let { return it }

        // 2) Name heuristics
        um.deviceList.values.firstOrNull { d ->
            val nm = d.deviceName ?: ""
            nm.contains("zk", ignoreCase = true) ||
                    nm.contains("zkteco", ignoreCase = true) ||
                    nm.contains("slk", ignoreCase = true) ||
                    nm.contains("silk", ignoreCase = true)
        }?.let { return it }

        // 3) Interface class heuristic: vendor-specific (0xFF)
        um.deviceList.values.firstOrNull { d ->
            try {
                var found = false
                for (i in 0 until d.interfaceCount) {
                    val intf = d.getInterface(i)
                    if (intf.interfaceClass == 255) { // UsbConstants.USB_CLASS_VENDOR_SPEC
                        found = true
                        break
                    }
                }
                found
            } catch (e: Throwable) {
                false
            }
        }?.let { return it }

        // 4) Fallback: first available device
        return um.deviceList.values.firstOrNull()
    }

    /* -------------------------- SDK wiring (direct calls) --------------------------- */

    @Synchronized
    @Throws(Exception::class)
    private fun ensureOpened(dev: UsbDevice, dbg: StringBuilder) {
        if (fingerprintSensor != null) {
            dbg.appendLine("ensureOpened: already open.")
            return
        }

        LogHelper.setLevel(Log.DEBUG)
        val params = HashMap<String, Any>()  // Use Any to allow Integer
        params[ParameterHelper.PARAM_KEY_VID] = java.lang.Integer.valueOf(VID)  // Box kotlin.Int to java.lang.Integer
        params[ParameterHelper.PARAM_KEY_PID] = java.lang.Integer.valueOf(PID)  // Box kotlin.Int to java.lang.Integer

        fingerprintSensor = FingerprintFactory.createFingerprintSensor(this, TransportType.USB, params)
        if (fingerprintSensor == null) throw RuntimeException("Factory failed")

        dbg.appendLine("FingerprintSensor created")

        try {
            fingerprintSensor!!.open(0)
            dbg.appendLine("Opened with index=0")

            val sn = fingerprintSensor!!.strSerialNumber
            val fw = fingerprintSensor!!.firmwareVersion
            dbg.appendLine("Device SN: $sn, Firmware: $fw")
        } catch (e: FingerprintException) {
            dbg.appendLine("Open failed: ${e.errorCode} - ${e.message}")
            throw e
        }

        try {
            fingerprintSensor!!.setFakeFunOn(1)
            dbg.appendLine("Anti-fake enabled")
        } catch (e: Exception) {
            dbg.appendLine("setFakeFunOn failed: ${e.message}")
        }
    }

    /** Direct async capture with listener (Sec 3.1.3-3.1.5) */
    private fun captureWithRetries(dbg: StringBuilder, totalMs: Int, perAttemptMs: Int): ByteArray? {
        val sensor = fingerprintSensor ?: return null
        val deadline = System.currentTimeMillis() + totalMs
        var capturedImage: ByteArray? = null
        var capturedTemplate: ByteArray? = null

        val listener = object : FingerprintCaptureListener {
            override fun captureOK(fpImage: ByteArray) {
                capturedImage = fpImage
                Log.i(TAG, "captureOK: ${fpImage.size} bytes image")
                dbg.appendLine("captureOK: ${fpImage.size} bytes image")
                // Optional: Log width/height
                Log.i(TAG, "Image: width=${sensor.imageWidth}, height=${sensor.imageHeight}")
            }
            override fun captureError(e: FingerprintException) {
                Log.e(TAG, "captureError: ${e.errorCode} - ${e.message}")
                dbg.appendLine("captureError: ${e.errorCode} - ${e.message}")
            }
            override fun extractOK(fpTemplate: ByteArray) {
                capturedTemplate = fpTemplate
                Log.i(TAG, "extractOK: ${fpTemplate.size} bytes template")
                dbg.appendLine("extractOK: ${fpTemplate.size} bytes template")
            }
            override fun extractError(errno: Int) {
                Log.e(TAG, "extractError: $errno")
                dbg.appendLine("extractError: $errno (see Appendix I for codes)")
            }
        }

        try {
            sensor.setFingerprintCaptureListener(0, listener)  // Exact: index=0
            sensor.startCapture(0)  // Exact: starts async, triggers listener
            dbg.appendLine("setFingerprintCaptureListener(0) & startCapture(0) called")

            // Poll for result with latch
            val latch = CountDownLatch(1)
            val timeoutLatch = Thread {
                try {
                    Thread.sleep(perAttemptMs.toLong())
                } catch (_: InterruptedException) {}
                if (latch.count > 0) latch.countDown()
            }
            timeoutLatch.start()

            latch.await()
            timeoutLatch.join()

            sensor.stopCapture(0)
            dbg.appendLine("stopCapture(0) called")

            // Prioritize template; fallback to image
            return capturedTemplate?.takeIf { it.isNotEmpty() } ?: capturedImage?.takeIf { it.isNotEmpty() }
            ?: run {
                dbg.appendLine("No data in listener callbacks")
                null
            }
        } catch (e: FingerprintException) {
            dbg.appendLine("Capture exception: ${e.errorCode} - ${e.message}")
            return null
        }
    }

    /** Extract template via ZKFingerService if image provided */
    private fun extractTemplate(imageBytes: ByteArray, dbg: StringBuilder): ByteArray? {
        return try {
            // SDK listener handles extractOK; fallback quality check
            val quality = ZKFingerService.getTemplateQuality(imageBytes)
            dbg.appendLine("Template quality: $quality")
            imageBytes  // Fallback to image
        } catch (e: Exception) {
            dbg.appendLine("Extract failed: ${e.message}")
            null
        }
    }

    /** Control scanner LED via anti-fake (Sec 3.1.10-3.1.11) */
    private fun controlScannerLed(enabled: Boolean, dbg: StringBuilder) {
        val sensor = fingerprintSensor ?: return
        try {
            sensor.setFakeFunOn(if (enabled) 1 else 0)
            val status = sensor.fakeStatus
            dbg.appendLine("setFakeFunOn(${if (enabled) 1 else 0}) - Status: $status (true if (status & 0x1F) == 31)")
        } catch (e: Exception) {
            dbg.appendLine("LED/live detect failed: ${e.message}")
        }
    }

    private fun stopCaptureQuietly() {
        val sensor = fingerprintSensor ?: return
        try {
            sensor.stopCapture(0)
        } catch (_: Throwable) {}
    }

    @Synchronized
    private fun releaseAll() {
        val sensor = fingerprintSensor
        fingerprintSensor = null
        try {
            if (sensor != null) {
                sensor.stopCapture(0)
                sensor.close(0)
            }
        } catch (_: Throwable) {}
    }

    /* ------------------------------- helpers -------------------------------- */

    private fun usb() = getSystemService(Context.USB_SERVICE) as UsbManager

    private fun hasVendorSdk(): Boolean = try {
        Class.forName("com.zkteco.android.biometric.module.fingerprintreader.ZKFingerService")
        Class.forName("com.zkteco.android.biometric.module.fingerprintreader.FingerprintSensor")
        true
    } catch (_: Throwable) { false }

    private fun logd(msg: String) = Log.d(TAG, msg)

    private fun postSuccess(result: MethodChannel.Result, text: String) =
        runOnUiThread { result.success(text) }

    private fun postSuccessMap(result: MethodChannel.Result, map: Map<String, Any?>) =
        runOnUiThread { result.success(map) }

    private fun postError(result: MethodChannel.Result, code: String, msg: String, details: String? = null) =
        runOnUiThread { result.error(code, msg, details) }

    private fun isEmulator(): Boolean =
        Build.FINGERPRINT.startsWith("generic") ||
                Build.MODEL.contains("Emulator", true) ||
                Build.BRAND.contains("generic", true) ||
                Build.PRODUCT.contains("sdk", true)

    private fun dumpAllSdkInfo(): String {
        val sb = StringBuilder()
        val sen = fingerprintSensor
        sb.appendLine("SDK Present: ${hasVendorSdk()}")
        sb.appendLine("Sensor: ${sen?.javaClass?.name ?: "(null)"}")
        if (sen != null) {
            sb.appendLine("\nMethods of ${sen.javaClass.name}:")
            sen.javaClass.methods.sortedBy { it.name }.forEach { m ->
                sb.append("  ").append(m.name).append("(")
                sb.append(m.parameterTypes.joinToString { it.simpleName })
                sb.append(") -> ").append(m.returnType.simpleName).append("\n")
            }
        }
        return sb.toString()
    }

    override fun onDestroy() {
        super.onDestroy()
        releaseAll()
        scope.cancel()
    }

//    private fun matchFingerprint(newTemplate: ByteArray, storedTemplate: ByteArray): Boolean {
//        try {
//            // Use ZKFingerService.verify() to compare templates
//            val score = ZKFingerService.verify(newTemplate, storedTemplate)
//            val isMatch = score >= 50 // Threshold: Adjust based on SDK docs (typically 70–80)
//            Log.i(TAG, "Verification Score: $score, Match: $isMatch")
//            return isMatch
//        } catch (e: Exception) {
//            Log.e(TAG, "Verification failed: ${e.message}")
//            return false
//        }
//    }





}