# esp32_ble_g3theme

A new Flutter application.

## Getting Started

This project is created for the special class of the 3rd yearof JHS..

## このプロジェクトで行うこと
ESP32でBLEを用いて温度測定結果の情報を送信して、それをアプリで受け取る。アプリにはGoogle社が開発したFlutterというクロスプラットフォームを用いる。

Flutter側では[Flutter_Blue](https://pub.dev/packages/flutter_blue)というプラグインを用いる。

またESP32での体温測定は、GY-906という温度センサを使用している。この際、非接触での計測と実際の体温には多少のずれがある。これは[この記事](http://independence-sys.net/main/?p=5532)を参考にさせていただいた。


A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# ESP32-BLESample-with-Flutter
