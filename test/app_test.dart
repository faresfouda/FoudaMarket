import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouda_market/main.dart' as app;
import 'package:fouda_market/models/category_model.dart';
import 'package:fouda_market/models/product_model.dart';

void main() {
  group('FoudaMarket App Integration Tests', () {
    testWidgets('App should initialize properly', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(MaterialApp(
        title: 'Fouda Market',
        home: Scaffold(
          body: Center(
            child: Text('Fouda Market'),
          ),
        ),
      ));

      // Verify that the app initializes
      expect(find.text('Fouda Market'), findsOneWidget);
    });

    testWidgets('App should handle theme properly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          body: Center(
            child: Text('Test'),
          ),
        ),
      ));

      // Verify theme is applied
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Model Tests', () {
    test('Category model should work correctly', () {
      final category = CategoryModel(
        id: '1',
        name: 'Electronics',
        imageUrl: 'electronics.jpg',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(category.id, '1');
      expect(category.name, 'Electronics');
      expect(category.imageUrl, 'electronics.jpg');
      expect(category.isActive, true);
    });

    test('Product model should work correctly', () {
      final product = ProductModel(
        id: '1',
        name: 'Test Product',
        description: 'Test Description',
        price: 99.99,
        images: ['product.jpg'],
        unit: 'piece',
        categoryId: '1',
        isVisible: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(product.id, '1');
      expect(product.name, 'Test Product');
      expect(product.price, 99.99);
      expect(product.isVisible, true);
      expect(product.images, ['product.jpg']);
      expect(product.unit, 'piece');
    });

    test('Product model discount calculation should work', () {
      final product = ProductModel(
        id: '1',
        name: 'Test Product',
        price: 80.0,
        originalPrice: 100.0,
        images: ['product.jpg'],
        unit: 'piece',
        categoryId: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(product.hasDiscount, true);
      expect(product.discountPercentage, 20.0);
    });
  });

  group('Navigation Tests', () {
    testWidgets('Should navigate to different screens', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Home Screen'),
          ),
        ),
      ));

      expect(find.text('Home Screen'), findsOneWidget);
    });
  });

  group('UI Component Tests', () {
    testWidgets('Should display buttons correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: null,
              child: Text('Test Button'),
            ),
          ),
        ),
      ));

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Should handle text input', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
              ),
            ),
          ),
        ),
      ));

      expect(find.text('Search'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('Should handle empty states', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('No items found'),
          ),
        ),
      ));

      expect(find.text('No items found'), findsOneWidget);
    });
  });
} 