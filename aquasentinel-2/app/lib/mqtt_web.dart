import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

// Trình duyệt chỉ kết nối được qua WebSocket (HiveMQ: wss://broker.hivemq.com:8884/mqtt)
MqttClient makeClient(String host, String id) => MqttBrowserClient('wss://$host/mqtt', id)..port = 8884;
