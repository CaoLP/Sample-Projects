package com.example.nhacanh  // đổi theo package của project

import android.graphics.Bitmap
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
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

fun now(): String = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
fun fmt(d: Double) = if (d.isNaN()) "--" else "%.1f".format(d)
fun yn(b: Boolean) = if (b) "CÓ" else "Bình thường"

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { MaterialTheme { Surface { NhaCanhScreen() } } }
    }
}

@Composable
fun NhaCanhScreen() {
    var ip by remember { mutableStateOf("192.168.1.50") }
    var demo by remember { mutableStateOf(true) }
    var away by remember { mutableStateOf(false) }
    var reading by remember { mutableStateOf<Reading?>(null) }
    var status by remember { mutableStateOf("Chưa kết nối") }
    var alerts by remember { mutableStateOf(listOf<String>()) }
    var photo by remember { mutableStateOf<Bitmap?>(null) }
    val log = remember { mutableStateListOf<String>() }
    val cam = rememberLauncherForActivityResult(ActivityResultContracts.TakePicturePreview()) {
        photo = it
        if (it != null) log.add(0, "${now()} Đã chụp ảnh kiểm tra")
    }

    LaunchedEffect(ip, demo, away) {
        val samples = mutableListOf<Int>()
        var base = -1  // giá trị nền MQ-2 = trung bình 10 mẫu đầu
        var prev = setOf<String>()
        while (true) {
            try {
                val r = if (demo) fake() else fetch(ip)
                reading = r
                status = if (demo) "Chế độ mô phỏng (dữ liệu giả)" else "Đã kết nối $ip"
                if (base < 0) {
                    samples += r.mq
                    if (samples.size >= 10) base = samples.average().toInt()
                }
                val a = alertsOf(r, if (base >= 0) base else r.mq, away)
                alerts = a
                a.filter { it !in prev }.forEach { log.add(0, "${now()} $it") }
                while (log.size > 100) log.removeAt(log.lastIndex)
                prev = a.toSet()
            } catch (e: Exception) {
                status = "Lỗi kết nối: ${e.message}"
            }
            delay(2000)
        }
    }

    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text("NHÀ CANH", style = MaterialTheme.typography.headlineMedium)
        Text(status)
        OutlinedTextField(ip, { ip = it }, label = { Text("IP của ESP32-S3") }, singleLine = true,
            modifier = Modifier.fillMaxWidth())
        Row(verticalAlignment = Alignment.CenterVertically) {
            Switch(demo, { demo = it }); Spacer(Modifier.width(8.dp)); Text("Chế độ mô phỏng")
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Switch(away, { away = it }); Spacer(Modifier.width(8.dp)); Text("Chế độ vắng nhà")
        }
        alerts.forEach { Text("⚠ $it", color = Color.Red) }

        reading?.let { r ->
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(12.dp)) {
                    Text("Môi trường", style = MaterialTheme.typography.titleMedium)
                    Text("Nhiệt độ phòng (DHT22): ${fmt(r.t)} °C")
                    Text("Độ ẩm (DHT22): ${fmt(r.h)} %")
                    Text("Nhiệt độ bề mặt (DS18B20): ${fmt(r.td)} °C")
                    Text("MQ-2 (ADC, chưa phải ppm): ${r.mq}")
                    Text("Mực nước (ADC): ${r.water}")
                }
            }
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(12.dp)) {
                    Text("Hoạt động", style = MaterialTheme.typography.titleMedium)
                    Text("PIR chuyển động: ${yn(r.pir)}")
                    Text("Âm thanh: ${yn(r.snd)}")
                    Text("MPU rung/nghiêng: ${"%.2f".format(r.mpu)} g")
                    Text("Cảm biến quang: ${r.light}  ·  Dò line: ${r.line}")
                }
            }
        }

        Button({ cam.launch(null) }) { Text("Mở camera điện thoại để kiểm tra") }
        photo?.let { Image(it.asImageBitmap(), "Ảnh kiểm tra", Modifier.fillMaxWidth()) }

        Text("Nhật ký sự kiện", style = MaterialTheme.typography.titleMedium)
        if (log.isEmpty()) Text("Chưa có sự kiện")
        log.take(15).forEach { Text(it) }
    }
}
