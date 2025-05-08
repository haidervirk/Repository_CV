import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SmallMap extends StatelessWidget {
  final LatLng loc;

  const SmallMap({super.key, required this.loc});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: (loc),
            zoom: 8,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('1'),
              position: loc,
            ),
          },
        ),
      ),
    );
  }
}
