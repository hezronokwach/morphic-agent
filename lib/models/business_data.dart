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

class BusinessData {
  static List<Product> getProducts() {
    return [
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
  }

  static List<Expense> getExpenses() {
    return [
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
  }
}
