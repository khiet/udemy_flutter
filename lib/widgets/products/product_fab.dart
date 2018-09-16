import 'package:flutter/material.dart';

class ProductFab extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ProductFabState();
  }
}

class _ProductFabState extends State<ProductFab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 70.0,
          width: 56.0,
          alignment: FractionalOffset.center,
          child: FloatingActionButton(
            backgroundColor: Theme.of(context).cardColor,
            heroTag: 'contact',
            mini: true,
            onPressed: () {},
            child: Icon(
              Icons.mail,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Container(
          height: 70.0,
          width: 56.0,
          alignment: FractionalOffset.center,
          child: FloatingActionButton(
            backgroundColor: Theme.of(context).cardColor,
            heroTag: 'favourite',
            mini: true,
            onPressed: () {},
            child: Icon(
              Icons.favorite,
              color: Colors.red,
            ),
          ),
        ),
        Container(
          height: 70.0,
          width: 56.0,
          child: FloatingActionButton(
            heroTag: 'options',
            onPressed: () {},
            child: Icon(
              Icons.more_vert,
            ),
          ),
        ),
      ],
    );
  }
}
