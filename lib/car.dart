import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'car_image.dart';

class ParkingSensorPage extends StatefulWidget {
  final BluetoothDevice server;

  const ParkingSensorPage({required this.server});

  @override
  _ParkingSensorPageState createState() => _ParkingSensorPageState();
}

class _ParkingSensorPageState extends State<ParkingSensorPage> {
  late BluetoothConnection connection;
  bool isConnecting = true;
  bool isDisconnecting = false;

  String message = '';

  String frontDistance = "N/A";
  String rearDistance = "N/A";

  String _messageBuffer = '';

  static const double MAX_DISTANCE = 100;


  @override
  void initState() {
    super.initState();
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input?.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print("Disconnecting locally!");
        } else {
          print("Disconnected remotely!");
        }
        if (mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print("Cannot connect, exception occurred");
      print(error);
    });
  }

  @override
  void dispose() {
    if (connection.isConnected) {
      isDisconnecting = true;
      connection.dispose();
    }
    super.dispose();
  }


  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        message =
            backspacesCounter > 0
                ? _messageBuffer.substring(
                0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index);
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
          0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }

    parseRearAndFrontDistance(message);

  }

  void parseRearAndFrontDistance(String dataString) {

    RegExp frontRegExp = RegExp(r"Front:\s*([\d\.]+)\s*cm");
    RegExp rearRegExp = RegExp(r"Rear:\s*([\d\.]+)\s*cm");

    // Try to find matches for the front and rear distances
    Match? frontMatch = frontRegExp.firstMatch(dataString);
    Match? rearMatch = rearRegExp.firstMatch(dataString);

    if (frontMatch != null && rearMatch != null) {
      // Extract front and rear distances from the matched groups
      String frontDistance = frontMatch.group(1)!;
      String rearDistance = rearMatch.group(1)!;

      // Update the front and rear distances
      setState(() {
        this.frontDistance = (frontDistance);
        this.rearDistance = (rearDistance);
      });
    }
  }


  double _calculateDistancePosition(String distance) {
    double distanceValue = double.tryParse(distance) ?? 0;
    double position = -100;
    if(distanceValue > MAX_DISTANCE) position = -100;
    else position =  -220/MAX_DISTANCE * distanceValue + 220;
    return position;
  }

  @override
  Widget build(BuildContext context) {

    final double carImageHeight = 250;

    double frontIndicatorTop = _calculateDistancePosition(frontDistance);
    double rearIndicatorBottom = _calculateDistancePosition(rearDistance);


    if (isConnecting || frontDistance == 'N/A' || rearDistance == 'N/A') {
      return Scaffold(
        appBar: AppBar(title: Text("Connecting...",
          style: TextStyle(
            fontFamily: 'CocoGothic',
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          )),
        backgroundColor: Colors.lightBlueAccent,),
        body: Center(child: CircularProgressIndicator()),
      );
    }



    // double frontIndicatorTop = 220;
    // 0 -> TOP OF THE SCREEN
    // 220 -> top od the image
    // double rearIndicatorBottom = 220;
    // 0-> bottom of the screen
    // 220 -> bottom of the car



      return Scaffold(
          appBar: AppBar(title: Text('Parking Sensor',
            style: TextStyle(
              fontFamily: 'CocoGothic',
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),),
              backgroundColor: Colors.lightBlueAccent),

          body: Center(
            child:
              Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  color: Colors.transparent,
                  height: MediaQuery.of(context).size.height,
                  width: double.infinity,
                ),
                buildCarImage(carImageHeight),

                AnimatedPositioned(
                  duration: Duration(milliseconds: 500),
                  top: frontIndicatorTop,
                  child: _buildFrontDistanceIndicator(),
                  curve: Curves.linear,
                ),

                // Rear Indicator positioned below the car
                AnimatedPositioned(
                  duration: Duration(milliseconds: 500),
                  bottom: rearIndicatorBottom,
                  child: _buildRearDistanceIndicator(),
                  curve: Curves.linear,
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text("Front Distance: $frontDistance cm" , style: TextStyle(fontSize: 18)),
                      Text("Rear Distance: $rearDistance cm", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),

              ],
            ),



          ),
        );

  }
  Widget _buildFrontDistanceIndicator(){
    return _buildDistanceIndicator(distance: frontDistance, direction: 'Front');
  }
  Widget _buildRearDistanceIndicator(){
    return _buildDistanceIndicator(distance: rearDistance, direction: 'Rear');
  }

  Widget _buildDistanceIndicator({required String distance, required String direction}) {
    final int? distanceValue = int.tryParse(distance);
    final double opacity = distanceValue != null && distanceValue <= 100
        ? (100 - distanceValue) / 100
        : 0.1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(opacity),
                Colors.yellow.withOpacity(opacity / 2),
                Colors.green.withOpacity(0.1),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text("$direction: $distance cm", style: TextStyle(color: Colors.black)),
      ],
    );
  }
}
