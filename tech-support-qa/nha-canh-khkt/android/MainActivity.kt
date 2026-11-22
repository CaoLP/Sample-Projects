package com.example.nhacanh  // đổi theo package của project

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.random.Random

// Ngưỡng nghiên cứu - phải chỉnh lại theo đo thực tế (ADC 0..4095)
const val MQ_DELTA = 400      // MQ-2 tăng so với giá trị nền
const val TEMP_MAX = 50.0     // °C
const val HUM_MAX = 85.0      // %
const val WATER_MAX = 3000    // ADC mực nước
const val MPU_MAX = 0.5       // g lệch so với 1g

data class Reading(
    val t: Double, val h: Double, val td: Double, val mq: Int, val water: Int, val mpu: Double,
    val pir: Boolean, val snd: Boolean, val light: Boolean, val line: Boolean
)

suspend fun fetch(ip: String): Reading = withContext(Dispatchers.IO) {
    val c = URL("http://$ip/api").openConnection() as HttpURLConnection
    try {
        c.connectTimeout = 2000
        c.readTimeout = 2000
        val j = JSONObject(c.inputStream.bufferedReader().readText())
        Reading(
            j.optDouble("t"), j.optDouble("h"), j.optDouble("td"),
            j.optInt("mq"), j.optInt("water"), j.optDouble("mpu"),
            j.optInt("pir") == 1, j.optInt("snd") == 1, j.optInt("light") == 1, j.optInt("line") == 1
        )
    } finally {
        c.disconnect()
    }
}

fun fake() = Reading(
    28 + Random.nextDouble() * 3, 60 + Random.nextDouble() * 10, 27 + Random.nextDouble() * 2,
    if (Random.nextInt(15) == 0) 1500 else 300 + Random.nextInt(80),
    Random.nextInt(500, 1500), Random.nextDouble() * 0.1,
    Random.nextInt(8) == 0, Random.nextInt(10) == 0, false, false
)

fun alertsOf(r: Reading, mqBase: Int, away: Boolean): List<String> = buildList {
    if (r.mq - mqBase > MQ_DELTA) add("Phát hiện tín hiệu khí/khói bất thường (MQ-2) - cần kiểm tra")
    if (r.t > TEMP_MAX || r.td > TEMP_MAX) add("Nhiệt độ cao bất thường")
    if (r.h > HUM_MAX) add("Độ ẩm cao bất thường")
    if (r.water > WATER_MAX) add("Mực nước vượt ngưỡng")
    if (r.mpu > MPU_MAX) add("Phát hiện rung/nghiêng/va chạm (MPU)")
    if (away && r.pir && r.snd) add("Vắng nhà: có chuyển động và tiếng động - hãy kiểm tra camera")
}

fun now(): String = SimpleDateFormat("dd/MM HH:mm:ss", Locale.getDefault()).format(Date())
fun fmt(d: Double) = if (d.isNaN()) "--" else "%.1f".format(d)
fun yn(b: Boolean) = if (b) "CÓ" else "Bình thường"

// Lưu lịch sử sự kiện vào SharedPreferences (mỗi dòng 1 sự kiện, mới nhất ở đầu)
class Store(ctx: Context) {
    private val sp = ctx.getSharedPreferences("nhacanh", Context.MODE_PRIVATE)
    fun load(): List<String> = sp.getString("log", "")!!.split("\n").filter { it.isNotBlank() }
    fun save(l: List<String>) = sp.edit().putString("log", l.take(200).joinToString("\n")).apply()
}

// Thông báo chỉ hoạt động khi app đang mở (chưa có service chạy nền)
@Suppress("DEPRECATION")
fun pushAlert(ctx: Context, text: String) {
    if (Build.VERSION.SDK_INT >= 33 &&
        ctx.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
    ) return
    val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    val b = if (Build.VERSION.SDK_INT >= 26) {
        nm.createNotificationChannel(
            NotificationChannel("nhacanh", "Cảnh báo NHÀ CANH", NotificationManager.IMPORTANCE_HIGH)
        )
        Notification.Builder(ctx, "nhacanh")
    } else Notification.Builder(ctx)
    nm.notify(Random.nextInt(), b.setSmallIcon(android.R.drawable.ic_dialog_alert)
        .setContentTitle("NHÀ CANH").setContentText(text).build())
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { MaterialTheme { Surface { NhaCanhApp() } } }
    }
}

