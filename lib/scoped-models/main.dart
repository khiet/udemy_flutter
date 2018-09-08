import 'package:scoped_model/scoped_model.dart';

import '../scoped-models/user.dart';
import '../scoped-models/products.dart';
import '../scoped-models/connected_products.dart';

class MainModel extends Model with ConnectedProducts, UserModel, ProductsModel {
}
