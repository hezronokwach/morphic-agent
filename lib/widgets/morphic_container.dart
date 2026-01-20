import 'package:flutter/material.dart';
import '../models/morphic_state.dart';
import '../models/business_data.dart';
import 'inventory_table.dart';
import 'finance_chart.dart';
import 'product_image_card.dart';

class MorphicContainer extends StatelessWidget {
  final MorphicState state;

  const MorphicContainer({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: _buildContentForMode(),
    );
  }

  Widget _buildContentForMode() {
    return Container(
      key: ValueKey(state.uiMode),
      child: _getWidgetForMode(),
    );
  }

  Widget _getWidgetForMode() {
    print('🎨 Building widget for mode: ${state.uiMode}');
    print('🎨 Data keys available: ${state.data.keys.toList()}');
    
    switch (state.uiMode) {
      case UIMode.table:
        final products = state.data['products'] as List<Product>? ?? [];
        print('🎨 Table: ${products.length} products');
        return InventoryTable(products: products);

      case UIMode.chart:
        final expenses = state.data['expenses'] as List<Expense>? ?? [];
        print('🎨 Chart: ${expenses.length} expenses');
        if (expenses.isEmpty) {
          print('⚠️ WARNING: No expenses data!');
        }
        return FinanceChart(expenses: expenses);

      case UIMode.image:
        final product = state.data['product'] as Product?;
        print('🎨 Image: ${product?.name ?? "null"}');
        if (product != null) {
          return ProductImageCard(product: product);
        }
        return _buildNarrativeView();

      case UIMode.narrative:
      default:
        print('🎨 Narrative mode');
        return _buildNarrativeView();
    }
  }

  Widget _buildNarrativeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.confidence < 0.7) ...[
              const Icon(Icons.help_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                "I'm not quite sure. Could you rephrase?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              state.narrative,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
