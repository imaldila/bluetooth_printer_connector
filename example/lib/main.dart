import 'dart:async';

import 'package:bluetooth_printer_connector/bluetooth_printer_connector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const BluetoothPrinterDemo(),
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
    );
  }
}

class BluetoothPrinterDemo extends StatefulWidget {
  const BluetoothPrinterDemo({super.key});

  @override
  State<BluetoothPrinterDemo> createState() => _BluetoothPrinterDemoState();
}

class _BluetoothPrinterDemoState extends State<BluetoothPrinterDemo> {
  final BluetoothPrinterConnector _bluetooth = BluetoothPrinterConnector();
  List<BluetoothPrinter> _devices = [];
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  String? _connectedDeviceAddress;
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    try {
      bool isEnabled = await _bluetooth.isBluetoothEnabled();
      if (!isEnabled) {
        bool enabled = await _bluetooth.enableBluetooth();
        if (!enabled) {
          _showSnackBar('Please enable Bluetooth to use this app');
          return;
        }
      }
      await _getBondedDevices();
    } on PlatformException catch (e) {
      _showSnackBar('Error initializing Bluetooth: ${e.message}');
    }
  }

  Future<void> _getBondedDevices() async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      setState(() {
        _devices = devices;
      });
    } on PlatformException catch (e) {
      _showSnackBar('Error getting bonded devices: ${e.message}');
    }
  }

  Future<void> _startDiscovery() async {
    try {
      setState(() {
        _isDiscovering = true;
      });
      await _bluetooth.startDiscovery();
    } on PlatformException catch (e) {
      _showSnackBar('Error starting discovery: ${e.message}');
    }
  }

  Future<void> _stopDiscovery() async {
    try {
      await _bluetooth.stopDiscovery();
      setState(() {
        _isDiscovering = false;
      });
    } on PlatformException catch (e) {
      _showSnackBar('Error stopping discovery: ${e.message}');
    }
  }

  Future<void> _connectToDevice(String address) async {
    try {
      bool connected = await _bluetooth.connect(address);
      if (connected) {
        setState(() {
          _connectionState = BluetoothConnectionState.connected;
          _connectedDeviceAddress = address;
        });
        _showSnackBar('Connected successfully');
      } else {
        _showSnackBar('Failed to connect');
      }
    } on PlatformException catch (e) {
      _showSnackBar('Error connecting to device: ${e.message}');
    }
  }

  Future<void> _disconnect() async {
    try {
      bool disconnected = await _bluetooth.disconnect();
      if (disconnected) {
        setState(() {
          _connectionState = BluetoothConnectionState.disconnected;
          _connectedDeviceAddress = null;
        });
        _showSnackBar('Disconnected successfully');
      } else {
        _showSnackBar('Failed to disconnect');
      }
    } on PlatformException catch (e) {
      _showSnackBar('Error disconnecting: ${e.message}');
    }
  }

  Future<void> _printTestPage() async {
    if (_connectionState != BluetoothConnectionState.connected) {
      _showSnackBar('Please connect to a printer first');
      return;
    }

    try {
      // Example ESC/POS commands for test print
      // Different printers may require different commands
      List<int> bytes = [
        0x1B, 0x40, // Initialize printer
        0x1B, 0x21, 0x00, // Normal text
        ...('Test Print\n').codeUnits,
        ...('----------------\n').codeUnits,
        ...('Hello from Flutter!\n').codeUnits,
        0x1B, 0x64, 0x02, // Feed 2 lines
        0x1D, 0x56, 0x41, 0x00, // Cut paper
      ];

      bool success = await _bluetooth.write(bytes);
      if (success) {
        _showSnackBar('Test page printed successfully');
      } else {
        _showSnackBar('Failed to print test page');
      }
    } on PlatformException catch (e) {
      _showSnackBar('Error printing: ${e.message}');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Printer Demo'),
        actions: [
          IconButton(
            icon: Icon(_isDiscovering ? Icons.stop : Icons.search),
            onPressed: _isDiscovering ? _stopDiscovery : _startDiscovery,
            tooltip: _isDiscovering ? 'Stop Discovery' : 'Start Discovery',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getBondedDevices,
            tooltip: 'Refresh Devices',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  _connectionState == BluetoothConnectionState.connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color:
                      _connectionState == BluetoothConnectionState.connected
                          ? Colors.green
                          : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Status: ${_connectionState.toString().split('.').last}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_connectionState == BluetoothConnectionState.connected)
                  ElevatedButton(
                    onPressed: _disconnect,
                    child: const Text('Disconnect'),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                final isConnected = device.address == _connectedDeviceAddress;
                return ListTile(
                  leading: Icon(
                    isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                    color: isConnected ? Colors.green : Colors.blue,
                  ),
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  trailing: ElevatedButton(
                    onPressed:
                        isConnected
                            ? null
                            : () => _connectToDevice(device.address),
                    child: Text(isConnected ? 'Connected' : 'Connect'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          _connectionState == BluetoothConnectionState.connected
              ? FloatingActionButton.extended(
                onPressed: _printTestPage,
                label: const Text('Print Test Page'),
                icon: const Icon(Icons.print),
              )
              : null,
    );
  }
}
