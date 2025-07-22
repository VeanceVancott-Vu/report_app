import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FreeMapPicker extends StatefulWidget {
  @override
  _FreeMapPickerState createState() => _FreeMapPickerState();
}

class _FreeMapPickerState extends State<FreeMapPicker> {
  LatLng? selectedPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location (Free Map)")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(15.97, 108.25), // Somewhere in Quảng Nam 🗺️
          initialZoom: 13,
          onTap: (tapPosition, latlng) {
            setState(() {
              selectedPosition = latlng;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.report_app',
          ),
          if (selectedPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: selectedPosition!,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (selectedPosition != null) {
            Navigator.pop(context, selectedPosition);
          }
        },
        label: const Text("Select Location"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}