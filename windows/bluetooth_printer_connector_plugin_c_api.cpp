#include "include/bluetooth_printer_connector/bluetooth_printer_connector_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "bluetooth_printer_connector_plugin.h"

void BluetoothPrinterConnectorPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  bluetooth_printer_connector::BluetoothPrinterConnectorPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
