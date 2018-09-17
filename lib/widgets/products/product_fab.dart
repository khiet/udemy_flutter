import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/product.dart';
import '../../scoped-models/main.dart';

class ProductFab extends StatefulWidget {
  final Product product;

  ProductFab(this.product);

  @override
  State<StatefulWidget> createState() {
    return _ProductFabState();
  }
}

class _ProductFabState extends State<ProductFab> {
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant(
      builder: (BuildContext context, Widget child, MainModel model) {
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
                onPressed: () async {
                  final String url = 'mailto:${widget.product.userEmail}';
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    throw 'Could not launch!';
                  }
                },
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
                onPressed: () {
                  model.toggleProductFavouriteStatus();
                },
                child: Icon(
                  model.selectedProduct.isFavourite
                      ? Icons.favorite
                      : Icons.favorite_border,
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
      },
    );
  }
}
