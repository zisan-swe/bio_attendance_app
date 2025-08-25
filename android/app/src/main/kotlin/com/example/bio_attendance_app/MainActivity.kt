package com.example.bio_attendance_app

import android.app.PendingIntent
import android.content.*
import android.graphics.Bitmap
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlinx.coroutines.suspendCancellableCoroutine
import java.lang.StringBuilder
import java.lang.reflect.Proxy
import java.nio.ByteBuffer
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import kotlin.coroutines.resume

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.legendit.zkteco"
    private val TAG = "SLK20R"
    private val ACTION_USB_PERMISSION = "com.example.bio_attendance_app.USB_PERMISSION"

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    // Class names present in your JARs (confirmed family)
    private val CLS_SERVICE = "com.zkteco.android.biometric.module.fingerprintreader.ZKFingerService"
    private val CLS_SENSOR  = "com.zkteco.android.biometric.module.fingerprintreader.FingerprintSensor"
    private val CLS_FACTORY1 = "com.zkteco.android.biometric.module.fingerprintreader.FingprintFactory" // SDK typo
    private val CLS_FACTORY2 = "com.zkteco.android.biometric.module.fingerprintreader.FingerprintFactory"
    private val CLS_CAPTURE_LISTENER = "com.zkteco.android.biometric.module.fingerprintreader.FingerprintCaptureListener"

    @Volatile private var fingerService: Any? = null
    @Volatile private var fpReader: Any? = null

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
                                // 1) Ensure device + permission (may show system dialog)
                                val dev = withContext(Dispatchers.Main) { getDeviceWithPermission(dbg) }
                                    ?: run {
                                        dbg.appendLine("NO_DEVICE: no 0x1B55 device or permission denied.")
                                        postError(result, "NO_DEVICE", "SLK20R not detected or USB permission denied.", dbg.toString()); return@launch
                                    }

                                // 2) Open/init SDK
                                ensureOpened(dev, dbg)

                                // 3) Capture (sync → async → direct-template), with retries
                                var bytes: ByteArray? = captureWithRetries(dbg, totalMs = 10000, perAttemptMs = 1600)

                                // If still empty, try direct template APIs
                                if (bytes == null || bytes.isEmpty()) {
                                    dbg.appendLine("Trying direct template APIs…")
                                    bytes = captureTemplateDirect(dbg, 6000)
                                    if (bytes != null) dbg.appendLine("Direct template API returned ${bytes.size} bytes.")
                                }

                                if (bytes == null || bytes.isEmpty()) {
                                    postError(result, "CAPTURE_EMPTY", "No finger image captured.", dbg.toString()); return@launch
                                }

                                // If payload looks like a template already, return as-is
                                if (bytes.size < 2048) {
                                    dbg.appendLine("Heuristic: payload size ${bytes.size} → treat as TEMPLATE (skip extract).")
                                    postSuccess(result, Base64.encodeToString(bytes, Base64.NO_WRAP)); return@launch
                                }

                                // 4) Extract template from image
                                val tpl = extractTemplate(bytes, dbg)
                                if (tpl == null || tpl.isEmpty()) {
                                    postError(result, "EXTRACT_FAIL", "Template extraction failed.", dbg.toString()); return@launch
                                }

                                // 5) Return Base64 template
                                postSuccess(result, Base64.encodeToString(tpl, Base64.NO_WRAP))
                            } catch (t: Throwable) {
                                Log.e(TAG, "scanFingerprint failed", t)
                                dbg.appendLine("Exception: ${t.javaClass.simpleName}: ${t.message}")
                                postError(result, "SCAN_FAIL", t.message ?: t.toString(), dbg.toString())
                            } finally {
                                stopCaptureQuietly()
                            }
                        }
                    }

                    // Optional: call from Flutter to see a deep dump of methods
                    "dumpSdk" -> {
                        scope.launch {
                            val dump = dumpAllSdkInfo()
                            postSuccess(result, dump)
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
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val receiver = object : BroadcastReceiver() {
                override fun onReceive(ctx: Context?, intent: Intent?) {
                    if (intent?.action == ACTION_USB_PERMISSION) {
                        try { unregisterReceiver(this) } catch (_: Throwable) {}
                        val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                        dbg?.appendLine("USB permission result: granted=$granted")
                        if (!cont.isCompleted) cont.resume(if (granted) dev else null)
                    }
                }
            }
            val filter = IntentFilter(ACTION_USB_PERMISSION)
            if (Build.VERSION.SDK_INT >= 33) {
                registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(receiver, filter)
            }
            dbg?.appendLine("Requesting USB permission…")
            um.requestPermission(dev, pi)
            cont.invokeOnCancellation { try { unregisterReceiver(receiver) } catch (_: Throwable) {} }
        }
    }

    // ✅ Any PID for ZKTeco vendor (0x1B55)
    private fun findSlk20r(um: UsbManager): UsbDevice? =
        um.deviceList.values.firstOrNull { d -> d.vendorId == 0x1B55 }

    /* -------------------------- SDK wiring (robust) --------------------------- */

    @Synchronized
    @Throws(Exception::class)
    private fun ensureOpened(dev: UsbDevice, dbg: StringBuilder) {
        if (fingerService != null && fpReader != null) { dbg.appendLine("ensureOpened: already open."); return }

        // Service (init optional)
        fingerService = createZkService(dbg)

        // Optional: SilkID bootstrap
        try {
            val silkCls = Class.forName("com.zkteco.android.biometric.util.SilkidService")
            val silk = tryConstruct(silkCls, this) ?: silkCls.getDeclaredConstructor().newInstance()
            tryInvokeAny(silk, listOf("init", "initialize", "start"), arrayOf(this))
            dbg.appendLine("SilkidService initialized.")
        } catch (_: Throwable) { }

        // Sensor via factory then constructors
        val sensor = tryCreateSensor(dbg)
            ?: throw RuntimeException("Could not create FingerprintSensor (no factory/constructor matched).")
        fpReader = sensor
        dbg.appendLine("Sensor created: ${sensor.javaClass.name}")

        // Try to open with many signatures
        if (!tryOpenSensor(sensor, dev, dbg)) {
            dumpMethods(sensor, listOf("open", "openDevice", "openReader", "openDeviceEx", "connect", "start"), dbg)
            throw RuntimeException("Failed to open FingerprintSensor (no matching open() signature).")
        }
        dbg.appendLine("FingerprintSensor opened successfully.")

        // Optional knobs (best-effort)
        tryInvokeAny(sensor, listOf("setLed", "setLED", "enableLeds"), arrayOf(true))
        tryInvokeAny(sensor, listOf("setDPI", "setResolution"), arrayOf(500))
        tryInvokeAny(sensor, listOf("setTimeout", "setTimeOut"), arrayOf(10000))
    }

    /** Repeated capture attempts (sync → async in each attempt) until something arrives or timeout. */
    private fun captureWithRetries(dbg: StringBuilder, totalMs: Int, perAttemptMs: Int): ByteArray? {
        val deadline = System.currentTimeMillis() + totalMs
        var attempt = 0
        while (System.currentTimeMillis() < deadline) {
            attempt++
            dbg.appendLine("Attempt #$attempt (perAttemptMs=$perAttemptMs)…")
            var img = captureSync(perAttemptMs, dbg)
            if (img == null || img.isEmpty()) {
                dbg.appendLine("Sync capture empty; trying async listener path…")
                img = captureAsync(perAttemptMs, dbg)
            }
            if (img != null && img.isNotEmpty()) {
                dbg.appendLine("Got ${img.size} bytes from attempt #$attempt.")
                return img
            }
            try { Thread.sleep(150) } catch (_: Throwable) {}
        }
        return null
    }

    /** Try direct/synchronous capture variants */
    private fun captureSync(timeoutMs: Int, dbg: StringBuilder): ByteArray? {
        val s = fpReader ?: return null
        (tryInvokeAny(s, listOf("capture"), arrayOf(timeoutMs)) as? ByteArray)?.let { dbg.appendLine("capture(int) → ${it.size} bytes"); return it }
        (tryInvokeAny(s, listOf("capture"), emptyArray()) as? ByteArray)?.let { dbg.appendLine("capture() → ${it.size} bytes"); return it }
        (tryInvokeAny(s, listOf("getImage", "acquire", "getImageEx", "acquireImage"), arrayOf(timeoutMs)) as? ByteArray)?.let { dbg.appendLine("getImage(int) → ${it.size} bytes"); return it }
        (tryInvokeAny(s, listOf("getImage", "acquire", "getImageEx", "acquireImage"), emptyArray()) as? ByteArray)?.let { dbg.appendLine("getImage() → ${it.size} bytes"); return it }

        // Some SDKs return an object; try to convert to bytes
        val obj = tryInvokeAny(s, listOf("capture", "getImage", "acquire", "getImageEx", "acquireImage"), arrayOf(timeoutMs))
            ?: tryInvokeAny(s, listOf("capture", "getImage", "acquire", "getImageEx", "acquireImage"), emptyArray())
        if (obj != null) {
            when (obj) {
                is Bitmap -> {
                    val arr = bitmapToGrayscaleBytes(obj); dbg.appendLine("capture→Bitmap (${arr.size} bytes)"); return arr
                }
                is ByteBuffer -> {
                    val arr = ByteArray(obj.remaining()); obj.get(arr); dbg.appendLine("capture→ByteBuffer (${arr.size} bytes)"); return arr
                }
                else -> {
                    val asBytes = obj.javaClass.methods.firstOrNull {
                        it.name.equals("getImage", true) || it.name.equals("getBytes", true) || it.name.equals("toBytes", true)
                    }?.invoke(obj) as? ByteArray
                    if (asBytes != null) { dbg.appendLine("capture→obj.getBytes (${asBytes.size} bytes)"); return asBytes }
                }
            }
        }
        return null
    }

    /** Async capture via any *Listener setter + startCapture/start/beginCapture/autoCapture */
    private fun captureAsync(timeoutMs: Int, dbg: StringBuilder): ByteArray? {
        val s = fpReader ?: return null

        // 1) Find a suitable listener setter
        val listenerSetter = s.javaClass.methods.firstOrNull { m ->
            val n = m.name.lowercase()
            val looksLikeSetter = n.startsWith("set") || n.startsWith("add") || n.startsWith("register")
            val listenerish = n.contains("listener") || n.contains("capture") || n.contains("image") || n.contains("finger")
            looksLikeSetter && listenerish && m.parameterTypes.size == 1 && m.parameterTypes[0].isInterface
        } ?: s.javaClass.methods.firstOrNull { m ->
            (m.name.equals("setCaptureListener", true) || m.name.equals("addCaptureListener", true)) && m.parameterTypes.size == 1
        } ?: run {
            dbg.appendLine("No listener setter found on ${s.javaClass.simpleName}."); return null
        }

        val iface = listenerSetter.parameterTypes[0]
        dbg.appendLine("Using listener setter ${listenerSetter.name}(${iface.simpleName})")

        val imageRef = AtomicReference<ByteArray?>()
        val latch = CountDownLatch(1)

        // 2) Build dynamic proxy for that interface
        val proxy = Proxy.newProxyInstance(
            iface.classLoader,
            arrayOf(iface)
        ) { _, _, args ->
            try {
                // Prefer byte[] / ByteBuffer / Bitmap
                args?.forEach { a ->
                    when (a) {
                        is ByteArray -> if (a.isNotEmpty()) { imageRef.set(a); latch.countDown() }
                        is ByteBuffer -> {
                            val arr = ByteArray(a.remaining()); a.get(arr); if (arr.isNotEmpty()) { imageRef.set(arr); latch.countDown() }
                        }
                        is Bitmap -> {
                            val arr = bitmapToGrayscaleBytes(a); if (arr.isNotEmpty()) { imageRef.set(arr); latch.countDown() }
                        }
                        else -> {
                            val bb = try {
                                a?.javaClass?.methods?.firstOrNull {
                                    it.name.equals("getBytes", true) || it.name.equals("toBytes", true) || it.name.equals("getImage", true)
                                }?.invoke(a) as? ByteArray
                            } catch (_: Throwable) { null }
                            if (bb != null && bb.isNotEmpty()) { imageRef.set(bb); latch.countDown() }
                        }
                    }
                }
            } catch (_: Throwable) { }
            null
        }

        // register listener
        try { listenerSetter.isAccessible = true; listenerSetter.invoke(s, proxy); dbg.appendLine("Listener registered via ${listenerSetter.name}") }
        catch (t: Throwable) { dbg.appendLine("Failed to register listener: ${t.message}"); return null }

        // 3) Start capture (try many names)
        val starters = s.javaClass.methods.filter { m ->
            val n = m.name.lowercase()
            n == "startcapture" || n == "start" || n == "begincapture" || n == "startimage" || n == "acquirestart" || n == "startautocapture" || n == "startcaptureimage"
        }
        if (starters.isEmpty()) { dumpMethods(s, listOf("start", "capture", "begin"), dbg); return null }

        var started = false
        val candidateArgs = listOf(
            emptyArray(),
            arrayOf(false), arrayOf(true),
            arrayOf(timeoutMs),
            arrayOf(timeoutMs, false), arrayOf(timeoutMs, true),
            arrayOf(this), arrayOf(this, false), arrayOf(this, true)
        )
        outer@ for (m in starters) {
            for (args in candidateArgs) {
                if (m.parameterTypes.size != args.size) continue
                try {
                    m.isAccessible = true
                    m.invoke(s, *args)
                    started = true
                    dbg.appendLine("Started async via ${m.name}(${args.joinToString { it.javaClass.simpleName }})")
                    break@outer
                } catch (_: Throwable) { }
            }
        }
        if (!started) { dbg.appendLine("Could not start async capture with any known signature."); return null }

        // 4) Wait for a callback
        latch.await(timeoutMs.toLong(), TimeUnit.MILLISECONDS)
        val img = imageRef.get()

        // 5) Stop capture if method exists
        try { tryInvokeAny(s, listOf("stopCapture", "stop", "end"), emptyArray()) } catch (_: Throwable) {}
        if (img != null) dbg.appendLine("Async listener delivered ${img.size} bytes.")

        return img
    }

    /** Some SDKs provide a direct template capture on sensor or service (no image path). */
    private fun captureTemplateDirect(dbg: StringBuilder, timeoutMs: Int): ByteArray? {
        val s = fpReader
        val svc = fingerService

        val names = listOf("acquireTemplate", "getTemplate", "captureTemplate", "getFPTemplate", "acquireFingerTemplate", "generateTemplate")
        val argsList: List<Array<Any>> = listOf(
            emptyArray(),
            arrayOf(timeoutMs),
            arrayOf(this),
            arrayOf(this, timeoutMs)
        )

        if (s != null) {
            for (nm in names) {
                for (args in argsList) {
                    val ret = tryInvokeAny(s, listOf(nm), args) as? ByteArray
                    if (ret != null && ret.isNotEmpty()) { dbg.appendLine("Sensor.$nm returned ${ret.size} bytes."); return ret }
                }
            }
        }
        if (svc != null) {
            for (nm in names) {
                for (args in argsList) {
                    val ret = tryInvokeAny(svc, listOf(nm), args) as? ByteArray
                    if (ret != null && ret.isNotEmpty()) { dbg.appendLine("Service.$nm returned ${ret.size} bytes."); return ret }
                }
            }
        }
        return null
    }

    /** Extract template via extract()/createTemplate()/process(); tries a few variants */
    private fun extractTemplate(imageBytes: ByteArray, dbg: StringBuilder): ByteArray? {
        val svc = fingerService ?: return null
        (tryInvokeAny(svc, listOf("extract", "createTemplate", "process"), arrayOf(imageBytes)) as? ByteArray)
            ?.let { dbg.appendLine("extract(image) → ${it.size} bytes"); return it }
        for (fmt in intArrayOf(0, 1, 256)) {
            (tryInvokeAny(svc, listOf("extract", "createTemplate", "process"), arrayOf(imageBytes, fmt)) as? ByteArray)
                ?.let { dbg.appendLine("extract(image, $fmt) → ${it.size} bytes"); return it }
        }
        svc.javaClass.methods.firstOrNull { it.name.equals("getService", true) }?.let { getSvc ->
            val inner = getSvc.invoke(svc) ?: return null
            (tryInvokeAny(inner, listOf("extract", "createTemplate", "process"), arrayOf(imageBytes)) as? ByteArray)
                ?.let { dbg.appendLine("inner.extract(image) → ${it.size} bytes"); return it }
        }
        return null
    }

    private fun stopCaptureQuietly() {
        val s = fpReader ?: return
        try { tryInvokeAny(s, listOf("stopCapture", "stop", "end"), emptyArray()) } catch (_: Throwable) {}
    }

    @Synchronized
    private fun releaseAll() {
        val s = fpReader
        val svc = fingerService
        fpReader = null
        fingerService = null
        try { if (s != null) tryInvokeAny(s, listOf("close", "release", "shutdown"), emptyArray()) } catch (_: Throwable) {}
        try { if (svc != null) tryInvokeAny(svc, listOf("close", "release", "free"), emptyArray()) } catch (_: Throwable) {}
    }

    /* ------------------------------- helpers -------------------------------- */

    private fun usb() = getSystemService(Context.USB_SERVICE) as UsbManager

    private fun hasVendorSdk(): Boolean =
        try { Class.forName(CLS_SERVICE); Class.forName(CLS_SENSOR); true } catch (_: Throwable) { false }

    private fun logd(msg: String) = Log.d(TAG, msg)

    /** Create service; try with/without Context init */
    private fun createZkService(dbg: StringBuilder): Any {
        val svcNames = listOf(
            CLS_SERVICE,
            "com.zkteco.zkfinger.FingerprintService",
            "com.zkteco.zkfinger.ZKIDFprService",
            "com.zkteco.biometric.IDFprService"
        )
        for (name in svcNames) {
            try {
                val cls = Class.forName(name)
                val inst = tryConstruct(cls, this) ?: cls.getDeclaredConstructor().newInstance()
                tryInvokeAny(inst, listOf("init", "initialize", "Init"), arrayOf(this))
                    ?: tryInvokeAny(inst, listOf("init", "initialize", "Init"), emptyArray())
                dbg.appendLine("Service initialized with $name")
                return inst
            } catch (_: Throwable) { }
        }
        // If no init method, return first constructible
        for (name in svcNames) {
            try {
                val cls = Class.forName(name)
                val inst = tryConstruct(cls, this) ?: cls.getDeclaredConstructor().newInstance()
                dbg.appendLine("Service constructed (no init) with $name")
                return inst
            } catch (_: Throwable) { }
        }
        throw RuntimeException("No ZK finger service class available.")
    }

    /** Sensor from factory or constructors */
    private fun tryCreateSensor(dbg: StringBuilder): Any? {
        for (fn in listOf(CLS_FACTORY1, CLS_FACTORY2)) {
            try {
                val f = Class.forName(fn)
                for (m in f.methods) {
                    val n = m.name.lowercase()
                    if (!(n.startsWith("create") || n.startsWith("get"))) continue
                    val args: Array<Any> = when (m.parameterTypes.size) {
                        0 -> emptyArray()
                        1 -> arrayOf(this)
                        2 -> arrayOf(this, usb())
                        else -> continue
                    }
                    try {
                        val obj = m.invoke(null, *args)
                        if (obj != null && obj.javaClass.name.contains("FingerprintSensor", true)) {
                            dbg.appendLine("Sensor created via $fn.${m.name}(${m.parameterTypes.size} args)")
                            return obj
                        }
                    } catch (_: Throwable) { }
                }
            } catch (_: Throwable) { }
        }
        for (n in listOf(CLS_SENSOR, "com.zkteco.fingerprintreader.FingerprintSensor")) {
            try {
                val c = Class.forName(n)
                tryConstruct(c, this)?.let { dbg.appendLine("Sensor constructed with $n(Context)"); return it }
                c.getDeclaredConstructor().newInstance()?.let { dbg.appendLine("Sensor constructed with $n()"); return it }
            } catch (_: Throwable) { }
        }
        return null
    }

    /** Try many open/connect signatures */
    private fun tryOpenSensor(sensor: Any, dev: UsbDevice, dbg: StringBuilder): Boolean {
        val um = usb()
        val vid = dev.vendorId
        val pid = dev.productId

        val names = listOf("open", "openDevice", "openReader", "openDeviceEx", "connect", "start", "startDevice")
        val combos: List<Array<Any>> = listOf(
            emptyArray(),
            arrayOf(this),
            arrayOf(um),
            arrayOf(dev),
            arrayOf(vid, pid),
            arrayOf(pid, vid),
            arrayOf(pid), arrayOf(vid),
            arrayOf(0), arrayOf(1), // index-based
            arrayOf(this, dev),
            arrayOf(this, um),
            arrayOf(this, vid, pid),
            arrayOf(this, pid),
            arrayOf(um, dev),
            arrayOf(um, vid, pid),
            arrayOf(dev, um),
            arrayOf(dev, this),
            arrayOf(um, dev, this),
            arrayOf(this, um, dev),
            arrayOf(dev, um, this)
        )
        val methods = sensor.javaClass.methods.filter { m -> names.any { m.name.equals(it, true) } }
        for (m in methods) {
            for (args in combos) {
                if (m.parameterTypes.size != args.size) continue
                try {
                    m.isAccessible = true
                    val ret = m.invoke(sensor, *args)
                    when (ret) {
                        is Int -> { dbg.appendLine("open ${m.name}(${args.size}) → int=$ret"); if (ret == 0) return true }
                        is Boolean -> { dbg.appendLine("open ${m.name}(${args.size}) → bool=$ret"); if (ret) return true }
                        else -> { dbg.appendLine("open ${m.name}(${args.size}) → void/other (assume success)"); return true }
                    }
                } catch (_: Throwable) { }
            }
        }
        dbg.appendLine("No open-like signature matched on ${sensor.javaClass.name}")
        return false
    }

    private fun dumpMethods(target: Any, names: List<String>, dbg: StringBuilder) {
        dbg.appendLine("Available methods on ${target.javaClass.name}:")
        for (m in target.javaClass.methods) {
            if (names.any { m.name.contains(it, ignoreCase = true) }) {
                dbg.append("  ").append(m.name).append("(")
                dbg.append(m.parameterTypes.joinToString { it.simpleName })
                dbg.append(") -> ").append(m.returnType.simpleName).append("\n")
            }
        }
    }

    private fun tryConstruct(c: Class<*>, ctx: Context): Any? {
        return try {
            val ctor = c.declaredConstructors.firstOrNull {
                it.parameterTypes.size == 1 && it.parameterTypes[0].isAssignableFrom(Context::class.java)
            } ?: return null
            ctor.isAccessible = true
            ctor.newInstance(ctx)
        } catch (_: Throwable) { null }
    }

    private fun tryInvokeAny(target: Any, names: List<String>, args: Array<out Any>): Any? {
        val methods = target.javaClass.methods
        for (nm in names) {
            val cands = methods.filter { it.name.equals(nm, true) && it.parameterTypes.size == args.size }
            for (m in cands) {
                try { m.isAccessible = true; return m.invoke(target, *args) } catch (_: Throwable) {}
            }
            for (m in methods.filter { it.name.equals(nm, true) }) {
                try { m.isAccessible = true; return if (args.isEmpty()) m.invoke(target) else m.invoke(target, *args) } catch (_: Throwable) {}
            }
        }
        return null
    }

    private fun bitmapToGrayscaleBytes(bm: Bitmap): ByteArray {
        val w = bm.width
        val h = bm.height
        val out = ByteArray(w * h)
        val row = IntArray(w)
        var idx = 0
        for (y in 0 until h) {
            bm.getPixels(row, 0, w, 0, y, w, 1)
            for (x in 0 until w) {
                val p = row[x]
                val r = (p shr 16) and 0xff
                val g = (p shr 8) and 0xff
                val b = (p) and 0xff
                out[idx++] = ((0.299 * r + 0.587 * g + 0.114 * b).toInt() and 0xff).toByte()
            }
        }
        return out
    }

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

    override fun onDestroy() {
        super.onDestroy()
        releaseAll()
        scope.cancel()
    }

    /* ----------------------- OPTIONAL: deep SDK dump ------------------------ */

    private fun dumpAllSdkInfo(): String {
        val sb = StringBuilder()
        val svc = fingerService
        val sen = fpReader
        sb.appendLine("SDK Present: ${hasVendorSdk()}")  // ✅ FIXED: call the function
        sb.appendLine("Service: ${svc?.javaClass?.name ?: "(null)"}")
        sb.appendLine("Sensor : ${sen?.javaClass?.name ?: "(null)"}")
        listOfNotNull(svc, sen).forEach { obj ->
            sb.appendLine("\nMethods of ${obj.javaClass.name}:")
            obj.javaClass.methods.sortedBy { it.name }.forEach { m ->
                sb.append("  ").append(m.name).append("(")
                sb.append(m.parameterTypes.joinToString { it.simpleName })
                sb.append(") -> ").append(m.returnType.simpleName).append("\n")
            }
        }
        return sb.toString()
    }
}
