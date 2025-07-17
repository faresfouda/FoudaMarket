import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../blocs/category/category_event.dart';
import '../../blocs/category/category_state.dart';
// import '../../models/category_model.dart';
import '../../theme/appcolors.dart';
import '../../views/category/category_screen.dart';
import 'dart:async';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  Timer? _debounceTimer;
  bool _isLoadingMore = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);
    // تحميل الفئات الأولية
    Future.microtask(() => context.read<CategoryBloc>().add(const FetchCategories(limit: CategoryBloc.defaultLimit)));
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200 && !_isLoadingMore) {
      final bloc = context.read<CategoryBloc>();
      final state = bloc.state;
      
      if (_isSearching) {
        // تحميل المزيد من نتائج البحث
        if (state is CategoriesSearchLoaded && state.hasMore) {
          _isLoadingMore = true;
          bloc.add(LoadMoreSearchResults(
            limit: CategoryBloc.defaultLimit,
            lastCategory: state.categories.isNotEmpty ? state.categories.last : null,
          ));
        }
      } else {
        // تحميل المزيد من الفئات العادية
        if (state is CategoriesLoaded && state.hasMore) {
          _isLoadingMore = true;
          bloc.add(LoadMoreCategories(
            limit: CategoryBloc.defaultLimit,
            lastCategory: state.categories.isNotEmpty ? state.categories.last : null,
          ));
        }
      }
    }
  }

  void _onLoadMoreFinished() {
    _isLoadingMore = false;
  }

  void _onSearchChanged(String value) {
    // إلغاء البحث السابق
    _debounceTimer?.cancel();
    
    // تأخير البحث لمدة 500 مللي ثانية لتجنب البحث المتكرر
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isNotEmpty) {
        setState(() {
          _isSearching = true;
        });
        context.read<CategoryBloc>().add(SearchCategories(value.trim()));
      } else {
        setState(() {
          _isSearching = false;
        });
        context.read<CategoryBloc>().add(const ClearSearch());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاقسام'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Search bar for categories - خارج BlocBuilder لتجنب إعادة البناء
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن الفئات...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Content area - فقط هذا الجزء يتم إعادة بنائه
            Expanded(
              child: BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (_isLoadingMore && (state is CategoriesLoaded || state is CategoriesSearchLoaded)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _isLoadingMore = false;
                      });
                    });
                  }

                  if (state is CategoriesLoading || state is CategoriesSearching) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('جاري التحميل...'),
                        ],
                      ),
                    );
                  } else if (state is CategoriesLoaded || state is CategoriesSearchLoaded) {
                    final categories = state is CategoriesLoaded 
                        ? state.categories 
                        : (state as CategoriesSearchLoaded).categories;
                    
                    if (categories.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSearching ? Icons.search_off : Icons.category_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isSearching ? 'لا توجد نتائج للبحث' : 'لا توجد فئات متاحة',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            if (_isSearching) ...[
                              const SizedBox(height: 8),
                              Text(
                                'جرب البحث بكلمات مختلفة',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    // مراقبة انتهاء التحميل
                    if (_isLoadingMore && !(state is CategoriesLoaded ? state.hasMore : (state as CategoriesSearchLoaded).hasMore)) {
                      _onLoadMoreFinished();
                    }

                    return Stack(
                      children: [
                        GridView.builder(
                          controller: _scrollController,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 20.0,
                  childAspectRatio: 0.8,
                ),
                          itemCount: categories.length,
                itemBuilder: (context, index) {
                            final category = categories[index];
                            Color bgColor = Colors.white;
                            if (category.color != null && category.color!.startsWith('#')) {
                              try {
                                bgColor = Color(int.parse(category.color!.replaceFirst('#', '0xff')));
                              } catch (e) {
                                bgColor = AppColors.lightGrayColor3;
                              }
                            }
                            
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryScreen(
                                      categoryName: category.name,
                                      categoryId: category.id,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.white,
                                      backgroundImage: (category.imageUrl != null && category.imageUrl!.isNotEmpty)
                                          ? NetworkImage(category.imageUrl!)
                                          : null,
                                      child: (category.imageUrl == null || category.imageUrl!.isEmpty)
                                          ? Icon(Icons.category, size: 40, color: AppColors.primary)
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        category.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (_isLoadingMore)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 8,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  } else if (state is CategoriesError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ في تحميل الفئات',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<CategoryBloc>().add(const FetchCategories(limit: CategoryBloc.defaultLimit));
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
