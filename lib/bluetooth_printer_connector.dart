import 'bluetooth_printer_connector_platform_interface.dart';

export 'bluetooth_printer_connector_platform_interface.dart'
    show BluetoothPrinter, BluetoothConnectionState;

class BluetoothPrinterConnector {
  Future<bool> isBluetoothEnabled() {
    return BluetoothPrinterConnectorPlatform.instance.isBluetoothEnabled();
  }

  Future<bool> enableBluetooth() {
    return BluetoothPrinterConnectorPlatform.instance.enableBluetooth();
  }

  Future<List<BluetoothPrinter>> getBondedDevices() {
    return BluetoothPrinterConnectorPlatform.instance.getBondedDevices();
  }

  Future<void> startDiscovery() {
    return BluetoothPrinterConnectorPlatform.instance.startDiscovery();
  }

  Future<void> stopDiscovery() {
    return BluetoothPrinterConnectorPlatform.instance.stopDiscovery();
  }

  Future<bool> connect(String address) {
    return BluetoothPrinterConnectorPlatform.instance.connect(address);
  }

  Future<bool> disconnect() {
    return BluetoothPrinterConnectorPlatform.instance.disconnect();
  }

  Future<BluetoothConnectionState> getConnectionState() {
    return BluetoothPrinterConnectorPlatform.instance.getConnectionState();
  }

  Future<bool> write(List<int> data) {
    return BluetoothPrinterConnectorPlatform.instance.write(data);
  }
}
