// import 'package:flutter_test/flutter_test.dart';
// import 'package:bluetooth_printer_connector/bluetooth_printer_connector.dart';
// import 'package:bluetooth_printer_connector/bluetooth_printer_connector_platform_interface.dart';
// import 'package:bluetooth_printer_connector/bluetooth_printer_connector_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockBluetoothPrinterConnectorPlatform
//     with MockPlatformInterfaceMixin
//     implements BluetoothPrinterConnectorPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final BluetoothPrinterConnectorPlatform initialPlatform = BluetoothPrinterConnectorPlatform.instance;

//   test('$MethodChannelBluetoothPrinterConnector is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelBluetoothPrinterConnector>());
//   });

//   test('getPlatformVersion', () async {
//     BluetoothPrinterConnector bluetoothPrinterConnectorPlugin = BluetoothPrinterConnector();
//     MockBluetoothPrinterConnectorPlatform fakePlatform = MockBluetoothPrinterConnectorPlatform();
//     BluetoothPrinterConnectorPlatform.instance = fakePlatform;

//     expect(await bluetoothPrinterConnectorPlugin.getPlatformVersion(), '42');
//   });
// }
