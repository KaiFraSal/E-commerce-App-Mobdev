import 'package:flutter/material.dart';

void main() {
  runApp(const ProductDemoApp());
}

// AUTHENTICATION LOGIC

class AuthService {
  AuthService._private();
  static final AuthService instance = AuthService._private();

  final List<User> _users = [];
  User? currentUser;

  bool register(String username, String password) {
    if (_users.any((u) => u.username == username)) return false;
    _users.add(User(username: username, password: password));
    return true;
  }

  bool login(String username, String password) {
    final user = _users.firstWhere(
            (u) => u.username == username && u.password == password,
        orElse: () => User.empty());
    if (user.isEmpty) return false;
    currentUser = user;
    return true;
  }

  void logout() {
    currentUser = null;
  }
}

class ProductService {
  ProductService._private();
  static final ProductService instance = ProductService._private();

  final List<Product> products = [];
}

class UserCart {
  UserCart._private();
  static final UserCart instance = UserCart._private();

  final List<CartItem> cart = [];

  void addItem(Product product) {
    if (product.stock <= 0) return;

    try {
      final existingItem = cart.firstWhere((item) => item.product.name == product.name);
      existingItem.quantity++;
    } catch (e) {
      cart.add(CartItem(product: product, quantity: 1));
    }
    product.stock--;
  }

  void decrementItem(CartItem cartItem) {
    cartItem.product.stock++;
    cartItem.quantity--;

    if (cartItem.quantity <= 0) {
      cart.remove(cartItem);
    }
  }

  void removeItem(CartItem cartItem) {
    cartItem.product.stock += cartItem.quantity;
    cart.remove(cartItem);
  }

  double get totalPrice {
    return cart.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }
}

class User {
  final String username;
  final String password;
  const User({required this.username, required this.password});

  const User.empty()
      : username = '',
        password = '';

  bool get isEmpty => username.isEmpty && password.isEmpty;
}

