#ifndef FLUTTER_PLUGIN_BLUETOOTH_PRINTER_CONNECTOR_PLUGIN_H_
#define FLUTTER_PLUGIN_BLUETOOTH_PRINTER_CONNECTOR_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace bluetooth_printer_connector {

class BluetoothPrinterConnectorPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  BluetoothPrinterConnectorPlugin();

  virtual ~BluetoothPrinterConnectorPlugin();

  // Disallow copy and assign.
  BluetoothPrinterConnectorPlugin(const BluetoothPrinterConnectorPlugin&) = delete;
  BluetoothPrinterConnectorPlugin& operator=(const BluetoothPrinterConnectorPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace bluetooth_printer_connector

#endif  // FLUTTER_PLUGIN_BLUETOOTH_PRINTER_CONNECTOR_PLUGIN_H_
