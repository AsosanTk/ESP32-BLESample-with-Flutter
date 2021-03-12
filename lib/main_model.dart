import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class MainModel extends ChangeNotifier {

  final _connectToLocalName = 'ESP32';
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final _timeout = 4;
  BluetoothDevice _device;
  BluetoothCharacteristic _notifyCharacteristic;
  String receiveString = 'Nan';
  List<int> receiveRaw = [];


  void scanDevices() {
    flutterBlue.startScan(timeout: Duration(seconds: _timeout));

    // Listen to Scan Results
    var subscription = flutterBlue.scanResults.listen((results) async {
      for (ScanResult r in results) {
        print('${r.device.name} found! rssi: ${r.rssi}');

        if (r.device.name == _connectToLocalName) {
          // Device情報を保持する
          if (_device == null) {
            _device = r.device;
            notifyListeners();
            await connect();
            break;
          }
        }
      }
    });

    flutterBlue.stopScan();
  }

  void connect() async {
    await _device.connect();
    print('Connect!');

    List<BluetoothService> services = await _device.discoverServices();
    services.forEach((service) async {
      service.characteristics.forEach((characteristic) async {
        if (characteristic.properties.notify) {
          _notifyCharacteristic = characteristic;
          await _notifyCharacteristic.setNotifyValue(true);
          _notifyCharacteristic.value.listen((value) {
            receiveRaw = value;
            receiveString = utf8.decode(value);
            print('recevied: ${receiveString}');
            if (receiveString == ' 0.0') receiveString = 'Nan';
            notifyListeners();
          });
          print('notify');
        }
      });
    });
  }

  void disconnect() {
    _device.disconnect();
    _device = null;
    _notifyCharacteristic = null;
    print('Disconnect');
    notifyListeners();
  }

  bool isConnected() {
    if (_device == null) return false;
    return true;
  }
}
