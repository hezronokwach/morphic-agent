import 'package:flutter/material.dart';
import '../models/business_data.dart';
import '../utils/app_theme.dart';

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
      child: Container(
        margin: const EdgeInsets.all(24.0),
        decoration: AppTheme.whiteCard(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.orange, width: 2),
                ),
                child: Icon(
                  _getIcon(),
                  size: 40,
                  color: AppTheme.orange,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getTitle(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _getDescription(),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.black,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionType == 'updateStock' && !canAfford) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Insufficient funds!',
                        style: TextStyle(
                          color: Colors.red,
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
                  Container(
                    decoration: AppTheme.blackCard(borderRadius: 8),
                    child: TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: canAfford ? AppTheme.orangeButton() : AppTheme.blackCard(borderRadius: 8),
                    child: TextButton(
                      onPressed: canAfford ? onConfirm : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        'CONFIRM',
                        style: TextStyle(
                          color: canAfford ? AppTheme.white : AppTheme.white.withOpacity(0.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
    return AppTheme.orange;
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
