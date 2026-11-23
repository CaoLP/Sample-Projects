import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient makeClient(String host, String id) => MqttServerClient(host, id)..port = 1883;
