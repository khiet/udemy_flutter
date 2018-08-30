import 'package:flutter/material.dart';

class ProductCreatePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ProductCreatePageState();
  }
}

class _ProductCreatePageState extends State<ProductCreatePage> {
  String _titleValue = '';
  String _descriptionValue = '';
  double _priceValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10.0),
      child: ListView(
        children: <Widget>[
          Column(
            children: <Widget>[
              TextField(
                decoration: InputDecoration(labelText: 'Product Title'),
                onChanged: (String value) {
                  setState(() {
                    _titleValue = value;
                  });
                },
              ),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(labelText: 'Product Description'),
                onChanged: (String value) {
                  setState(() {
                    _descriptionValue = value;
                  });
                },
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Product Price'),
                onChanged: (String value) {
                  setState(() {
                    _priceValue = double.parse(value);
                  });
                },
              )
            ],
          )
        ],
      ),
    );
  }
}
