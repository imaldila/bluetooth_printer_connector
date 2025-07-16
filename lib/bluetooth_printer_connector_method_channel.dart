import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bluetooth_printer_connector_platform_interface.dart';

/// An implementation of [BluetoothPrinterConnectorPlatform] that uses method channels.
class MethodChannelBluetoothPrinterConnector
    extends BluetoothPrinterConnectorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bluetooth_printer_connector');

  @override
  Future<bool> isBluetoothEnabled() async {
    final bool enabled = await methodChannel.invokeMethod('isBluetoothEnabled');
    return enabled;
  }

  @override
  Future<bool> enableBluetooth() async {
    final bool success = await methodChannel.invokeMethod('enableBluetooth');
    return success;
  }

  @override
  Future<List<BluetoothPrinter>> getBondedDevices() async {
    final List<dynamic> devices = await methodChannel.invokeMethod(
      'getBondedDevices',
    );
    return devices
        .map(
          (device) => BluetoothPrinter(
            name: device['name'] as String,
            address: device['address'] as String,
            isConnected: device['isConnected'] as bool? ?? false,
          ),
        )
        .toList();
  }

  @override
  Future<void> startDiscovery() async {
    await methodChannel.invokeMethod('startDiscovery');
  }

  @override
  Future<void> stopDiscovery() async {
    await methodChannel.invokeMethod('stopDiscovery');
  }

  @override
  Future<bool> connect(String address) async {
    final bool success = await methodChannel.invokeMethod('connect', {
      'address': address,
    });
    return success;
  }

  @override
  Future<bool> disconnect() async {
    final bool success = await methodChannel.invokeMethod('disconnect');
    return success;
  }

  @override
  Future<BluetoothConnectionState> getConnectionState() async {
    final String state = await methodChannel.invokeMethod('getConnectionState');
    return BluetoothConnectionState.values.firstWhere(
      (e) => e.toString().split('.').last == state,
      orElse: () => BluetoothConnectionState.disconnected,
    );
  }

  @override
  Future<bool> write(List<int> data) async {
    final bool success = await methodChannel.invokeMethod('write', {
      'data': data,
    });
    return success;
  }
}
