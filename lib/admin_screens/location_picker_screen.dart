import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? selectedPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Выбор местоположения")),
      body: FlutterMap(
        options: MapOptions(
          // теперь для центра и зума используется начальная позиция камеры:
          initialCenter: LatLng(55.7558, 37.6173), // Москва
          initialZoom: 12,
          onTap: (tapPosition, point) {
            setState(() {
              selectedPosition = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          if (selectedPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: selectedPosition!,
                  width: 40,
                  height: 40,
                  // теперь вместо builder — child:
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedPosition != null) {
            Navigator.pop(context, selectedPosition);
          }
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
