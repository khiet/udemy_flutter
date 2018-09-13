import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';
import 'package:http/http.dart' as http;

class LocationInput extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LocationInputState();
  }
}

class _LocationInputState extends State<LocationInput> {
  Uri _staticMapUri;
  final FocusNode _addressInputFocusNode = FocusNode();
  final TextEditingController _addressInputcontroller = TextEditingController();

  @override
  void initState() {
    _addressInputFocusNode.addListener(_updateLocation);
    super.initState();
  }

  @override
  void dispose() {
    _addressInputFocusNode.removeListener(_updateLocation);
    super.dispose();
  }

  void getStaticMap(String address) async {
    if (address.isEmpty) {
      return;
    }

    // https://developers.google.com/maps/documentation/geocoding/intro
    final Uri rui = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {'address': address, 'key': 'AIzaSyDc72LQ1Qsa72z6Xg8dWb59aCg9_jEIqwA'},
    );

    final http.Response response = await http.get(rui);
    final decodedResponse = json.decode(response.body);
    final formattedAddress = decodedResponse['results'][0]['formatted_address'];
    final coords = decodedResponse['results'][0]['geometry']['location'];

    print(decodedResponse);

    final StaticMapProvider staticMapViewProvider =
        StaticMapProvider('AIzaSyDc72LQ1Qsa72z6Xg8dWb59aCg9_jEIqwA');

    final Uri staticMapUri = staticMapViewProvider.getStaticUriWithMarkers(
      [
        Marker('position', 'Position', coords['lat'], coords['lng']),
      ],
      center: Location(coords['lat'], coords['lng']),
      width: 500,
      height: 300,
      maptype: StaticMapViewType.roadmap,
    );

    setState(() {
      _staticMapUri = staticMapUri;
      _addressInputcontroller.text = formattedAddress;
    });
  }

  void _updateLocation() {
    if (!_addressInputFocusNode.hasFocus) {
      getStaticMap(_addressInputcontroller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextFormField(
          focusNode: _addressInputFocusNode,
          controller: _addressInputcontroller,
          decoration: InputDecoration(
            labelText: 'Address',
          ),
        ),
        SizedBox(
          height: 10.0,
        ),
        Image.network(
          _staticMapUri.toString(),
        ),
      ],
    );
  }
}
