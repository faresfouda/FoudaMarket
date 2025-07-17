# Blocs Architecture

This directory contains all the BLoC (Business Logic Component) classes for the FoudaMarket app.

## Structure

```
lib/blocs/
├── auth/                    # Authentication related blocs
│   ├── auth_bloc.dart      # Main authentication bloc
│   ├── auth_event.dart     # Authentication events
│   ├── auth_state.dart     # Authentication states
│   └── index.dart          # Auth exports
├── product/                # Product management blocs
│   ├── product_bloc.dart   # Main product management bloc
│   ├── product_event.dart  # Product events
│   ├── product_state.dart  # Product states
│   └── index.dart          # Product exports
├── category/               # Category management blocs
│   ├── category_bloc.dart  # Category management bloc
│   ├── category_event.dart # Category events
│   ├── category_state.dart # Category states
│   └── index.dart          # Category exports
├── favorites/              # Favorites management
│   ├── favorites_notifier.dart # Favorites state management
│   └── index.dart          # Favorites exports
├── index.dart              # Main exports
└── README.md               # This file
```

## Usage

### Importing Blocs

```dart
// Import all blocs
import 'package:fodamarket/blocs/index.dart';

// Import specific blocs
import 'package:fodamarket/blocs/auth/index.dart';
import 'package:fodamarket/blocs/product/index.dart';
import 'package:fodamarket/blocs/category/index.dart';
import 'package:fodamarket/blocs/favorites/index.dart';
```

### Using Blocs in Widgets

```dart
// Using ProductBloc
BlocProvider<ProductBloc>(
  create: (context) => ProductBloc(),
  child: BlocBuilder<ProductBloc, ProductState>(
    builder: (context, state) {
      if (state is ProductsLoading) {
        return CircularProgressIndicator();
      } else if (state is ProductsLoaded) {
        return ProductList(products: state.products);
      }
      return Container();
    },
  ),
);

// Using CategoryBloc
BlocProvider<CategoryBloc>(
  create: (context) => CategoryBloc(),
  child: BlocBuilder<CategoryBloc, CategoryState>(
    builder: (context, state) {
      if (state is CategoriesLoading) {
        return CircularProgressIndicator();
      } else if (state is CategoriesLoaded) {
        return CategoryList(categories: state.categories);
      }
      return Container();
    },
  ),
);

// Using FavoritesNotifier for immediate UI updates
ListenableBuilder(
  listenable: context.read<ProductBloc>().favoritesNotifier,
  builder: (context, child) {
    return FavoriteButton(
      isFavorite: context.read<ProductBloc>().favoritesNotifier.isProductFavorite(productId),
      onPressed: () {
        context.read<ProductBloc>().add(AddToFavorites(productId));
      },
    );
  },
);
```

## Key Features

### ProductBloc
- Product CRUD operations
- Search functionality (admin and user modes)
- Pagination support
- Favorites management
- Home screen data (best sellers, special offers, etc.)

### CategoryBloc
- Category CRUD operations
- Search functionality
- Pagination support

### AuthBloc
- User authentication
- Profile management
- Role-based navigation

### FavoritesNotifier
- Immediate UI updates for favorite actions
- Separate from main product loading states
- Uses ChangeNotifier for reactive updates

## Best Practices

1. **Always use BlocProvider** to provide blocs to the widget tree
2. **Use BlocBuilder** for reactive UI updates
3. **Use ListenableBuilder** for FavoritesNotifier updates
4. **Handle loading and error states** appropriately
5. **Use proper event dispatching** for user actions
6. **Keep blocs focused** on specific business logic domains
7. **Each bloc has its own directory** for better organization

## State Management Flow

1. **Event** → User action triggers an event
2. **Bloc** → Processes the event and updates state
3. **State** → New state is emitted
4. **UI** → Widget rebuilds based on new state

## Error Handling

All blocs include proper error handling:
- Network errors
- Validation errors
- Authentication errors
- Database errors

Errors are emitted as specific error states that can be handled in the UI.

## Directory Organization Benefits

- **Separation of Concerns**: Each bloc has its own directory
- **Easy Navigation**: Clear folder structure makes it easy to find specific blocs
- **Scalability**: Easy to add new blocs without cluttering existing ones
- **Maintainability**: Each bloc is self-contained with its own events, states, and logic
- **Team Collaboration**: Multiple developers can work on different blocs simultaneously 