import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/subjects.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../models/product.dart';
import '../models/user.dart';
import '../models/auth.dart';
import '../models/location.dart';

class ConnectedProductsModel extends Model {
  List<Product> _products = [];
  String _selProductId;
  User _authenticatedUser;
  bool _isLoading = false;
}

class ProductsModel extends ConnectedProductsModel {
  bool _showFavorites = false;

  List<Product> get allProducts {
    return List.from(_products);
  }

  List<Product> get displayedProducts {
    if (_showFavorites) {
      return _products.where((Product product) => product.isFavourite).toList();
    }
    return List.from(_products);
  }

  String get selectedProductId {
    return _selProductId;
  }

  Product get selectedProduct {
    if (selectedProductId == null) {
      return null;
    }
    return _products.firstWhere((Product product) {
      return product.id == selectedProductId;
    });
  }

  bool get displayFavouritesOnly {
    return _showFavorites;
  }

  int get selectedProductIndex {
    return _products.indexWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  Future<Null> fetchProducts({onlyForUser: false}) {
    _isLoading = true;
    _products = [];
    notifyListeners();

    return http
        .get(
            'https://udemiy-flutter.firebaseio.com/products.json?auth=${_authenticatedUser.token}')
        .then<Null>((http.Response response) {
      final Map<String, dynamic> productListData = json.decode(response.body);
      final List<Product> fetchedProductList = [];

      if (productListData == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      productListData.forEach((String productId, dynamic productData) {
        final bool isFavourite = ((productData['wishlistUsers'] == null)
            ? false
            : (productData['wishlistUsers'] as Map<String, dynamic>)
                .containsKey(_authenticatedUser.id));

        final Product product = Product(
          id: productId,
          title: productData['title'],
          description: productData['description'],
          price: productData['price'],
          image: productData['imageUrl'],
          imagePath: productData['imagePath'],
          location: LocationData(
            latitude: productData['loc_lat'],
            longitude: productData['loc_lng'],
            address: productData['loc_address'],
          ),
          userEmail: productData['userEmail'],
          userId: productData['userId'],
          isFavourite: isFavourite,
        );

        fetchedProductList.add(product);
      });

      _products = onlyForUser
          ? fetchedProductList.where((Product product) {
              return product.userId == _authenticatedUser.id;
            }).toList()
          : fetchedProductList;

      _isLoading = false;
      notifyListeners();
      _selProductId = null;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return;
    });
  }

  Future<Map<String, dynamic>> uploadImage(File image,
      {String imagePath}) async {
    final List<String> mimeTypeData = lookupMimeType(image.path).split('/');
    final file = await http.MultipartFile.fromPath(
      'image',
      image.path,
      contentType: MediaType(
        mimeTypeData[0],
        mimeTypeData[1],
      ),
    );
    final http.MultipartRequest imageUploadRequest = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://us-central1-udemiy-flutter.cloudfunctions.net/storeImage',
      ),
    );

    imageUploadRequest.files.add(file);
    if (imagePath != null) {
      imageUploadRequest.fields['imagePath'] = Uri.encodeComponent(imagePath);
    }

    imageUploadRequest.headers['Authorization'] =
        'Bearer ${_authenticatedUser.token}';

    try {
      final http.StreamedResponse streamedResponse =
          await imageUploadRequest.send();
      final http.Response response =
          await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      }
    } catch (error) {
      print(error);
      return null;
    }
  }

  Future<bool> addProduct(String title, String description, double price,
      File image, LocationData locData) async {
    _isLoading = true;
    notifyListeners();

    final Map<String, dynamic> uploadData = await uploadImage(image);
    if (uploadData == null) {
      return false;
    }

    final Map<String, dynamic> productData = {
      'title': title,
      'description': description,
      'imagePath': uploadData['imagePath'],
      'imageUrl': uploadData['imageUrl'],
      'price': price,
      'userEmail': _authenticatedUser.email,
      'userId': _authenticatedUser.id,
      'loc_lat': locData.latitude,
      'loc_lng': locData.longitude,
      'loc_address': locData.address
    };

    try {
      final http.Response response = await http.post(
        'https://udemiy-flutter.firebaseio.com/products.json?auth=${_authenticatedUser.token}',
        body: json.encode(productData),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final Map<String, dynamic> responseData = json.decode(response.body);

      final Product newProduct = Product(
        id: responseData['name'],
        title: title,
        description: description,
        image: uploadData['imageUrl'],
        imagePath: uploadData['imagePath'],
        price: price,
        location: locData,
        userEmail: _authenticatedUser.email,
        userId: _authenticatedUser.id,
      );
      _products.add(newProduct);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(String title, String description, double price,
      File image, LocationData locData) async {
    _isLoading = true;
    notifyListeners();

    String imageUrl = selectedProduct.image;
    String imagePath = selectedProduct.imagePath;
    if (image != null) {
      final Map<String, dynamic> uploadData = await uploadImage(image);
      if (uploadData == null) {
        return false;
      }

      imageUrl = uploadData['imageUrl'];
      imagePath = uploadData['imagePath'];
    }

    final Map<String, dynamic> updateData = {
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'price': price,
      'loc_lat': locData.latitude,
      'loc_lng': locData.longitude,
      'loc_address': locData.address,
      'userEmail': selectedProduct.userEmail,
      'userId': selectedProduct.userId,
    };

    try {
      final http.Response response = await http.put(
        'https://udemiy-flutter.firebaseio.com/products/${selectedProduct.id}.json?auth=${_authenticatedUser.token}',
        body: json.encode(updateData),
      );

      _isLoading = false;
      final Product updatedProduct = Product(
        id: selectedProduct.id,
        title: title,
        description: description,
        image: imageUrl,
        imagePath: imagePath,
        price: price,
        location: locData,
        userEmail: selectedProduct.userEmail,
        userId: selectedProduct.userId,
      );

      _products[selectedProductIndex] = updatedProduct;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct() {
    _isLoading = true;
    final String deletedProductId = selectedProduct.id;

    _products.removeAt(selectedProductIndex);
    notifyListeners();

    return http
        .delete(
            'https://udemiy-flutter.firebaseio.com/products/$deletedProductId.json?auth=${_authenticatedUser.token}')
        .then((http.Response response) {
      _isLoading = false;
      notifyListeners();
      return true;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  void toggleProductFavouriteStatus(Product toggledProduct) async {
    final bool isCurrentlyFavorite = toggledProduct.isFavourite;
    final bool newFavoriteStatus = !isCurrentlyFavorite;
    final int toggledProductIndex = _products.indexWhere((Product product) {
      return product.id == toggledProduct.id;
    });
    Product updatedProduct = Product(
      id: toggledProduct.id,
      title: toggledProduct.title,
      description: toggledProduct.description,
      price: toggledProduct.price,
      location: toggledProduct.location,
      image: toggledProduct.image,
      imagePath: toggledProduct.imagePath,
      userEmail: toggledProduct.userEmail,
      userId: toggledProduct.userId,
      isFavourite: newFavoriteStatus,
    );

    http.Response response;
    if (newFavoriteStatus) {
      response = await http.put(
          'https://udemiy-flutter.firebaseio.com/products/${toggledProduct.id}/wishlistUsers/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}',
          body: json.encode(true));
    } else {
      response = await http.delete(
          'https://udemiy-flutter.firebaseio.com/products/${toggledProduct.id}/wishlistUsers/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      updatedProduct = Product(
        id: toggledProduct.id,
        title: toggledProduct.title,
        description: toggledProduct.description,
        price: toggledProduct.price,
        location: toggledProduct.location,
        image: toggledProduct.image,
        imagePath: toggledProduct.imagePath,
        userEmail: toggledProduct.userEmail,
        userId: toggledProduct.userId,
        isFavourite: !newFavoriteStatus,
      );
    }

    _products[toggledProductIndex] = updatedProduct;
    notifyListeners();
  }

  void selectProduct(String productId) {
    print('selectProduct $productId');
    _selProductId = productId;
    if (productId != null) {
      notifyListeners();
    }
  }

  void toggleDisplayMode() {
    _showFavorites = !_showFavorites;
    notifyListeners();
  }
}

class UserModel extends ConnectedProductsModel {
  Timer _authTimer;
  PublishSubject<bool> _userSubject = PublishSubject();

  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

  User get user {
    return _authenticatedUser;
  }

  Future<Map<String, dynamic>> authenticate(String email, String password,
      [AuthMode mode = AuthMode.Login]) async {
    _isLoading = true;
    notifyListeners();

    final Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true
    };

    final String authUrl = (mode == AuthMode.Login)
        ? 'https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=AIzaSyA_T9yBuYx19vbbzakD4cjmXcNMwh0BpZE'
        : 'https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=AIzaSyA_T9yBuYx19vbbzakD4cjmXcNMwh0BpZE';

    final http.Response response = await http.post(
      authUrl,
      body: json.encode(authData),
      headers: {'Content-Type': 'application/json'},
    );

    final Map<String, dynamic> responseData = json.decode(response.body);
    String message = 'Something went wrong.';
    bool hasError = true;

    if (responseData.containsKey('idToken')) {
      hasError = false;
      message = 'Authentication succeeded!';
      _authenticatedUser = User(
          id: responseData['localId'],
          email: email,
          token: responseData['idToken']);

      setAuthTimeout(int.parse(responseData['expiresIn']));
      _userSubject.add(true);

      final DateTime now = DateTime.now();
      final DateTime expiryTime = now.add(
        Duration(
          seconds: int.parse(
            responseData['expiresIn'],
          ),
        ),
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('userId', responseData['localId']);
      prefs.setString('userEmail', email);
      prefs.setString('token', responseData['idToken']);
      prefs.setString('expiryTime', expiryTime.toIso8601String());
    } else if (responseData['error']['message'] == 'EMAIL_NOT_FOUND') {
      message = 'This email was not found.';
    } else if (responseData['error']['message'] == 'INVALID_PASSWORD') {
      message = 'This password is invalid.';
    } else if (responseData['error']['message'] == 'EMAIL_EXISTS') {
      message = 'This email already exists.';
    }

    _isLoading = false;
    notifyListeners();
    return {'success': !hasError, 'message': message};
  }

  void autoAuthenticate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('token');
    final String expiryTimeString = prefs.getString('expiryTime');
    if (token != null) {
      final DateTime now = DateTime.now();
      final DateTime parsedExpiryTime = DateTime.parse(expiryTimeString);
      if (parsedExpiryTime.isBefore(now)) {
        _authenticatedUser = null;
        notifyListeners();
        return;
      }
      final String userEmail = prefs.getString('userEmail');
      final String userId = prefs.getString('userId');
      final int tokenLifespan = parsedExpiryTime.difference(now).inSeconds;
      _authenticatedUser = User(id: userId, email: userEmail, token: token);
      _userSubject.add(true);
      setAuthTimeout(tokenLifespan);
      notifyListeners();
    }
  }

  void logout() async {
    _authenticatedUser = null;
    _authTimer.cancel();
    _userSubject.add(false);
    _selProductId = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userEmail');
    prefs.remove('userId');
    prefs.remove('token');
  }

  void setAuthTimeout(int time) {
    _authTimer = Timer(Duration(seconds: time), logout);
  }
}

class UtilityModel extends ConnectedProductsModel {
  bool get isLoading {
    return _isLoading;
  }
}
