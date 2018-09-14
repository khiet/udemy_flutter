import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';
import 'package:http/http.dart' as http;

import '../../models/location.dart';
import '../../models/product.dart';

class LocationInput extends StatefulWidget {
  final Function setLocation;
  final Product product;

  LocationInput(this.setLocation, this.product);

  @override
  State<StatefulWidget> createState() {
    return _LocationInputState();
  }
}

class _LocationInputState extends State<LocationInput> {
  Uri _staticMapUri;
  LocationData _locationData;
  final FocusNode _addressInputFocusNode = FocusNode();
  final TextEditingController _addressInputcontroller = TextEditingController();

  @override
  void initState() {
    _addressInputFocusNode.addListener(_updateLocation);
    if (widget.product != null) {
      getStaticMap(widget.product.location.address, false);
    }
    super.initState();
  }

  @override
  void dispose() {
    _addressInputFocusNode.removeListener(_updateLocation);
    super.dispose();
  }

  void getStaticMap(String address, [geocode = true]) async {
    if (address.isEmpty) {
      setState(() {
        _staticMapUri = null;
      });
      widget.setLocation(null);
      return;
    }

    if (geocode) {
      // https://developers.google.com/maps/documentation/geocoding/intro
      final Uri rui = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {'address': address, 'key': 'AIzaSyDc72LQ1Qsa72z6Xg8dWb59aCg9_jEIqwA'},
      );

      final http.Response response = await http.get(rui);
      final decodedResponse = json.decode(response.body);
      final formattedAddress =
          decodedResponse['results'][0]['formatted_address'];
      final coords = decodedResponse['results'][0]['geometry']['location'];
      _locationData = LocationData(
          latitude: coords['lat'],
          longitude: coords['lng'],
          address: formattedAddress);
    } else {
      _locationData = widget.product.location;
    }

    final StaticMapProvider staticMapViewProvider =
        StaticMapProvider('AIzaSyDc72LQ1Qsa72z6Xg8dWb59aCg9_jEIqwA');

    final Uri staticMapUri = staticMapViewProvider.getStaticUriWithMarkers(
      [
        Marker('position', 'Position', _locationData.latitude,
            _locationData.longitude),
      ],
      center: Location(_locationData.latitude, _locationData.longitude),
      width: 500,
      height: 300,
      maptype: StaticMapViewType.roadmap,
    );

    widget.setLocation(_locationData);
    setState(() {
      _staticMapUri = staticMapUri;
      _addressInputcontroller.text = _locationData.address;
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
          validator: (String value) {
            if (value.isEmpty || _locationData == null) {
              return 'No valid location found.';
            }
          },
          decoration: InputDecoration(
            labelText: 'Address',
          ),
        ),
        SizedBox(
          height: 10.0,
        ),
        _staticMapUri != null
            ? Image.network(_staticMapUri.toString())
            : Container(),
      ],
    );
  }
}
