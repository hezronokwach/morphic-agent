class Product {
  final String id;
  final String name;
  final int stockCount;
  final double price;
  final String imageUrl;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.stockCount,
    required this.price,
    required this.imageUrl,
    required this.category,
  });
}

class Expense {
  final String id;
  final String category;
  final double amount;
  final DateTime date;
  final String description;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
  });
}

class Account {
  static double _balance = 10000.0; // Starting balance
  static final List<Expense> _expenses = [];
  
  static double get balance => _balance;
  
  static void debit(double amount, String description, String productName) {
    _balance -= amount;
    
    // Extract brand/supplier from product name
    String supplier = 'General Supplier';
    
    // Split product name and use first word as brand
    final words = productName.split(' ');
    if (words.isNotEmpty) {
      final brand = words[0];
      supplier = '$brand Supplier';
    }
    
    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: supplier,
      amount: amount,
      date: DateTime.now(),
      description: description,
    );
    _expenses.add(expense);
    print('💳 Expense added: ${expense.category} - \$${amount.toStringAsFixed(2)} - $description');
    print('💳 Total expenses now: ${_expenses.length}');
  }
  
  static void credit(double amount) {
    _balance += amount;
  }
  
  static List<Expense> getExpenses() => List.from(_expenses);
  
  static double getTotalExpenses() {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }
  
  static double getAvailableFunds() {
    return _balance;
  }
  
  static bool canAfford(double amount) {
    return _balance >= amount;
  }
}

class BusinessData {
  static final List<Product> _products = [
    Product(
      id: '1',
      name: 'Nike Air Max',
      stockCount: 15,
      price: 120.0,
      imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
      category: 'shoes',
    ),
    Product(
      id: '2',
      name: 'Adidas Ultraboost',
      stockCount: 8,
      price: 150.0,
      imageUrl: 'https://images.unsplash.com/photo-1608231387042-66d1773070a5',
      category: 'shoes',
    ),
    Product(
      id: '3',
      name: 'Puma Running Shoes',
      stockCount: 22,
      price: 95.0,
      imageUrl: 'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa',
      category: 'shoes',
    ),
    Product(
      id: '4',
      name: 'Reebok Classic',
      stockCount: 12,
      price: 85.0,
      imageUrl: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a',
      category: 'shoes',
    ),
    Product(
      id: '5',
      name: 'New Balance 574',
      stockCount: 18,
      price: 110.0,
      imageUrl: 'https://images.unsplash.com/photo-1539185441755-769473a23570',
      category: 'shoes',
    ),
  ];

  static List<Product> getProducts() => List.from(_products);

  static void updateStock(String productId, int newStock) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final product = _products[index];
      _products[index] = Product(
        id: product.id,
        name: product.name,
        stockCount: newStock,
        price: product.price,
        imageUrl: product.imageUrl,
        category: product.category,
      );
    }
  }

  static void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
  }

  static void addProduct(Product product) {
    _products.add(product);
  }

  static List<Expense> getExpenses() {
    // Combine fixed expenses with account expenses
    final fixedExpenses = [
      Expense(
        id: '1',
        category: 'Nike Supplier',
        amount: 3500.0,
        date: DateTime(2025, 1, 12),
        description: 'Quarterly shoe order',
      ),
      Expense(
        id: '2',
        category: 'Rent',
        amount: 2000.0,
        date: DateTime(2025, 1, 1),
        description: 'January rent',
      ),
      Expense(
        id: '3',
        category: 'Utilities',
        amount: 450.0,
        date: DateTime(2025, 1, 5),
        description: 'Electricity and water',
      ),
      Expense(
        id: '4',
        category: 'Marketing',
        amount: 800.0,
        date: DateTime(2025, 1, 15),
        description: 'Social media ads',
      ),
    ];
    
    final accountExpenses = Account.getExpenses();
    print('📊 getExpenses called: ${fixedExpenses.length} fixed + ${accountExpenses.length} account = ${fixedExpenses.length + accountExpenses.length} total');
    
    return [...fixedExpenses, ...accountExpenses];
  }
}
