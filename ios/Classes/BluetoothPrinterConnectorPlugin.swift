import Flutter
import UIKit
import CoreBluetooth

public class BluetoothPrinterConnectorPlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var channel: FlutterMethodChannel
    private var discoveredPeripherals: [CBPeripheral] = []
    private var pendingResult: FlutterResult?
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "bluetooth_printer_connector", binaryMessenger: registrar.messenger())
        let instance = BluetoothPrinterConnectorPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isBluetoothEnabled":
            result(centralManager.state == .poweredOn)
            
        case "enableBluetooth":
            // iOS doesn't allow programmatic Bluetooth enabling
            result(false)
            
        case "getBondedDevices":
            // iOS doesn't have concept of bonded devices
            result([])
            
        case "startDiscovery":
            discoveredPeripherals.removeAll()
            centralManager.scanForPeripherals(withServices: nil)
            result(nil)
            
        case "stopDiscovery":
            centralManager.stopScan()
            result(nil)
            
        case "connect":
            guard let args = call.arguments as? [String: Any],
                  let address = args["address"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT",
                                  message: "Device address is required",
                                  details: nil))
                return
            }
            
            guard let peripheral = discoveredPeripherals.first(where: { $0.identifier.uuidString == address }) else {
                result(FlutterError(code: "DEVICE_NOT_FOUND",
                                  message: "Device not found",
                                  details: nil))
                return
            }
            
            self.peripheral = peripheral
            self.pendingResult = result
            centralManager.connect(peripheral, options: nil)
            
        case "disconnect":
            if let peripheral = peripheral {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            peripheral = nil
            writeCharacteristic = nil
            result(true)
            
        case "getConnectionState":
            guard let peripheral = peripheral else {
                result("disconnected")
                return
            }
            
            switch peripheral.state {
            case .connected:
                result("connected")
            case .connecting:
                result("connecting")
            default:
                result("disconnected")
            }
            
        case "write":
            guard let args = call.arguments as? [String: Any],
                  let data = args["data"] as? [UInt8] else {
                result(FlutterError(code: "INVALID_ARGUMENT",
                                  message: "Data is required",
                                  details: nil))
                return
            }
            
            guard let peripheral = peripheral,
                  peripheral.state == .connected,
                  let characteristic = writeCharacteristic else {
                result(FlutterError(code: "NOT_CONNECTED",
                                  message: "Printer is not connected",
                                  details: nil))
                return
            }
            
            peripheral.writeValue(Data(data),
                                for: characteristic,
                                type: .withResponse)
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Bluetooth is on
        }
    }
    
    public func centralManager(_ central: CBCentralManager,
                             didDiscover peripheral: CBPeripheral,
                             advertisementData: [String : Any],
                             rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
            let deviceData: [String: Any] = [
                "name": peripheral.name ?? "Unknown",
                "address": peripheral.identifier.uuidString,
                "isConnected": false
            ]
            channel.invokeMethod("onDeviceFound", arguments: deviceData)
        }
    }
    
    public func centralManager(_ central: CBCentralManager,
                             didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    public func centralManager(_ central: CBCentralManager,
                             didDisconnectPeripheral peripheral: CBPeripheral,
                             error: Error?) {
        if peripheral == self.peripheral {
            self.peripheral = nil
            self.writeCharacteristic = nil
            channel.invokeMethod("onConnectionStateChanged", arguments: "disconnected")
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    public func peripheral(_ peripheral: CBPeripheral,
                         didDiscoverServices error: Error?) {
        guard error == nil else {
            pendingResult?(FlutterError(code: "SERVICE_DISCOVERY_FAILED",
                                      message: error?.localizedDescription ?? "Unknown error",
                                      details: nil))
            return
        }
        
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                         didDiscoverCharacteristicsFor service: CBService,
                         error: Error?) {
        guard error == nil else {
            pendingResult?(FlutterError(code: "CHARACTERISTIC_DISCOVERY_FAILED",
                                      message: error?.localizedDescription ?? "Unknown error",
                                      details: nil))
            return
        }
        
        for characteristic in service.characteristics ?? [] {
            if characteristic.properties.contains(.write) ||
                characteristic.properties.contains(.writeWithoutResponse) {
                writeCharacteristic = characteristic
                pendingResult?(true)
                pendingResult = nil
                channel.invokeMethod("onConnectionStateChanged", arguments: "connected")
                return
            }
        }
        
        pendingResult?(FlutterError(code: "NO_WRITE_CHARACTERISTIC",
                                  message: "No writable characteristic found",
                                  details: nil))
        pendingResult = nil
    }
}
