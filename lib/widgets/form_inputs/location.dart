import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as geoloc;

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
      _getStaticMap(widget.product.location.address, geocode: false);
    }
    super.initState();
  }

  @override
  void dispose() {
    _addressInputFocusNode.removeListener(_updateLocation);
    super.dispose();
  }

  Future<String> _getAddress(double lat, double lng) async {
    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'latlng': '${lat.toString()},${lng.toString()}',
        'key': 'AIzaSyDc72LQ1Qsa72z6Xg8dWb59aCg9_jEIqwA'
      },
    );

    final http.Response response = await http.get(uri);
    final decodedResponse = json.decode(response.body);
    final formattedAddress = decodedResponse['results'][0]['formatted_address'];
    return formattedAddress;
  }

  void _getUserLocation() async {
    final geoloc.Location location = geoloc.Location();
    try {
      final Map<String, double> currentLocation = await location.getLocation();

      final String address = await _getAddress(
        currentLocation['latitude'],
        currentLocation['longitude'],
      );

      _getStaticMap(
        address,
        geocode: false,
        lat: currentLocation['latitude'],
        lng: currentLocation['longitude'],
      );
    } catch (error) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Could not fetch Location'),
            content: Text('Please add an address manually!'),
            actions: <Widget>[
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Okay'),
              )
            ],
          );
        },
      );
    }
  }

  void _getStaticMap(String address,
      {bool geocode = true, double lat, double lng}) async {
    if (address.isEmpty) {
      setState(() {
        _staticMapUri = null;
      });
      widget.setLocation(null);
      return;
    }

    if (geocode) {
      // https://developers.google.com/maps/documentation/geocoding/intro
      final Uri uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {'address': address, 'key': 'AIzaSyDc72LQ1Qsa72z6Xg8dWb59aCg9_jEIqwA'},
      );

      final http.Response response = await http.get(uri);
      final decodedResponse = json.decode(response.body);
      final formattedAddress =
          decodedResponse['results'][0]['formatted_address'];
      final coords = decodedResponse['results'][0]['geometry']['location'];
      _locationData = LocationData(
          latitude: coords['lat'],
          longitude: coords['lng'],
          address: formattedAddress);
    } else if (lat == null && lng == null) {
      _locationData = widget.product.location;
    } else {
      _locationData = LocationData(
        latitude: lat,
        longitude: lng,
        address: address,
      );
    }

    final StaticMapProvider staticMapViewProvider =
        StaticMapProvider('AIzaSyDc72LQ1Qsa72z6Xg8dWb59aCg9_jEIqwA');

    final Uri staticMapUri = staticMapViewProvider.getStaticUriWithMarkers(
      [
        Marker('position', _locationData.address, _locationData.latitude,
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
      _getStaticMap(_addressInputcontroller.text);
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
        FlatButton(
          child: Text('Locate User'),
          onPressed: _getUserLocation,
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