@Composable
fun LineChart(title: String, values: List<Float>, color: Color = Color(0xFF1976D2)) {
    val v = values.filter { !it.isNaN() }
    Text(title, style = MaterialTheme.typography.labelLarge)
    Canvas(Modifier.fillMaxWidth().height(100.dp)) {
        if (v.size < 2) return@Canvas
        val lo = v.minOrNull()!!
        val hi = v.maxOrNull()!!
        val span = if (hi - lo < 1e-3f) 1f else hi - lo
        val p = Path()
        v.forEachIndexed { i, y ->
            val px = size.width * i / (v.size - 1)
            val py = size.height * (1 - (y - lo) / span)
            if (i == 0) p.moveTo(px, py) else p.lineTo(px, py)
        }
        drawPath(p, color, style = Stroke(width = 3f))
    }
    if (v.isNotEmpty()) Text("min %.1f · max %.1f · 60 mẫu gần nhất".format(v.minOrNull()!!, v.maxOrNull()!!))
}

@Composable
fun NhaCanhApp() {
    val ctx = LocalContext.current
    val store = remember { Store(ctx) }
    var ip by remember { mutableStateOf("192.168.1.50") }
    var demo by remember { mutableStateOf(true) }
    var away by remember { mutableStateOf(false) }
    var reading by remember { mutableStateOf<Reading?>(null) }
    var status by remember { mutableStateOf("Chưa kết nối") }
    var alerts by remember { mutableStateOf(listOf<String>()) }
    var photo by remember { mutableStateOf<Bitmap?>(null) }
    var note by remember { mutableStateOf("") }
    var tab by remember { mutableStateOf(0) }
    val hist = remember { mutableStateListOf<Reading>() }
    val log = remember { mutableStateListOf<String>().apply { addAll(store.load()) } }

    fun addLog(s: String) {
        log.add(0, "${now()}  $s")
        while (log.size > 200) log.removeAt(log.lastIndex)
        store.save(log)
    }

    val cam = rememberLauncherForActivityResult(ActivityResultContracts.TakePicturePreview()) {
        photo = it
        if (it != null) addLog("Đã chụp ảnh kiểm tra")
    }
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {}
    LaunchedEffect(Unit) {
        if (Build.VERSION.SDK_INT >= 33) perm.launch(Manifest.permission.POST_NOTIFICATIONS)
    }

    LaunchedEffect(ip, demo, away) {
        val samples = mutableListOf<Int>()
        var base = -1  // giá trị nền MQ-2 = trung bình 10 mẫu đầu
        var prev = setOf<String>()
        while (true) {
            try {
                val r = if (demo) fake() else fetch(ip)
                reading = r
                hist.add(r)
                while (hist.size > 60) hist.removeAt(0)
                status = if (demo) "Chế độ mô phỏng (dữ liệu giả)" else "Đã kết nối $ip"
                if (base < 0) {
                    samples += r.mq
                    if (samples.size >= 10) base = samples.average().toInt()
                }
                val a = alertsOf(r, if (base >= 0) base else r.mq, away)
                alerts = a
                a.filter { it !in prev }.forEach { addLog("⚠ $it"); pushAlert(ctx, it) }
                prev = a.toSet()
            } catch (e: Exception) {
                status = "Lỗi kết nối: ${e.message}"
            }
            delay(2000)
        }
    }

    val tabs = listOf("Tổng quan", "Không khí", "Hoạt động", "Nước", "Camera", "Lịch sử")
    Column(Modifier.fillMaxSize()) {
        Text("NHÀ CANH", style = MaterialTheme.typography.headlineSmall, modifier = Modifier.padding(16.dp, 16.dp, 16.dp, 0.dp))
        Text(status, modifier = Modifier.padding(horizontal = 16.dp))
        ScrollableTabRow(selectedTabIndex = tab, edgePadding = 8.dp) {
            tabs.forEachIndexed { i, t -> Tab(tab == i, { tab = i }, text = { Text(t) }) }
        }
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            val r = reading
            when (tab) {
                0 -> {
                    if (alerts.isEmpty()) Text("✔ Hệ thống bình thường", color = Color(0xFF2E7D32), style = MaterialTheme.typography.titleMedium)
                    alerts.forEach { Text("⚠ $it", color = Color.Red) }
                    OutlinedTextField(ip, { ip = it }, label = { Text("IP của ESP32-S3") }, singleLine = true,
                        modifier = Modifier.fillMaxWidth())
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Switch(demo, { demo = it }); Spacer(Modifier.width(8.dp)); Text("Chế độ mô phỏng")
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Switch(away, { away = it }); Spacer(Modifier.width(8.dp)); Text("Chế độ vắng nhà")
                    }
                    if (r != null) {
                        Text("Nhiệt độ ${fmt(r.t)} °C · Độ ẩm ${fmt(r.h)} %")
                        Text("MQ-2 ${r.mq} · Mực nước ${r.water}")
                        Text("Chuyển động: ${yn(r.pir)}")
                    }
                }
                1 -> {
                    if (r != null) {
                        Text("Nhiệt độ phòng (DHT22): ${fmt(r.t)} °C")
                        Text("Độ ẩm (DHT22): ${fmt(r.h)} %")
                        Text("Nhiệt độ bề mặt (DS18B20): ${fmt(r.td)} °C")
                        Text("MQ-2 (ADC, chưa phải ppm): ${r.mq}")
                    }
                    LineChart("MQ-2 (ADC)", hist.map { it.mq.toFloat() }, Color(0xFFD32F2F))
                    LineChart("Nhiệt độ phòng (°C)", hist.map { it.t.toFloat() }, Color(0xFFF57C00))
                    LineChart("Độ ẩm (%)", hist.map { it.h.toFloat() })
                }
                2 -> if (r != null) {
                    Text("PIR chuyển động: ${yn(r.pir)}")
                    Text("Âm thanh: ${yn(r.snd)}")
                    Text("MPU rung/nghiêng: ${"%.2f".format(r.mpu)} g (ngưỡng $MPU_MAX)")
                    Text("Cảm biến quang: ${r.light}")
                    Text("Dò line: ${r.line}")
                    LineChart("MPU lệch so với 1g", hist.map { it.mpu.toFloat() }, Color(0xFF7B1FA2))
                }
                3 -> if (r != null) {
                    Text("Mực nước (ADC): ${r.water}  ·  ngưỡng cảnh báo $WATER_MAX")
                    Text(if (r.water > WATER_MAX) "⚠ Vượt ngưỡng" else "Ổn định",
                        color = if (r.water > WATER_MAX) Color.Red else Color(0xFF2E7D32))
                    LineChart("Mực nước (ADC)", hist.map { it.water.toFloat() })
                }
                4 -> {
                    Button({ cam.launch(null) }) { Text("Mở camera điện thoại") }
                    photo?.let { Image(it.asImageBitmap(), "Ảnh kiểm tra", Modifier.fillMaxWidth()) }
                    OutlinedTextField(note, { note = it }, label = { Text("Ghi chú sự kiện") }, modifier = Modifier.fillMaxWidth())
                    Button({ if (note.isNotBlank()) { addLog("Ghi chú: $note"); note = "" } }) { Text("Lưu ghi chú vào lịch sử") }
                    Text("Nếu nghi có khí/khói: rời khỏi khu vực, không vào kiểm tra hay quay phim.")
                }
                5 -> {
                    Button({ log.clear(); store.save(log) }) { Text("Xóa lịch sử") }
                    if (log.isEmpty()) Text("Chưa có sự kiện")
                    log.forEach { Text(it) }
                }
                else -> {}
            }
        }
    }
}
