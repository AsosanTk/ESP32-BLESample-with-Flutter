import 'package:esp32_ble_g3theme/main_model.dart';
import 'package:flutter/material.dart';
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

// ignore: must_be_immutable
class HomePage extends StatelessWidget {
  bool searching = false;
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
                Icon(model.isConnected() ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
                Text('Latest Your Body-Temperature'),
                SizedBox(width: 100, height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.ideographic,
                  children: [
                    Text(model.receiveString, style: TextStyle(fontSize: 60, color: Colors.green),),
                    SizedBox(width: 20, height: 40,),
                    Text('deg C', style: TextStyle(fontSize: 25, color: Colors.black))
                  ],
                ),
                SizedBox(width: 100, height: 20,),
                RaisedButton(
                  child: Icon(searching ? Icons.bluetooth_searching_rounded : Icons.bluetooth_disabled_rounded),
                  onPressed: () {
                    if (model.isConnected() == true) {
                      model.disconnect();
                    } else {
                      model.scanDevices();
                    }
                    if (searching) {
                      searching = false;
                    } else {
                      searching = true;
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