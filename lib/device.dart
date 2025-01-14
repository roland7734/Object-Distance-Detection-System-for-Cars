import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothDeviceListEntry extends StatelessWidget {
  final VoidCallback onTap;
  final BluetoothDevice device;

  BluetoothDeviceListEntry({required this.onTap, required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.lightBlueAccent,
          child: Icon(Icons.devices, color: Colors.white),
        ),
        title: Text(
          device.name ?? "Unknown device",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          device.address.toString(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: ElevatedButton(
          onPressed: onTap,
          child: Text('Connect'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF6347),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
    );
  }
}