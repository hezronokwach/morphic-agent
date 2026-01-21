import 'package:flutter/material.dart';
import '../models/business_data.dart';

class ActionCard extends StatelessWidget {
  final String actionType;
  final Map<String, dynamic> actionData;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ActionCard({
    super.key,
    required this.actionType,
    required this.actionData,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = _checkAffordability();
    
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24.0),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIcon(),
                size: 64,
                color: _getColor(),
              ),
              const SizedBox(height: 16),
              Text(
                _getTitle(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _getDescription(),
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (actionType == 'updateStock' && !canAfford) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Insufficient funds!',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed: canAfford ? onConfirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford ? _getColor() : Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('CONFIRM'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _checkAffordability() {
    if (actionType == 'updateStock') {
      final quantity = actionData['quantity'] ?? 0;
      final productPrice = actionData['product_price'] ?? 0.0;
      final totalCost = quantity * productPrice;
      return Account.canAfford(totalCost);
    }
    return true;
  }

  IconData _getIcon() {
    switch (actionType) {
      case 'updateStock':
        return Icons.add_shopping_cart;
      case 'deleteProduct':
        return Icons.delete_forever;
      case 'addProduct':
        return Icons.add_circle;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColor() {
    switch (actionType) {
      case 'updateStock':
        return Colors.blue;
      case 'deleteProduct':
        return Colors.red;
      case 'addProduct':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTitle() {
    switch (actionType) {
      case 'updateStock':
        return 'Update Stock';
      case 'deleteProduct':
        return 'Delete Product';
      case 'addProduct':
        return 'Add Product';
      default:
        return 'Confirm Action';
    }
  }

  String _getDescription() {
    final productName = actionData['product_name'] ?? 'Unknown';
    
    switch (actionType) {
      case 'updateStock':
        final quantity = actionData['quantity'] ?? 0;
        final currentStock = actionData['current_stock'] ?? 0;
        final newStock = currentStock + quantity;
        final productPrice = actionData['product_price'] ?? 0.0;
        final totalCost = quantity * productPrice;
        final availableFunds = Account.getAvailableFunds();
        
        return 'Add $quantity units to $productName?\n'
               'Cost: \$${totalCost.toStringAsFixed(2)}\n'
               'New stock: $newStock units\n'
               'Available funds: \$${availableFunds.toStringAsFixed(2)}';
      case 'deleteProduct':
        return 'Delete $productName from inventory?\nThis action cannot be undone.';
      case 'addProduct':
        final price = actionData['price'] ?? 0;
        final stock = actionData['stock'] ?? 0;
        return 'Add $productName to inventory?\nPrice: \$$price, Stock: $stock units';
      default:
        return 'Are you sure you want to proceed?';
    }
  }
}
