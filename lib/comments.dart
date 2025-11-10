import 'package:flutter/material.dart'; // Import Flutter material widgets and utilities


void main() { // Application entry point
  runApp(const ProductDemoApp()); // Launch the app with ProductDemoApp as the root widget
}


// AUTHENTICATION LOGIC


class AuthService { // Singleton service that manages users and authentication state
  AuthService._private(); // Private constructor to prevent external instantiation
  static final AuthService instance = AuthService._private(); // Single shared instance


  final List<User> _users = []; // In-memory list of registered users
  User? currentUser; // Currently logged-in user, null when none


  bool register(String username, String password) { // Register a new user
    if (_users.any((u) => u.username == username)) return false; // Fail if username already exists
    _users.add(User(username: username, password: password)); // Add new user to list
    return true; // Registration successful
  }


  bool login(String username, String password) { // Attempt to log in with credentials
    final user = _users.firstWhere( // Find first user matching both username and password
            (u) => u.username == username && u.password == password,
        orElse: () => User.empty()); // If not found, return an empty User sentinel
    if (user.isEmpty) return false; // Login failed when sentinel returned
    currentUser = user; // Set the authenticated user
    return true; // Login successful
  }


  void logout() { // Log out the current user
    currentUser = null; // Clear authentication state
  }
}


class ProductService { // Singleton service that holds available products
  ProductService._private(); // Private constructor for singleton pattern
  static final ProductService instance = ProductService._private(); // Shared instance


  final List<Product> products = []; // In-memory list of products available in the shop
}


class UserCart { // Singleton cart representing the current user's shopping cart
  UserCart._private(); // Private constructor for singleton
  static final UserCart instance = UserCart._private(); // Shared instance


  final List<CartItem> cart = []; // List of items currently in the cart


  void addItem(Product product) { // Add a single unit of a product to the cart
    if (product.stock <= 0) return; // Do nothing when product is out of stock


    try {
      final existingItem = cart.firstWhere((item) => item.product.name == product.name); // Find existing cart item
      existingItem.quantity++; // Increment quantity if it exists
    } catch (e) {
      cart.add(CartItem(product: product, quantity: 1)); // If not found, add new cart item with quantity 1
    }
    product.stock--; // Decrease product stock after adding to cart
  }


  void addMultipleItems(Product product, int quantityToAdd) { // Add multiple units of a product to the cart
    if (quantityToAdd <= 0) return; // Can't add zero or negative amounts
    if (product.stock < quantityToAdd) return; // Do nothing if insufficient stock


    try {
      // Check if item is already in cart
      final existingItem = cart.firstWhere((item) => item.product.name == product.name); // Find existing cart item
      // If yes, just increase its quantity
      existingItem.quantity += quantityToAdd; // Increase existing quantity
    } catch (e) {
      // If no, add it as a new item with the specified quantity
      cart.add(CartItem(product: product, quantity: quantityToAdd)); // Add new cart item
    }
    // Decrease the product's stock by the quantity added
    product.stock -= quantityToAdd; // Deduct stock after adding to cart
  }


  void decrementItem(CartItem cartItem) { // Decrease quantity of a specific cart item by one
    cartItem.product.stock++; // Return one unit to product stock
    cartItem.quantity--; // Decrease item quantity in cart


    if (cartItem.quantity <= 0) {
      cart.remove(cartItem); // Remove the cart item if quantity reaches zero or below
    }
  }


  void removeItem(CartItem cartItem) { // Remove an item entirely from the cart
    cartItem.product.stock += cartItem.quantity; // Restock the product by the removed quantity
    cart.remove(cartItem); // Remove item from cart list
  }


  double get totalPrice { // Compute total price of all items in the cart
    return cart.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity)); // Sum of price * quantity
  }
}


class User { // Simple User model
  final String username; // Username string
  final String password; // Password string (stored in plain text for demo purposes)
  const User({required this.username, required this.password}); // Constructor requiring both fields


  const User.empty() // Sentinel empty user used for not-found results
      : username = '',
        password = '';


  bool get isEmpty => username.isEmpty && password.isEmpty; // Convenience check for the sentinel user
}


class Product { // Product model representing items available for sale
  final String desc; // Product description
  final String name; // Product name, used as identifier in cart logic
  double price; // Product price, mutable to allow changes
  int stock; // Available stock count, mutable
  Product({required this.desc, required this.name, required this.price, required this.stock}); // Constructor
}


class CartItem { // Model for an entry in the shopping cart
  final Product product; // Associated product
  int quantity; // Quantity of that product in the cart


  CartItem({required this.product, this.quantity = 1}); // Constructor with default quantity 1
}


class ProductDemoApp extends StatelessWidget { // Root widget of the Flutter app
  const ProductDemoApp({super.key}); // Const constructor delegating key to superclass


  @override
  Widget build(BuildContext context) { // Build method describes the UI
    return MaterialApp( // MaterialApp provides app-level configuration and routing
      title: 'Product App Demo', // App title
      initialRoute: '/login', // Start route when the app launches
      routes: { // Map of named routes to widget builders
        '/login': (context) => const LoginScreen(), // Route for login screen
        '/register': (context) => const RegisterScreen(), // Route for registration screen
        '/menu': (context) => const MenuScreen(), // Route for main menu
        '/add': (context) => const AddProductScreen(), // Route to add a product
        '/list': (context) => const ProductListScreen(), // Route to view product list
        '/cart': (context) => const CartScreen(), // Route to view cart
      },
      debugShowCheckedModeBanner: false, // Hide the debug banner in debug builds
    );
  }
}


