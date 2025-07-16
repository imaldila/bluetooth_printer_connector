import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluetooth_printer_connector_method_channel.dart';

/// Represents a Bluetooth printer device
class BluetoothPrinter {
  final String name;
  final String address;
  final bool isConnected;

  BluetoothPrinter({
    required this.name,
    required this.address,
    this.isConnected = false,
  });

  @override
  String toString() =>
      'BluetoothPrinter(name: $name, address: $address, isConnected: $isConnected)';
}

/// Connection state enum
enum BluetoothConnectionState { disconnected, connecting, connected, error }

abstract class BluetoothPrinterConnectorPlatform extends PlatformInterface {
  /// Constructs a BluetoothPrinterConnectorPlatform.
  BluetoothPrinterConnectorPlatform() : super(token: _token);

  static final Object _token = Object();

  static BluetoothPrinterConnectorPlatform _instance =
      MethodChannelBluetoothPrinterConnector();

  /// The default instance of [BluetoothPrinterConnectorPlatform] to use.
  ///
  /// Defaults to [MethodChannelBluetoothPrinterConnector].
  static BluetoothPrinterConnectorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BluetoothPrinterConnectorPlatform] when
  /// they register themselves.
  static set instance(BluetoothPrinterConnectorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() {
    throw UnimplementedError('isBluetoothEnabled() has not been implemented.');
  }

  /// Request to enable Bluetooth
  Future<bool> enableBluetooth() {
    throw UnimplementedError('enableBluetooth() has not been implemented.');
  }

  /// Get list of paired/bonded Bluetooth printers
  Future<List<BluetoothPrinter>> getBondedDevices() {
    throw UnimplementedError('getBondedDevices() has not been implemented.');
  }

  /// Start discovery of Bluetooth printers
  Future<void> startDiscovery() {
    throw UnimplementedError('startDiscovery() has not been implemented.');
  }

  /// Stop discovery of Bluetooth printers
  Future<void> stopDiscovery() {
    throw UnimplementedError('stopDiscovery() has not been implemented.');
  }

  /// Connect to a Bluetooth printer
  Future<bool> connect(String address) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  /// Disconnect from current Bluetooth printer
  Future<bool> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  /// Get current connection state
  Future<BluetoothConnectionState> getConnectionState() {
    throw UnimplementedError('getConnectionState() has not been implemented.');
  }

  /// Write data to the connected printer
  Future<bool> write(List<int> data) {
    throw UnimplementedError('write() has not been implemented.');
  }
}
