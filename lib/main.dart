import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 BLE',
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MainModel>(
      create: (_) => MainModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Temp-ESP32-BLE'),
        ),
        body: Consumer<MainModel>(builder: (context, model, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Latest Your Body-Temperature'),
                Text(model.receiveString, style: TextStyle(fontSize: 40, color: Colors.blue),),
                RaisedButton(
                  child: Icon(model.isConnected() ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
                  onPressed: () {
                    if (model.isConnected() == true) {
                      model.disconnect();
                    } else {
                      model.scanDevices();
                    }
                  },
                ),
              ]
            ),
          );
        },),
      )
    );
  }
}



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
