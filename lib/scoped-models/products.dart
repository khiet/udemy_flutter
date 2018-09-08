import '../models/product.dart';
import './connected_products.dart';

class ProductsModel extends ConnectedProducts {
  bool _showFavourites = false;

  List<Product> get allProducts {
    return List.from(products);
  }

  List<Product> get displayedProducts {
    if (_showFavourites) {
      return products.where((Product product) => product.isFavourite).toList();
    }

    return List.from(products);
  }

  int get selectedProductIndex {
    return selProductIndex;
  }

  Product get selectedProduct {
    if (selectedProductIndex == null) {
      return null;
    }
    return products[selectedProductIndex];
  }

  bool get displayFavouritesOnly {
    return _showFavourites;
  }

  void updateProduct(
      String title, String description, double price, String image) {
    final Product updatedProduct = Product(
        title: title,
        description: description,
        price: price,
        image: image,
        userEmail: selectedProduct.userEmail,
        userId: selectedProduct.userId);

    products[selectedProductIndex] = updatedProduct;
    selProductIndex = null;
  }

  void deleteProduct() {
    products.removeAt(selectedProductIndex);
    selProductIndex = null;
  }

  void setSelectedProduct(int index) {
    selProductIndex = index;
  }

  void toggleProductFavouriteStatus() {
    final bool isCurrentlyFavorite = selectedProduct.isFavourite;
    final bool newFavoriteStatus = !isCurrentlyFavorite;
    final Product updatedProduct = Product(
        title: selectedProduct.title,
        description: selectedProduct.description,
        price: selectedProduct.price,
        image: selectedProduct.image,
        userEmail: selectedProduct.userEmail,
        userId: selectedProduct.userId,
        isFavourite: newFavoriteStatus);

    products[selectedProductIndex] = updatedProduct;
    selProductIndex = null;

    notifyListeners();
  }

  void toggleDisplayMode() {
    _showFavourites = !_showFavourites;

    notifyListeners();
  }
}
