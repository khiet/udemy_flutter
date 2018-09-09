import 'package:scoped_model/scoped_model.dart';

import '../scoped-models/connected_products.dart';

class MainModel extends Model
    with ConnectedProductsModel, ProductsModel, UserModel, UtilityModel {}
