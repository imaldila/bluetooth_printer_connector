#include "bluetooth_printer_connector_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>

#include <windows.h>
#include <bluetoothapis.h>
#include <bthsdpdef.h>
#include <ws2bth.h>

#pragma comment(lib, "Bthprops.lib")

namespace {

class BluetoothPrinterConnectorPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  BluetoothPrinterConnectorPlugin();

  virtual ~BluetoothPrinterConnectorPlugin();

 private:
  SOCKET socket_ = INVALID_SOCKET;
  bool is_connected_ = false;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  bool InitializeWinsock();
  void CleanupWinsock();
  std::vector<flutter::EncodableValue> GetBondedDevices();
  bool ConnectToPrinter(const std::string& address);
  bool DisconnectPrinter();
  bool WriteToPrinter(const std::vector<uint8_t>& data);
};

void BluetoothPrinterConnectorPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "bluetooth_printer_connector",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<BluetoothPrinterConnectorPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

BluetoothPrinterConnectorPlugin::BluetoothPrinterConnectorPlugin() {
  InitializeWinsock();
}

BluetoothPrinterConnectorPlugin::~BluetoothPrinterConnectorPlugin() {
  DisconnectPrinter();
  CleanupWinsock();
}

bool BluetoothPrinterConnectorPlugin::InitializeWinsock() {
  WSADATA wsa_data;
  return (WSAStartup(MAKEWORD(2, 2), &wsa_data) == 0);
}

void BluetoothPrinterConnectorPlugin::CleanupWinsock() {
  WSACleanup();
}

std::vector<flutter::EncodableValue> BluetoothPrinterConnectorPlugin::GetBondedDevices() {
  std::vector<flutter::EncodableValue> devices;
  BLUETOOTH_DEVICE_SEARCH_PARAMS search_params = {
    sizeof(BLUETOOTH_DEVICE_SEARCH_PARAMS),
    1,  // Return authenticated devices
    0,  // Return remembered devices
    1,  // Return unknown devices
    1,  // Return connected devices
    1,  // Issue inquiry
    8   // Timeout multiplier
  };

  BLUETOOTH_DEVICE_INFO device_info = { sizeof(BLUETOOTH_DEVICE_INFO) };
  HBLUETOOTH_DEVICE_FIND device = BluetoothFindFirstDevice(&search_params, &device_info);

  if (device) {
    do {
      std::wstring name(device_info.szName);
      std::string device_name(name.begin(), name.end());
      
      std::stringstream address;
      address << std::hex << std::uppercase
              << (int)device_info.Address.rgBytes[5] << ":"
              << (int)device_info.Address.rgBytes[4] << ":"
              << (int)device_info.Address.rgBytes[3] << ":"
              << (int)device_info.Address.rgBytes[2] << ":"
              << (int)device_info.Address.rgBytes[1] << ":"
              << (int)device_info.Address.rgBytes[0];

      flutter::EncodableMap device_map;
      device_map[flutter::EncodableValue("name")] = flutter::EncodableValue(device_name);
      device_map[flutter::EncodableValue("address")] = flutter::EncodableValue(address.str());
      device_map[flutter::EncodableValue("isConnected")] = flutter::EncodableValue(false);
      
      devices.push_back(flutter::EncodableValue(device_map));
    } while (BluetoothFindNextDevice(device, &device_info));

    BluetoothFindDeviceClose(device);
  }

  return devices;
}

bool BluetoothPrinterConnectorPlugin::ConnectToPrinter(const std::string& address) {
  if (is_connected_) {
    DisconnectPrinter();
  }

  SOCKADDR_BTH sock_addr = { 0 };
  sock_addr.addressFamily = AF_BTH;
  
  // Convert address string to BTH_ADDR
  std::stringstream ss;
  ss << std::hex << address;
  ss >> sock_addr.btAddr;

  // Serial Port Profile UUID
  GUID spp_uuid = { 0x00001101, 0x0000, 0x1000, { 0x80, 0x00, 0x00, 0x80, 0x5F, 0x9B, 0x34, 0xFB } };
  sock_addr.serviceClassId = spp_uuid;
  sock_addr.port = BT_PORT_ANY;

  socket_ = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
  if (socket_ == INVALID_SOCKET) {
    return false;
  }

  if (connect(socket_, (SOCKADDR*)&sock_addr, sizeof(sock_addr)) == SOCKET_ERROR) {
    closesocket(socket_);
    socket_ = INVALID_SOCKET;
    return false;
  }

  is_connected_ = true;
  return true;
}

bool BluetoothPrinterConnectorPlugin::DisconnectPrinter() {
  if (socket_ != INVALID_SOCKET) {
    closesocket(socket_);
    socket_ = INVALID_SOCKET;
  }
  is_connected_ = false;
  return true;
}

bool BluetoothPrinterConnectorPlugin::WriteToPrinter(const std::vector<uint8_t>& data) {
  if (!is_connected_ || socket_ == INVALID_SOCKET) {
    return false;
  }

  int bytes_sent = send(socket_, (char*)data.data(), data.size(), 0);
  return bytes_sent == data.size();
}

void BluetoothPrinterConnectorPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() == "isBluetoothEnabled") {
    BLUETOOTH_RADIO_INFO radio_info = { sizeof(BLUETOOTH_RADIO_INFO) };
    HANDLE radio;
    HBLUETOOTH_RADIO_FIND find = BluetoothFindFirstRadio(nullptr, &radio);
    bool enabled = find != nullptr;
    if (find) {
      BluetoothFindRadioClose(find);
      CloseHandle(radio);
    }
    result->Success(flutter::EncodableValue(enabled));
  } else if (method_call.method_name() == "enableBluetooth") {
    // Windows doesn't support programmatically enabling Bluetooth
    result->Success(flutter::EncodableValue(false));
  } else if (method_call.method_name() == "getBondedDevices") {
    auto devices = GetBondedDevices();
    result->Success(flutter::EncodableValue(devices));
  } else if (method_call.method_name() == "startDiscovery") {
    // Windows doesn't support continuous discovery
    // We'll return the current devices instead
    result->Success();
  } else if (method_call.method_name() == "stopDiscovery") {
    result->Success();
  } else if (method_call.method_name() == "connect") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto address_it = arguments->find(flutter::EncodableValue("address"));
      if (address_it != arguments->end()) {
        const auto* address = std::get_if<std::string>(&address_it->second);
        if (address) {
          bool success = ConnectToPrinter(*address);
          result->Success(flutter::EncodableValue(success));
          return;
        }
      }
    }
    result->Error("INVALID_ARGUMENT", "Device address is required");
  } else if (method_call.method_name() == "disconnect") {
    bool success = DisconnectPrinter();
    result->Success(flutter::EncodableValue(success));
  } else if (method_call.method_name() == "getConnectionState") {
    std::string state = is_connected_ ? "connected" : "disconnected";
    result->Success(flutter::EncodableValue(state));
  } else if (method_call.method_name() == "write") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto data_it = arguments->find(flutter::EncodableValue("data"));
      if (data_it != arguments->end()) {
        const auto* data = std::get_if<std::vector<uint8_t>>(&data_it->second);
        if (data) {
          bool success = WriteToPrinter(*data);
          result->Success(flutter::EncodableValue(success));
          return;
        }
      }
    }
    result->Error("INVALID_ARGUMENT", "Data is required");
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void BluetoothPrinterConnectorPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  BluetoothPrinterConnectorPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
