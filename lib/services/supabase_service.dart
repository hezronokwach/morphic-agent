import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business_data.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize(String url, String anonKey) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    
    // Initialize with sample data if tables are empty
    await _initializeSampleData();
  }

  static Future<void> _initializeSampleData() async {
    try {
      // Check if products exist
      final products = await client.from('products').select().limit(1);
      if (products.isEmpty) {
        await _insertSampleProducts();
      }

      // Check if account exists
      final account = await client.from('account').select().limit(1);
      if (account.isEmpty) {
        await client.from('account').insert({
          'id': 1,
          'balance': 10000.00,
        });
      }
    } catch (e) {
      // Silently handle initialization errors
    }
  }

  static Future<void> _insertSampleProducts() async {
    final sampleProducts = [
      {
        'id': '1',
        'name': 'Nike Air Max 270',
        'stock_count': 15,
        'price': 120.00,
        'image_url': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
        'category': 'shoes',
      },
      {
        'id': '2',
        'name': 'Adidas Ultraboost 22',
        'stock_count': 8,
        'price': 180.00,
        'image_url': 'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa',
        'category': 'shoes',
      },
      {
        'id': '3',
        'name': 'Converse Chuck Taylor',
        'stock_count': 25,
        'price': 65.00,
        'image_url': 'https://images.unsplash.com/photo-1549298916-b41d501d3772',
        'category': 'shoes',
      },
      {
        'id': '4',
        'name': 'Vans Old Skool',
        'stock_count': 12,
        'price': 60.00,
        'image_url': 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77',
        'category': 'shoes',
      },
      {
        'id': '5',
        'name': 'Puma RS-X',
        'stock_count': 6,
        'price': 110.00,
        'image_url': 'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519',
        'category': 'shoes',
      },
    ];

    await client.from('products').insert(sampleProducts);
  }

  // Product operations
  static Future<List<Product>> getProducts() async {
    final response = await client.from('products').select();
    return response.map((json) => Product.fromJson(json)).toList();
  }

  static Future<void> updateProductStock(String id, int newStock) async {
    await client.from('products').update({'stock_count': newStock}).eq('id', id);
  }

  static Future<void> addProduct(Product product) async {
    await client.from('products').insert(product.toJson());
  }

  static Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
  }

  // Account operations
  static Future<double> getAccountBalance() async {
    final response = await client.from('account').select('balance').eq('id', 1).single();
    return (response['balance'] as num).toDouble();
  }

  static Future<void> updateAccountBalance(double newBalance) async {
    await client.from('account').update({'balance': newBalance}).eq('id', 1);
  }

  // Expense operations
  static Future<List<Expense>> getExpenses() async {
    final response = await client.from('expenses').select().order('date', ascending: false);
    return response.map((json) => Expense.fromJson(json)).toList();
  }

  static Future<void> addExpense(Expense expense) async {
    await client.from('expenses').insert(expense.toJson());
  }
}