class Product {
  final String desc;
  final String name;
  double price;
  int stock;
  Product({required this.desc, required this.name, required this.price, required this.stock});
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class ProductDemoApp extends StatelessWidget {
  const ProductDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product App Demo',
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/menu': (context) => const MenuScreen(),
        '/add': (context) => const AddProductScreen(),
        '/list': (context) => const ProductListScreen(),
        '/cart': (context) => const CartScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// LOGIN SCREENS

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameC = TextEditingController();
  final TextEditingController _passwordC = TextEditingController();
  String? _error;

  void _tryLogin() {
    if (!_formKey.currentState!.validate()) return;

    final ok = AuthService.instance
        .login(_usernameC.text.trim(), _passwordC.text.trim());

    if (ok) {
      setState(() => _error = null);
      Navigator.pushReplacementNamed(context, '/menu');
    } else {
      setState(() => _error = 'Invalid username or password.');
    }
  }

  @override
  void dispose() {
    _usernameC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient:  LinearGradient(
            begin: Alignment.topCenter,
            end:  Alignment.bottomCenter,
            colors: [Color(0xffFFBF00), Color(0xffF85B1A)]
          ),
        ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Login',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Colors.white
          ),
          backgroundColor: const Color(0xff072083),
        ),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 420,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Welcome — Please login',
                          style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usernameC,
                        decoration: const InputDecoration(labelText: 'Username'),
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordC,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      if (_error != null)
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text('Create account'),
                          ),
                          ElevatedButton(
                            onPressed: _tryLogin,
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameC = TextEditingController();
  final TextEditingController _passwordC = TextEditingController();
  String? _message;

  void _tryRegister() {
    if (!_formKey.currentState!.validate()) return;

    final success = AuthService.instance
        .register(_usernameC.text.trim(), _passwordC.text.trim());

    if (success) {
      setState(() {
        _message = 'Registration successful. You can now login.';
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        Navigator.pop(context);
      });
    } else {
      setState(() {
        _message = 'Username already exists. Choose another.';
      });
    }
  }

  @override
  void dispose() {
    _usernameC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient:  LinearGradient(
            begin: Alignment.topCenter,
            end:  Alignment.bottomCenter,
            colors: [Color(0xffFFBF00), Color(0xffF85B1A)]
          ),
        ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Register',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Colors.white
          ),
          backgroundColor: const Color(0xff072083),
        ),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 420,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Create an account',
                          style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usernameC,
                        decoration: const InputDecoration(labelText: 'Username'),
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordC,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (v) => (v == null || v.length < 4)
                            ? 'Password must be >= 4 chars'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      if (_message != null)
                        Text(_message!,
                            style: const TextStyle(color: Colors.green)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back'),
                          ),
                          ElevatedButton(
                            onPressed: _tryRegister,
                            child: const Text('Register'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String get username =>
      AuthService.instance.currentUser?.username ?? 'Unknown user';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient:  LinearGradient(
            begin: Alignment.topCenter,
            end:  Alignment.bottomCenter,
            colors: [Color(0xffFFBF00), Color(0xffF85B1A)]
          ),
        ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Menu',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Colors.white
          ),
          backgroundColor: const Color(0xff072083),
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: () {
                AuthService.instance.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            )
          ],
        ),
        body: Center(
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Hello, $username',
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center),
                const SizedBox(height: 18),
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Product'),
                    onPressed: () => Navigator.pushNamed(context, '/add'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text('List Products'),
                    onPressed: () => Navigator.pushNamed(context, '/list'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Check Cart'),
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Clear All Products',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[300],
                    ),
                    onPressed: () {
                      ProductService.instance.products.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All products cleared')),
                      );
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _descC = TextEditingController();
  final TextEditingController _priceC = TextEditingController();
  final TextEditingController _stockC = TextEditingController();

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final double? price = double.tryParse(_priceC.text.trim());
    final int? stock = int.tryParse(_stockC.text.trim());

    if (price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid price or stock value.')),
      );
      return;
    }

    final product = Product(
      desc: _descC.text.trim(),
      name: _nameC.text.trim(),
      price: price,
      stock: stock,
    );
    ProductService.instance.products.add(product);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added')),
    );

    _nameC.clear();
    _descC.clear();
    _priceC.clear();
    _stockC.clear();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    _priceC.dispose();
    _stockC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient:  LinearGradient(
            begin: Alignment.topCenter,
            end:  Alignment.bottomCenter,
            colors: [Color(0xffFFBF00), Color(0xffF85B1A)]
          ),
        ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Add Product',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Colors.white
          ),
          backgroundColor: const Color(0xff072083),
        ),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 480,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameC,
                        decoration:
                        const InputDecoration(labelText: 'Product Name'),
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descC,
                        decoration: const InputDecoration(labelText: 'Description'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceC,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _stockC,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back'),
                          ),
                          ElevatedButton(
                            onPressed: _save,
                            child: const Text('Save'),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  void _removeAt(int index) {
    final removed = ProductService.instance.products.removeAt(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed: ${removed.name}')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final products = ProductService.instance.products;

    return Container(
      decoration: const BoxDecoration(
          gradient:  LinearGradient(
            begin: Alignment.topCenter,
            end:  Alignment.bottomCenter,
            colors: [Color(0xffFFBF00), Color(0xffF85B1A)]
          ),
        ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Products', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Colors.white
          ),
          backgroundColor: const Color(0xff072083),
        ),
        body: products.isEmpty
            ? const Center(
          child: Text('No products yet. Add one from the menu.'),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return Dismissible(
              key: ValueKey(p.hashCode + index),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => _removeAt(index),
              child: Card(
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text("Desc: ${p.desc}\nPrice: \₱${p.price.toStringAsFixed(2)}\nStock: ${p.stock}"),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_checkout, color: Colors.green),
                          onPressed: p.stock > 0
                              ? () {
                            setState(() {
                              UserCart.instance.addItem(p);
                            });
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                  content:
                                  Text('Added ${p.name} to cart')),
                            );
                          }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.red),
                          onPressed: () => _removeAt(index),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cart = UserCart.instance.cart;

    return Container(
      decoration: const BoxDecoration(
          gradient:  LinearGradient(
            begin: Alignment.topCenter,
            end:  Alignment.bottomCenter,
            colors: [Color(0xffFFBF00), Color(0xffF85B1A)]
          ),
        ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            "Your Cart",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Colors.white
          ),
          backgroundColor: const Color(0xff072083),
        ),
        body: cart.isEmpty
            ? const Center(
          child: Text('Your cart is empty.'),
        )
            : Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final item = cart[index];
                  return Dismissible(
                    key: ValueKey(item.product.hashCode),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      UserCart.instance.removeItem(item);
                      _update();
                    },
                    child: Card(
                      child: ListTile(
                        title: Text(item.product.name),
                        subtitle: Text(
                            "Stock: ${item.product.stock} \nPrice: \₱${item.product.price.toStringAsFixed(2)}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () {
                                UserCart.instance.decrementItem(item);
                                _update();
                              },
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onPressed: item.product.stock > 0
                                  ? () {
                                UserCart.instance.addItem(item.product);
                                _update();
                              }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\₱${UserCart.instance.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}