// LOGIN SCREENS


class LoginScreen extends StatefulWidget { // Define a stateful widget for the login screen
  const LoginScreen({super.key}); // Const constructor forwarding optional key to superclass


  @override
  State<LoginScreen> createState() => _LoginScreenState(); // Create the mutable state instance
}


class _LoginScreenState extends State<LoginScreen> { // State class for LoginScreen
  final _formKey = GlobalKey<FormState>(); // Key to validate and manage the Form widget
  final TextEditingController _usernameC = TextEditingController(); // Controller for username input
  final TextEditingController _passwordC = TextEditingController(); // Controller for password input
  String? _error; // Nullable string to hold an error message for display


  void _tryLogin() { // Attempt to authenticate using form values
    if (!_formKey.currentState!.validate()) return; // Validate fields, abort if invalid


    final ok = AuthService.instance // Call singleton AuthService to perform login
        .login(_usernameC.text.trim(), _passwordC.text.trim()); // Pass trimmed username and password


    if (ok) { // If login succeeded
      setState(() => _error = null); // Clear any previous error and rebuild UI
      Navigator.pushReplacementNamed(context, '/menu'); // Navigate to menu and replace login route
    } else { // If login failed
      setState(() => _error = 'Invalid username or password.'); // Set error message and rebuild UI
    }
  }


  @override
  void dispose() { // Clean up controllers when the state is disposed
    _usernameC.dispose(); // Dispose username controller to free resources
    _passwordC.dispose(); // Dispose password controller to free resources
    super.dispose(); // Call superclass dispose
  }


