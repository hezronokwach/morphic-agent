import '../services/supabase_service.dart';

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

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      stockCount: json['stock_count'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stock_count': stockCount,
      'price': price,
      'image_url': imageUrl,
      'category': category,
    };
  }
}

class Expense {
  final String? id;
  final String category;
  final double amount;
  final DateTime date;
  final String description;

  Expense({
    this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString(),
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
    };
  }
}

class Account {
  static Future<double> getAvailableFunds() async {
    return await SupabaseService.getAccountBalance();
  }
  
  static Future<void> debit(double amount, String description, String productName) async {
    final currentBalance = await getAvailableFunds();
    final newBalance = currentBalance - amount;
    await SupabaseService.updateAccountBalance(newBalance);
    
    // Extract brand/supplier from product name
    String supplier = 'General Supplier';
    final words = productName.split(' ');
    if (words.isNotEmpty) {
      final brand = words[0];
      supplier = '$brand Supplier';
    }
    
    final expense = Expense(
      category: supplier,
      amount: amount,
      date: DateTime.now(),
      description: description,
    );
    
    await SupabaseService.addExpense(expense);
  }
  
  static Future<bool> canAfford(double amount) async {
    final balance = await getAvailableFunds();
    return balance >= amount;
  }
}

class BusinessData {
  static Future<List<Product>> getProducts() async {
    return await SupabaseService.getProducts();
  }

  static Future<void> updateStock(String productId, int newStock) async {
    await SupabaseService.updateProductStock(productId, newStock);
  }

  static Future<void> deleteProduct(String productId) async {
    await SupabaseService.deleteProduct(productId);
  }

  static Future<void> addProduct(Product product) async {
    await SupabaseService.addProduct(product);
  }

  static Future<List<Expense>> getExpenses() async {
    return await SupabaseService.getExpenses();
  }
}
