import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Map extends StatefulWidget {
  @override
  _Map createState() => _Map();
}

class _Map extends State<Map> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Punjab Districts"),
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: (LatLng(32.0740,72.6861)),
            zoom: 6,
          ),

          markers: {
            Marker( //Attock
              markerId: MarkerId('1'),
              position: LatLng(33.7660 ,72.3609),
            ),

            Marker( //Bahawalnagar
              markerId: MarkerId('2'),
              position: LatLng(29.9994 , 73.2550 ),
            ),

            Marker( //Bahawalpur
              markerId: MarkerId('3'),
              position: LatLng(29.3544 , 71.6911 ),
            ),

            Marker( //Bhakkar
              markerId: MarkerId('4'),
              position: LatLng(31.6082 , 71.0854 ),
            ),
            Marker( //Chakwal
              markerId: MarkerId('5'),
              position: LatLng(32.9328 , 72.8630 ),
            ),

            Marker( //Chiniot
              markerId: MarkerId('6'),
              position: LatLng(31.7292 , 72.9822 ),
            ),

            Marker( //DG Khan
              markerId: MarkerId('7'),
              position: LatLng(31.8626 , 70.9019 ),
            ),

            Marker( //Faisalabad
              markerId: MarkerId('8'),
              position: LatLng(31.4504 , 73.1350 ),
            ),

            Marker( //Gujranwala
              markerId: MarkerId('3'),
              position: LatLng(32.1877 , 74.1945 ),
            ),

            Marker( //Gujrat
              markerId: MarkerId('9'),
              position: LatLng(32.5731 , 74.1005 ),
            ),
            Marker( //Hafizabad
              markerId: MarkerId('10'),
              position: LatLng(32.0712 , 73.6895 ),
            ),

            Marker( //Jhang
              markerId: MarkerId('11'),
              position: LatLng(31.2781 , 72.3317 ),
            ),
            Marker( //Jhelum
              markerId: MarkerId('12'),
              position: LatLng(32.9425 , 73.7257 ),
            ),
            Marker( //Kasur
              markerId: MarkerId('13'),
              position: LatLng(31.1137 , 74.4672 ),
            ),

            Marker( //Khanewal
              markerId: MarkerId('14'),
              position: LatLng(30.2864 , 71.9320 ),
            ),
            Marker( //Khushab
              markerId: MarkerId('15'),
              position: LatLng(32.2955 , 72.3489 ),
            ),
            Marker( //Lahore
              markerId: MarkerId('16'),
              position: LatLng(31.5204 , 74.3587 ),
            ),
            Marker( //Layyah
              markerId: MarkerId('17'),
              position: LatLng(30.9693 , 70.9428 ),
            ),
            Marker( //Lodhran
              markerId: MarkerId('18'),
              position: LatLng(29.5467 , 71.6276 ),
            ),
            Marker( //M.B.Din
              markerId: MarkerId('19'),
              position: LatLng(32.5742 , 73.4828 ),
            ),
            Marker( //Mianwali
              markerId: MarkerId('20'),
              position: LatLng(32.5839 , 71.5370 ),
            ),
            Marker( //Multan
              markerId: MarkerId('21'),
              position: LatLng(30.1864 , 71.4886 ),
            ),
            Marker( //Muzaffargarh
              markerId: MarkerId('22'),
              position: LatLng(30.0736 , 71.1805 ),
            ),
            Marker( //Nankana Sahib
              markerId: MarkerId('23'),
              position: LatLng(31.4492 , 73.7125 ),
            ),
            Marker( //Narowal
              markerId: MarkerId('24'),
              position: LatLng(32.1014 , 74.8800 ),
            ),
            Marker( //Okara
              markerId: MarkerId('25'),
              position: LatLng(30.8138 , 73.4534 ),
            ),
            Marker( //Pakpattan
              markerId: MarkerId('23'),
              position: LatLng(30.3495 , 73.3827 ),
            ),
            Marker( //Rahim Yar Khan
              markerId: MarkerId('26'),
              position: LatLng(28.4212 , 70.2989 ),
            ),
            Marker( //Rajunpur
              markerId: MarkerId('27'),
              position: LatLng(29.1044 , 70.3301 ),
            ),
            Marker( //Pindi
              markerId: MarkerId('28'),
              position: LatLng(33.5651 , 73.0169 ),
            ),
            Marker( //Sahiwal
              markerId: MarkerId('29'),
              position: LatLng(30.6682 , 73.1114 ),
            ),
            Marker( //Sargodha
              markerId: MarkerId('30'),
              position: LatLng(32.0740 , 72.6861 ),
            ),
            Marker( //Sheikhupura
              markerId: MarkerId('31'),
              position: LatLng(31.7167 , 73.9850 ),
            ),
            Marker( //Sialkot
              markerId: MarkerId('32'),
              position: LatLng(32.4945 , 74.5229 ),
            ),
            Marker( //Toba tek singh
              markerId: MarkerId('33'),
              position: LatLng(30.9709 , 72.4826 ),
            ),
            Marker( // Vehari
              markerId: MarkerId('34'),
              position: LatLng(30.0442 , 72.3441 ),
            ),

          },
        ),
      ),
    );
  }
}