  @override
  Widget build(BuildContext context) { // Build method returns widget tree for this screen
    return Container( // Outer container to apply a background gradient
      decoration: const BoxDecoration( // Decoration for the container
          gradient:  LinearGradient( // Vertical linear gradient
            begin: Alignment.topCenter, // Gradient starts at top center
            end:  Alignment.bottomCenter, // Gradient ends at bottom center
            colors: [Color(0xffFFBF00), Color(0xffF85B1A)] // Two gradient colors
          ),
        ),
      child: Scaffold( // Scaffold provides app structure (app bar, body, etc.)
        backgroundColor: Colors.transparent, // Make scaffold background transparent to show gradient
        appBar: AppBar( // Top app bar
          title: const Text( // Title text widget
            'Login', // App bar title string
            style: TextStyle(color: Colors.white), // Title text color
          ),
          centerTitle: true, // Center the title horizontally
          iconTheme: IconThemeData( // Icon theme for app bar icons
            color: Colors.white // Icons colored white
          ),
          backgroundColor: const Color(0xff072083), // App bar background color
        ),
        body: Center( // Center the card in the available space
          child: Card( // Card widget that contains the login form
            margin: const EdgeInsets.all(24), // Outer margin around card
            child: Padding( // Padding inside the card
              padding: const EdgeInsets.all(16), // Uniform padding
              child: SizedBox( // Fixed width container for the form
                width: 420, // Constrain width to 420 logical pixels
                child: Form( // Form widget to group input fields and validation
                  key: _formKey, // Attach the form key defined earlier
                  child: Column( // Vertical layout for form elements
                    mainAxisSize: MainAxisSize.min, // Take minimal vertical space
                    children: [ // Children widgets in the column
                      const Text('Welcome — Please login', // Heading text
                          style: TextStyle(fontSize: 18)), // Text style for heading
                      const SizedBox(height: 12), // Spacer between heading and field
                      TextFormField( // Username input field with validation
                        controller: _usernameC, // Bind controller to field
                        decoration: const InputDecoration(labelText: 'Username'), // Label shown above field
                        validator: (v) => // Validator callback for this field
                        v == null || v.trim().isEmpty ? 'Required' : null, // Return error when empty
                      ),
                      const SizedBox(height: 8), // Small spacer between fields
                      TextFormField( // Password input field with obscured text
                        controller: _passwordC, // Bind password controller
                        decoration: const InputDecoration(labelText: 'Password'), // Field label
                        obscureText: true, // Hide entered characters
                        validator: (v) => // Validator for password field
                        v == null || v.isEmpty ? 'Required' : null, // Error when empty
                      ),
                      const SizedBox(height: 12), // Spacer before possible error message
                      if (_error != null) // Conditional display: show error only when non-null
                        Text(_error!, // Display the error message
                            style: const TextStyle(color: Colors.red)), // Style error text red
                      Row( // Horizontal row for action buttons
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space buttons apart
                        children: [
                          TextButton( // Button to navigate to register screen
                            onPressed: () {
                              Navigator.pushNamed(context, '/register'); // Push register route onto stack
                            },
                            child: const Text('Create account'), // Button label
                          ),
                          ElevatedButton( // Primary action button for login
                            onPressed: _tryLogin, // Call _tryLogin when pressed
                            child: const Text('Login'), // Button label
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


class RegisterScreen extends StatefulWidget { // Stateful widget for account registration
  const RegisterScreen({super.key}); // Const constructor forwarding key


  @override
  State<RegisterScreen> createState() => _RegisterScreenState(); // Create corresponding state
}


class _RegisterScreenState extends State<RegisterScreen> { // State class for RegisterScreen
  final _formKey = GlobalKey<FormState>(); // Form key to manage validation
  final TextEditingController _usernameC = TextEditingController(); // Controller for username input
  final TextEditingController _passwordC = TextEditingController(); // Controller for password input
  String? _message; // Nullable message to show success or failure feedback


  void _tryRegister() { // Attempt to register a new user
    if (!_formKey.currentState!.validate()) return; // Validate fields, abort if invalid


    final success = AuthService.instance // Call AuthService singleton to register
        .register(_usernameC.text.trim(), _passwordC.text.trim()); // Pass trimmed values


    if (success) { // If registration succeeded
      setState(() {
        _message = 'Registration successful. You can now login.'; // Set success message and rebuild
      });
      Future.delayed(const Duration(milliseconds: 800), () { // Short delay before navigating back
        if (!mounted) return; // Ensure widget is still in the tree before using context
        Navigator.pop(context); // Pop registration screen to return to previous (likely login)
      });
    } else { // If registration failed (username exists)
      setState(() {
        _message = 'Username already exists. Choose another.'; // Set failure message and rebuild
      });
    }
  }


  @override
  void dispose() { // Dispose controllers when state removed
    _usernameC.dispose(); // Dispose username controller
    _passwordC.dispose(); // Dispose password controller
    super.dispose(); // Call superclass dispose
  }


  @override
  Widget build(BuildContext context) { // Build UI for registration screen
    return Container( // Outer container for gradient background
      decoration: const BoxDecoration( // Decoration with gradient
          gradient:  LinearGradient( // Vertical linear gradient definition
            begin: Alignment.topCenter, // Start at top center
            end:  Alignment.bottomCenter, // End at bottom center
            colors: [Color(0xffFFBF00), Color(0xffF85B1A)] // Colors used in gradient
          ),
        ),
      child: Scaffold( // Scaffold to provide app structure
        backgroundColor: Colors.transparent, // Transparent scaffold to show gradient
        appBar: AppBar( // App bar for the register screen
          title: const Text( // Title widget
            'Register', // App bar title text
            style: TextStyle(color: Colors.white), // Title color
          ),
          centerTitle: true, // Center the title
          iconTheme: IconThemeData( // Icon theme for app bar icons
            color: Colors.white // Icons colored white
          ),
          backgroundColor: const Color(0xff072083), // App bar background color
        ),
        body: Center( // Center the card vertically and horizontally
          child: Card( // Card containing the registration form
            margin: const EdgeInsets.all(24), // Margin around the card
            child: Padding( // Padding inside the card
              padding: const EdgeInsets.all(16), // Uniform padding
              child: SizedBox( // Constrain form width
                width: 420, // Fixed width for consistency with login screen
                child: Form( // Form widget to hold input fields and validation
                  key: _formKey, // Attach form key
                  child: Column( // Vertical layout for form components
                    mainAxisSize: MainAxisSize.min, // Minimal vertical space
                    children: [
                      const Text('Create an account', // Heading for the form
                          style: TextStyle(fontSize: 18)), // Heading style
                      const SizedBox(height: 12), // Spacer
                      TextFormField( // Username input with validation
                        controller: _usernameC, // Bind username controller
                        decoration: const InputDecoration(labelText: 'Username'), // Label text
                        validator: (v) => // Validator callback
                        v == null || v.trim().isEmpty ? 'Required' : null, // Error when empty
                      ),
                      const SizedBox(height: 8), // Small spacer
                      TextFormField( // Password input with validation rules
                        controller: _passwordC, // Bind password controller
                        decoration: const InputDecoration(labelText: 'Password'), // Label text
                        obscureText: true, // Obscure password input
                        validator: (v) => (v == null || v.length < 4) // Validator checks length
                            ? 'Password must be >= 4 chars' // Error when too short
                            : null, // Valid otherwise
                      ),
                      const SizedBox(height: 12), // Spacer before message
                      if (_message != null) // Conditionally show feedback message
                        Text(_message!, // Display the message string
                            style: const TextStyle(color: Colors.green)), // Style message green for success
                      Row( // Row for action buttons
                        mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the end (right)
                        children: [
                          TextButton( // Back button to return without registering
                            onPressed: () => Navigator.pop(context), // Pop current route
                            child: const Text('Back'), // Button label
                          ),
                          ElevatedButton( // Register button to submit form
                            onPressed: _tryRegister, // Trigger registration attempt
                            child: const Text('Register'), // Button label
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


class MenuScreen extends StatefulWidget { // Stateful widget showing the main menu after login
  const MenuScreen({super.key}); // Const constructor forwarding key to superclass


  @override
  State<MenuScreen> createState() => _MenuScreenState(); // Create mutable state for this widget
}


class _MenuScreenState extends State<MenuScreen> { // State implementation for MenuScreen
  String get username => // Getter that provides the current username for display
      AuthService.instance.currentUser?.username ?? 'Unknown user'; // Read from AuthService singleton, fallback when null


  @override
  Widget build(BuildContext context) { // Build method returns the widget tree for the menu
    return Container( // Container used to provide a background gradient
      decoration: const BoxDecoration( // Decoration config for the container
          gradient:  LinearGradient( // Linear gradient background
            begin: Alignment.topCenter, // Gradient start position
            end:  Alignment.bottomCenter, // Gradient end position
            colors: [Color(0xffFFBF00), Color(0xffF85B1A)] // Gradient colors
          ),
        ),
      child: Scaffold( // Scaffold provides app structure (app bar, body)
        backgroundColor: Colors.transparent, // Make scaffold background transparent so gradient shows
        appBar: AppBar( // Top app bar
          title: const Text( // App bar title widget
            'Menu', // Title string
            style: TextStyle(color: Colors.white), // Title text color
          ),
          centerTitle: true, // Center the title text
          iconTheme: IconThemeData( // Icon theme for leading/trailing icons
            color: Colors.white // Set icon color to white
          ),
          backgroundColor: const Color(0xff072083), // App bar background color
          actions: [ // Action widgets in the app bar
            IconButton( // Logout icon button
              tooltip: 'Logout', // Tooltip text shown on long press / hover
              icon: const Icon(Icons.exit_to_app, color: Colors.white), // Icon and color
              onPressed: () { // Logout action handler
                AuthService.instance.logout(); // Clear authentication state in AuthService
                Navigator.pushReplacementNamed(context, '/login'); // Navigate back to login, replacing this route
              },
            )
          ],
        ),
        body: Center( // Center the content in the available space
          child: SizedBox( // SizedBox to constrain width of the menu content
            width: 420, // Fixed width for consistent layout on larger screens
            child: Column( // Vertical column of menu items
              mainAxisSize: MainAxisSize.min, // Use minimum vertical space required
              children: [ // Children widgets inside the column
                Text('Hello, $username', // Greeting text showing current username
                    style: const TextStyle(fontSize: 20), // Font size for greeting
                    textAlign: TextAlign.center), // Center text alignment
                const SizedBox(height: 18), // Spacer between greeting and first button
                SizedBox( // Constrain width of the button
                  width: 200, // Button width
                  child: ElevatedButton.icon( // Elevated button with an icon
                    icon: const Icon(Icons.add), // Icon displayed on button
                    label: const Text('Add New Product'), // Button label
                    onPressed: () => Navigator.pushNamed(context, '/add'), // Navigate to add product screen
                  ),
                ),
                const SizedBox(height: 12), // Spacer between buttons
                SizedBox( // Constrain width of the next button
                  width: 200, // Button width
                  child: ElevatedButton.icon( // Button to list products
                    icon: const Icon(Icons.list), // Icon for listing
                    label: const Text('List Products'), // Button label
                    onPressed: () => Navigator.pushNamed(context, '/list'), // Navigate to product list screen
                  ),
                ),
                const SizedBox(height: 12), // Spacer
                SizedBox( // Constrain width of the cart button
                  width: 200, // Button width
                  child: ElevatedButton.icon( // Button to check shopping cart
                    icon: const Icon(Icons.shopping_cart), // Cart icon
                    label: const Text('Check Cart'), // Button label
                    onPressed: () => Navigator.pushNamed(context, '/cart'), // Navigate to cart screen
                  ),
                ),
                const SizedBox(height: 12), // Spacer before destructive action
                SizedBox( // Constrain width for the destructive button
                  width: 200, // Button width
                  child: ElevatedButton.icon( // Elevated button styled as destructive action
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.white,
                    ), // Trash icon colored white
                    label: const Text(
                      'Clear All Products',
                      style: TextStyle(color: Colors.white),
                    ), // Button label styled white
                    style: ElevatedButton.styleFrom( // Custom button styling
                      backgroundColor: Colors.red[300], // Set button background to a red shade
                    ),
                    onPressed: () { // Handler for clearing all data
                      ProductService.instance.products.clear(); // Clear product list in ProductService
                      UserCart.instance.cart.clear(); // Clear user cart in UserCart singleton
                      ScaffoldMessenger.of(context).showSnackBar( // Show confirmation snackbar
                        const SnackBar(content: Text('All products cleared')),
                      );
                      setState(() {}); // Trigger rebuild to reflect cleared state
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


class AddProductScreen extends StatefulWidget { // Stateful widget for adding a new product
  const AddProductScreen({super.key}); // Const constructor forwarding key


  @override
  State<AddProductScreen> createState() => _AddProductScreenState(); // Create state instance
}


class _AddProductScreenState extends State<AddProductScreen> { // State class for add product screen
  final _formKey = GlobalKey<FormState>(); // Form key to manage validation
  final TextEditingController _nameC = TextEditingController(); // Controller for product name input
  final TextEditingController _descC = TextEditingController(); // Controller for description input
  final TextEditingController _priceC = TextEditingController(); // Controller for price input
  final TextEditingController _stockC = TextEditingController(); // Controller for stock input


  void _save() { // Save handler to validate and add product
    if (!_formKey.currentState!.validate()) return; // Validate form, abort if invalid


    final double? price = double.tryParse(_priceC.text.trim()); // Parse price from text, nullable on failure
    final int? stock = int.tryParse(_stockC.text.trim()); // Parse stock from text, nullable on failure


    if (price == null || stock == null) { // If parsing failed for either field
      ScaffoldMessenger.of(context).showSnackBar( // Show error snackbar
        const SnackBar(content: Text('Invalid price or stock value.')),
      );
      return; // Abort saving
    }


    final product = Product( // Create new Product instance from form values
      desc: _descC.text.trim(), // Trimmed description
      name: _nameC.text.trim(), // Trimmed name
      price: price, // Parsed price
      stock: stock, // Parsed stock
    );
    ProductService.instance.products.add(product); // Add the product to the ProductService list


    ScaffoldMessenger.of(context).showSnackBar( // Show success snackbar
      const SnackBar(content: Text('Product added')),
    );


    _nameC.clear(); // Clear name field for next entry
    _descC.clear(); // Clear description field
    _priceC.clear(); // Clear price field
    _stockC.clear(); // Clear stock field
  }


  @override
  void dispose() { // Dispose controllers when widget is removed
    _nameC.dispose(); // Dispose name controller
    _descC.dispose(); // Dispose description controller
    _priceC.dispose(); // Dispose price controller
    _stockC.dispose(); // Dispose stock controller
    super.dispose(); // Call superclass dispose
  }


  @override
  Widget build(BuildContext context) { // Build UI for add product screen
    return Container( // Container to host gradient background
      decoration: const BoxDecoration( // Gradient decoration
          gradient:  LinearGradient( // Linear gradient definition
            begin: Alignment.topCenter, // Start at top
            end:  Alignment.bottomCenter, // End at bottom
            colors: [Color(0xffFFBF00), Color(0xffF85B1A)] // Colors for gradient
          ),
        ),
      child: Scaffold( // Scaffold provides structure (app bar, body)
        backgroundColor: Colors.transparent, // Transparent scaffold background so gradient shows
        appBar: AppBar( // App bar for add product screen
          title: const Text( // Title widget
            'Add Product', // Title string
            style: TextStyle(color: Colors.white), // Title color
          ),
          centerTitle: true, // Center the title
          iconTheme: IconThemeData( // Icon theme for app bar
            color: Colors.white // White icon color
          ),
          backgroundColor: const Color(0xff072083), // App bar background color
        ),
        body: Center( // Center the card containing the form
          child: Card( // Card container for the form
            margin: const EdgeInsets.all(16), // Margin around card
            child: Padding( // Padding inside the card
              padding: const EdgeInsets.all(16), // Uniform padding
              child: SizedBox( // Constrain the width of the form
                width: 480, // Fixed width for the form layout
                child: Form( // Form widget to manage validation and grouping
                  key: _formKey, // Attach the form key
                  child: Column( // Vertical layout of form fields and actions
                    mainAxisSize: MainAxisSize.min, // Use minimal vertical space
                    children: [
                      TextFormField( // Product name input with validation
                        controller: _nameC, // Bind controller
                        decoration:
                        const InputDecoration(labelText: 'Product Name'), // Label text
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null, // Validate non-empty
                      ),
                      const SizedBox(height: 8), // Spacer
                      TextFormField( // Description input (optional)
                        controller: _descC, // Bind description controller
                        decoration: const InputDecoration(labelText: 'Description'), // Label text
                      ),
                      const SizedBox(height: 8), // Spacer
                      TextFormField( // Price input field
                        controller: _priceC, // Bind price controller
                        decoration: const InputDecoration(labelText: 'Price'), // Label text
                        keyboardType: const TextInputType.numberWithOptions(decimal: true), // Numeric keyboard allowing decimal input
                      ),
                      const SizedBox(height: 8), // Spacer
                      TextFormField( // Stock input field
                        controller: _stockC, // Bind stock controller
                        decoration: const InputDecoration(labelText: 'Stock'), // Label text
                        keyboardType: TextInputType.number, // Numeric keyboard for integers
                      ),
                      const SizedBox(height: 12), // Spacer before action buttons
                      Row( // Row to hold action buttons
                        mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the right
                        children: [
                          TextButton( // Back button to return to previous screen
                            onPressed: () => Navigator.pop(context), // Pop current route
                            child: const Text('Back'), // Button label
                          ),
                          ElevatedButton( // Save button to add the product
                            onPressed: _save, // Trigger _save when pressed
                            child: const Text('Save'), // Button label
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


class ProductListScreen extends StatefulWidget { // Stateful widget showing the list of products
  const ProductListScreen({super.key}); // Const constructor forwarding optional key


  @override
  State<ProductListScreen> createState() => _ProductListScreenState(); // Create mutable state instance
}


class _ProductListScreenState extends State<ProductListScreen> { // State class for ProductListScreen
  void _removeAt(int index) { // Remove product (and matching cart entries) at the given index
    final removedProduct = ProductService.instance.products.removeAt(index); // Remove product from ProductService list and keep reference


    // --- ADD THIS BLOCK ---
    // Now, remove the matching item from the cart, if it exists
    UserCart.instance.cart.removeWhere((cartItem) {
      return cartItem.product == removedProduct; // Remove cart items whose product equals the removed product
    });
    // --- END OF BLOCK ---


    ScaffoldMessenger.of(context).showSnackBar( // Show a snackbar confirming removal
      SnackBar(content: Text('Removed: ${removedProduct.name} from products and cart')), // Message includes product name
    );
    setState(() {}); // Trigger a rebuild so UI reflects removed product and cart changes
  }


  void _showAddToCartModal(int index) { // Show bottom sheet for adding a product to the cart
    final p = ProductService.instance.products[index]; // Grab product at the given index
    final controller = TextEditingController(); // Controller to read quantity input from the text field


    if (p.stock <= 0) { // If product has no stock available
      ScaffoldMessenger.of(context).showSnackBar( // Inform user it's out of stock
        SnackBar(content: Text('${p.name} is out of stock')),
      );
      return; // Abort showing the modal
    }


    showModalBottomSheet( // Open a modal bottom sheet to collect quantity
      context: context, // Build context for modal
      isScrollControlled: true, // Allow the sheet to expand with the keyboard
      builder: (context) {
        return Padding( // Add padding including keyboard inset
          padding: EdgeInsets.only(
            left: 16, // Left padding
            right: 16, // Right padding
            top: 16, // Top padding
            bottom: MediaQuery.of(context).viewInsets.bottom + 16, // Bottom padding adjusted for keyboard
          ),
          child: Column( // Column inside the modal
            mainAxisSize: MainAxisSize.min, // Take minimal vertical space
            children: [
              Text('Add ${p.name} to Cart', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), // Title showing product name
              const SizedBox(height: 8), // Spacing
              Align( // Align the stock text to the left
                alignment: Alignment.centerLeft,
                child: Text('Available stock: ${p.stock}'), // Show current available stock
              ),
              const SizedBox(height: 8), // Spacing
              TextField( // Input for quantity to add
                controller: controller, // Bind controller to read input
                keyboardType: TextInputType.number, // Numeric keyboard
                autofocus: true, // Automatically focus the field when modal opens
                decoration: const InputDecoration( // Decoration for the input field
                  labelText: 'Quantity to add', // Field label
                  hintText: 'Enter quantity', // Hint text
                  border: OutlineInputBorder(), // Outline border around the field
                ),
              ),
              const SizedBox(height: 12), // Spacing before action buttons
              Row( // Row for Cancel and Add buttons
                mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the right
                children: [
                  TextButton( // Cancel button
                    onPressed: () => Navigator.of(context).pop(), // Close the modal without doing anything
                    child: const Text('Cancel'), // Button label
                  ),
                  const SizedBox(width: 8), // Spacer between buttons
                  ElevatedButton( // Add to Cart button
                    onPressed: () { // Handler executed when user taps Add to Cart
                      final input = controller.text.trim(); // Read and trim the input string
                      final quantityToAdd = int.tryParse(input); // Parse input to integer (nullable)


                      if (quantityToAdd == null || quantityToAdd <= 0) { // Validate positive integer
                        ScaffoldMessenger.of(context).showSnackBar( // Show error snackbar for invalid quantity
                          const SnackBar(content: Text('Please enter a positive quantity')),
                        );
                        return; // Abort if invalid
                      }


                      if (quantityToAdd > p.stock) { // Check against available stock
                        ScaffoldMessenger.of(context).showSnackBar( // Inform user when requested quantity exceeds stock
                          SnackBar(content: Text('Not enough stock. Only ${p.stock} available.')),
                        );
                        return; // Abort if insufficient stock
                      }


                      // Success
                      // Use the new service method
                      UserCart.instance.addMultipleItems(p, quantityToAdd); // Add the requested quantity to the cart via UserCart


                      // Update the UI
                      setState(() {}); // Rebuild to reflect updated stock and cart counts


                      // Close modal
                      Navigator.of(context).pop(); // Dismiss the bottom sheet


                      // Show confirmation
                      ScaffoldMessenger.of(context).showSnackBar( // Show a snackbar confirming addition to cart
                        SnackBar(content: Text('Added $quantityToAdd x ${p.name} to cart')),
                      );
                    },
                    child: const Text('Add to Cart'), // Button label
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}


void _showReplenishBottomSheet(int index) { // Show a bottom sheet to add stock for the product at index
    final p = ProductService.instance.products[index]; // Get the product instance from the product service by index
    final controller = TextEditingController(); // Controller to read the user-entered replenish amount


    showModalBottomSheet( // Display a modal bottom sheet
      context: context, // Provide the current build context
      isScrollControlled: true, // Allow sheet to resize when keyboard appears
      builder: (context) { // Build the sheet's widget tree
        return Padding( // Add padding around the sheet contents
          padding: EdgeInsets.only( // Use edge insets allowing for keyboard inset
            left: 16, // Left padding 16
            right: 16, // Right padding 16
            top: 16, // Top padding 16
            bottom: MediaQuery.of(context).viewInsets.bottom + 16, // Bottom padding includes keyboard inset plus 16
          ),
          child: Column( // Vertical layout for sheet contents
            mainAxisSize: MainAxisSize.min, // Use minimal vertical space required by children
            children: [
              Text('Replenish ${p.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), // Title showing product name
              const SizedBox(height: 8), // Vertical spacer 8
              Align( // Align the following text to the left
                alignment: Alignment.centerLeft, // Left alignment
                child: Text('Current stock: ${p.stock}'), // Display current stock count
              ),
              const SizedBox(height: 8), // Vertical spacer 8
              TextField( // Input field for amount to add
                controller: controller, // Bind controller to read text
                keyboardType: TextInputType.number, // Numeric keyboard for integers
                decoration: const InputDecoration( // Decoration for the input
                  labelText: 'Amount to add', // Label shown above/inside field
                  hintText: 'Enter a positive integer', // Hint text guiding the user
                  border: OutlineInputBorder(), // Outline border around the field
                ),
              ),
              const SizedBox(height: 12), // Vertical spacer 12
              Row( // Horizontal row for action buttons
                mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the right
                children: [
                  TextButton( // Cancel button
                    onPressed: () => Navigator.of(context).pop(), // Close the modal without changes
                    child: const Text('Cancel'), // Button label
                  ),
                  const SizedBox(width: 8), // Horizontal spacer 8
                  ElevatedButton( // Add button to apply replenishment
                    onPressed: () { // Press handler for Add
                      final input = controller.text.trim(); // Read and trim the input string
                      final value = int.tryParse(input); // Try parsing input to int, yields null on invalid parse
                      if (value == null || value <= 0) { // Validate positive integer
                        ScaffoldMessenger.of(context).showSnackBar( // Show error if invalid
                          const SnackBar(content: Text('Please enter a positive integer')),
                        );
                        return; // Abort on invalid input
                      }
                      setState(() { // Update state to reflect stock change
                        p.stock += value; // Increase the product's stock by parsed value
                      });
                      Navigator.of(context).pop(); // Close the bottom sheet after successful addition
                      ScaffoldMessenger.of(context).showSnackBar( // Confirm addition with a snackbar
                        SnackBar(content: Text('Added $value to ${p.name} stock')),
                      );
                    },
                    child: const Text('Add'), // Button label
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  } // End of _showReplenishBottomSheet


  @override
  Widget build(BuildContext context) { // Build method for the product list screen
    final products = ProductService.instance.products; // Local reference to the products list


    return Container( // Outer container providing the background gradient
      decoration: const BoxDecoration( // Decoration configuration
        gradient: LinearGradient( // Linear gradient background
            begin: Alignment.topCenter, // Gradient start at top center
            end: Alignment.bottomCenter, // Gradient end at bottom center
            colors: [Color(0xffFFBF00), Color(0xffF85B1A)] // Two gradient colors
        ),
      ),
      child: Scaffold( // Scaffold provides app structure and safe areas
        backgroundColor: Colors.transparent, // Make scaffold background transparent to reveal gradient
        appBar: AppBar( // Top app bar for the screen
          title: const Text('Products', style: TextStyle(color: Colors.white)), // Title text styled white
          centerTitle: true, // Center the title
          iconTheme: const IconThemeData(color: Colors.white), // App bar icon color white
          backgroundColor: const Color(0xff072083), // App bar background color
        ),
        body: products.isEmpty // Conditional UI when there are no products
            ? const Center(
          child: Text('No products yet. Add one from the menu.'), // Prompt to add products
        )
            : ListView.builder( // Otherwise show a scrollable list of products
          padding: const EdgeInsets.all(8), // Padding around list
          itemCount: products.length, // Number of list items equals product count
          itemBuilder: (context, index) { // Builder for each list item
            final p = products[index]; // Product at current index
            final bool outOfStock = p.stock == 0; // Determine out-of-stock status


            return Dismissible( // Dismissible allows swipe-to-delete gesture
              key: ValueKey(p.hashCode + index), // Unique key combining hashCode and index
              direction: DismissDirection.endToStart, // Allow swipe from right to left only
              background: Container( // Background shown during swipe
                color: Colors.red, // Red background to indicate delete
                alignment: Alignment.centerRight, // Align icon to the right
                padding: const EdgeInsets.symmetric(horizontal: 16), // Horizontal padding inside background
                child: const Icon(Icons.delete, color: Colors.white), // Delete icon shown while swiping
              ),
              onDismissed: (_) => _removeAt(index), // Remove product when dismissed
              child: Card( // Card container for each product row
                color: outOfStock ? Colors.grey[300] : null, // Dim card when out of stock
                child: ListTile( // Standard list tile layout for product info
                  enabled: !outOfStock, // Disable tile interactions when out of stock
                  title: Text( // Product name title
                    p.name, // Show product name
                    style: TextStyle(
                      color: outOfStock ? Colors.grey[700] : null, // Grey text when out of stock
                    ),
                  ),
                  subtitle: Text( // Subtitle showing description, price, and stock
                    "Desc: ${p.desc}\nPrice: ₱${p.price.toStringAsFixed(2)}\nStock: ${p.stock}", // Formatted multi-line info
                    style: TextStyle(
                      color: outOfStock ? Colors.grey[700] : null, // Grey subtitle when out of stock
                    ),
                  ),
                  trailing: SizedBox( // Trailing area constrained in width for action icons
                    width: 150, // Fixed width for actions column
                    child: Row( // Row containing action icons
                      children: [
                        IconButton( // Button to add to cart
                          icon: Icon(
                            Icons.shopping_cart_checkout, // Checkout cart icon
                            color: outOfStock ? Colors.grey : Colors.green, // Greyed out when out of stock, green otherwise
                          ),


                          onPressed: p.stock > 0 // Enable only when stock > 0
                              ? () {
                                _showAddToCartModal(index); // Show add-to-cart modal for this product
                          }
                              : null, // Null disables the button
                        ),
                        IconButton( // Button to open replenish bottom sheet
                          icon: const Icon(
                            Icons.add_circle, // Add circle icon
                            color: Colors.blue, // Blue color for replenish action
                          ),
                          tooltip: 'Replenish stock', // Tooltip text
                          onPressed: () => _showReplenishBottomSheet(index), // Open replenish sheet for this index
                        ),
                        IconButton( // Button to delete the product
                          icon: Icon(
                            Icons.delete_forever, // Delete forever icon
                            color: outOfStock ? Colors.grey[700] : Colors.red, // Grey or red color depending on stock
                          ),
                          onPressed: () => _removeAt(index), // Remove product when pressed
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
  } // End of build
} // End of class


class CartScreen extends StatefulWidget { // Stateful widget that displays the user's shopping cart
  const CartScreen({super.key}); // Const constructor forwarding key to superclass


  @override
  State<CartScreen> createState() => _CartScreenState(); // Create the mutable state for this widget
}


class _CartScreenState extends State<CartScreen> { // State implementation for CartScreen
  void _update() { // Helper method to force a UI rebuild when cart changes
    setState(() {}); // Call setState with an empty callback to rebuild the widget tree
  }


  @override
  Widget build(BuildContext context) { // Build method that describes the UI
    final cart = UserCart.instance.cart; // Local reference to the singleton cart list


    return Container( // Outer container used to apply the background gradient
      decoration: const BoxDecoration( // Decoration for the container
          gradient:  LinearGradient( // Vertical linear gradient background
            begin: Alignment.topCenter, // Gradient starts at top center
            end:  Alignment.bottomCenter, // Gradient ends at bottom center
            colors: [Color(0xffFFBF00), Color(0xffF85B1A)] // Gradient colors
          ),
        ),
      child: Scaffold( // Scaffold provides app structure (app bar, body, etc.)
        backgroundColor: Colors.transparent, // Make scaffold background transparent so the gradient shows
        appBar: AppBar( // Top app bar for the cart screen
          title: const Text( // Title widget
            "Your Cart", // App bar title string
            style: TextStyle(color: Colors.white), // Title text color
          ),
          centerTitle: true, // Center the title horizontally
          iconTheme: IconThemeData( // Icon theme for app bar icons
            color: Colors.white // Icons colored white
          ),
          backgroundColor: const Color(0xff072083), // App bar background color
        ),
        body: cart.isEmpty // Conditional rendering based on whether the cart has items
            ? const Center( // If empty, show a centered message
          child: Text('Your cart is empty.'), // Message displayed when cart is empty
        )
            : Column( // If not empty, show the list of items and total area
          children: [
            Expanded( // Expanded so the list takes available vertical space above the total area
              child: ListView.builder( // Lazily-built scrollable list of cart items
                padding: const EdgeInsets.all(8), // Padding around list content
                itemCount: cart.length, // Number of items equals cart length
                itemBuilder: (context, index) { // Builder for each list entry
                  final item = cart[index]; // CartItem at current index
                  return Dismissible( // Dismissible to support swipe-to-delete of cart entries
                    key: ValueKey(item.product.hashCode), // Unique key for the dismissible using product hash
                    direction: DismissDirection.endToStart, // Allow swipe from right to left to dismiss
                    background: Container( // Background shown during swipe
                      color: Colors.red, // Red background to indicate deletion
                      alignment: Alignment.centerRight, // Align background icon to the right
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16), // Horizontal padding inside background
                      child: const Icon(Icons.delete, color: Colors.white), // Delete icon shown while swiping
                    ),
                    onDismissed: (_) { // Callback when the item is dismissed
                      UserCart.instance.removeItem(item); // Remove the item from the cart and restock product
                      _update(); // Trigger UI update
                    },
                    child: Card( // Card that contains the list tile for the cart item
                      child: ListTile( // ListTile for structured display of item info and controls
                        title: Text(item.product.name), // Product name as the title
                        subtitle: Text(
                            "Stock: ${item.product.stock} \nPrice: \₱${item.product.price.toStringAsFixed(2)}"), // Subtitle showing stock and formatted price
                        trailing: Row( // Trailing area containing quantity controls
                          mainAxisSize: MainAxisSize.min, // Row takes minimal horizontal space
                          children: [
                            IconButton( // Button to decrement quantity by one
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), // Remove icon styled red
                              onPressed: () { // When pressed
                                UserCart.instance.decrementItem(item); // Decrement item quantity and restock one unit
                                _update(); // Update UI to reflect change
                              },
                            ),
                            Text( // Display the current quantity
                              '${item.quantity}', // Show quantity as text
                              style: const TextStyle(fontSize: 16), // Font size for quantity text
                            ),
                            IconButton( // Button to increment quantity by one
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green), // Add icon styled green
                              onPressed: item.product.stock > 0 // Enable only if product still has stock
                                  ? () {
                                UserCart.instance.addItem(item.product); // Add one unit to the cart and decrement product stock
                                _update(); // Update UI after change
                              }
                                  : null, // Null disables the button when out of stock
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container( // Bottom container showing the total price
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Padding inside the total area
              decoration: BoxDecoration( // Decoration for the total area
                color: Colors.grey[100], // Light background color for contrast
                boxShadow: [ // Subtle shadow to separate the total area from the list
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Shadow color with opacity
                    spreadRadius: 0, // No spread
                    blurRadius: 5, // Blur radius for shadow
                    offset: const Offset(0, -2), // Slight upward offset to cast shadow above
                  ),
                ],
              ),
              child: Row( // Row to layout label and total amount
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space label and value apart
                children: [
                  const Text( // Label for the total
                    'Total:', // Label text
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold), // Styling for label
                  ),
                  Text( // Total amount text
                    '\₱${UserCart.instance.totalPrice.toStringAsFixed(2)}', // Formatted total price from cart
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green), // Styling for total amount
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