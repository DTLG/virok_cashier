import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../nomenclatura/domain/usecases/get_categories.dart';
import '../../../../nomenclatura/domain/usecases/get_subcategories.dart';
import '../../../../nomenclatura/domain/entities/nomenclatura.dart';
import '../../../data/models/category_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/home_bloc.dart';
import '../../../../../core/widgets/notificarion_toast/view.dart';

class CategoriesGrid extends StatefulWidget {
  const CategoriesGrid({super.key});

  @override
  State<CategoriesGrid> createState() => _CategoriesGridState();
}

class _CategoriesGridState extends State<CategoriesGrid> {
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Навігаційний стек для відстеження поточного шляху
  final List<CategoryModel> _navigationStack = [];
  CategoryModel? _currentCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (_currentCategory == null) {
        // Завантажуємо кореневі категорії
        final getCategories = GetIt.instance<GetCategories>();
        final result = await getCategories();

        result.fold(
          (failure) {
            setState(() {
              _errorMessage =
                  'Помилка завантаження категорій: ${failure.toString()}';
              _isLoading = false;
            });
          },
          (nomenclaturas) {
            final categories = nomenclaturas
                .map(
                  (nomenclatura) => CategoryModel.fromNomenclatura(
                    nomenclatura,
                    itemCount: _calculateItemCount(nomenclatura),
                  ),
                )
                .toList();

            setState(() {
              _categories = categories;
              _isLoading = false;
            });
          },
        );
      } else {
        // Завантажуємо підкатегорії поточної категорії
        final getSubcategories = GetIt.instance<GetSubcategories>();
        final result = await getSubcategories(_currentCategory!.id);

        result.fold(
          (failure) {
            setState(() {
              _errorMessage =
                  'Помилка завантаження підкатегорій: ${failure.toString()}';
              _isLoading = false;
            });
          },
          (nomenclaturas) {
            final items = nomenclaturas
                .map(
                  (nomenclatura) => CategoryModel.fromNomenclatura(
                    nomenclatura,
                    itemCount: nomenclatura.isFolder
                        ? _calculateItemCount(nomenclatura)
                        : 0,
                  ),
                )
                .toList();

            setState(() {
              _categories = items;
              _isLoading = false;
            });
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Невідома помилка: $e';
        _isLoading = false;
      });
    }
  }

  int _calculateItemCount(Nomenclatura nomenclatura) {
    // TODO: Реалізувати підрахунок товарів в категорії
    // Поки що повертаємо рандомне число для демонстрації
    return (nomenclatura.name.length % 20) + 1;
  }

  void _navigateToCategory(CategoryModel category) {
    if (category.isFolder) {
      // Перехід до підкатегорії
      setState(() {
        _navigationStack.add(category);
        _currentCategory = category;
      });
      _loadCategories();
    } else {
      // Клік по товару - додаємо до кошика або показуємо деталі
      context.read<HomeBloc>().add(
        AddToCart(
          guid: category.id,
          name: category.name,
          article: category.article ?? '',
          price: category.price,
        ),
      );
      ToastManager.show(
        context,
        type: ToastType.info,
        title: "Товар додано",
        actionLabel: 'Скасувати',
        onAction: () {
          context.read<HomeBloc>().add(RemoveFromCart(guid: category.id));
          ToastManager.show(
            context,
            type: ToastType.warning,
            title: "Товар видалено",
            message: "\"${category.name}\" видалено з кошика",
            position: ToastPosition.topRight,
          );
        },
        message: "\"${category.name}\" додано до кошика",
        position: ToastPosition.bottomLeft,
      );
    }
  }

  void _navigateBack() {
    if (_navigationStack.isNotEmpty) {
      setState(() {
        _navigationStack.removeLast();
        _currentCategory = _navigationStack.isNotEmpty
            ? _navigationStack.last
            : null;
      });
      _loadCategories();
    }
  }

  void _navigateToRoot() {
    setState(() {
      _navigationStack.clear();
      _currentCategory = null;
    });
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeViewState>(
      builder: (context, state) {
        // Якщо є результати пошуку, відображаємо їх
        if (state.searchResults.isNotEmpty) {
          return _buildSearchResults(state.searchResults);
        }

        // Інакше відображаємо звичайні категорії
        if (_isLoading) {
          return const Column(
            children: [
              Expanded(child: Center(child: CircularProgressIndicator())),
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Завантаження категорій...',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          );
        }

        if (_errorMessage != null) {
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCategories,
                        child: const Text('Спробувати ще раз'),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Категорії недоступні',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          );
        }

        if (_categories.isEmpty) {
          return Column(
            children: [
              // Breadcrumb навігація навіть для порожньої папки
              if (_currentCategory != null) _buildBreadcrumb(),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.folder_open_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentCategory != null
                            ? 'Папка "${_currentCategory!.name}" порожня'
                            : 'Категорії не знайдено',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentCategory != null
                            ? 'У цій папці немає товарів або підкатегорій'
                            : 'Спробуйте синхронізувати дані',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      if (_currentCategory != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _navigateBack,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Повернутися назад'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _currentCategory != null
                      ? 'Папка порожня'
                      : 'Оберіть категорію',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            // Breadcrumb навігація
            if (_currentCategory != null) _buildBreadcrumb(),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return _buildCategoryCard(category);
                },
              ),
            ),

            // Нижня панель з інформацією та кнопками
            _buildBottomPanel(),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(List<dynamic> searchResults) {
    return Column(
      children: [
        // Заголовок результатів пошуку
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'Результати пошуку (${searchResults.length})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Сітка результатів пошуку
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final nomenclatura = searchResults[index];
              final category = CategoryModel.fromNomenclatura(nomenclatura);
              return _buildCategoryCard(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToCategory(category),
          child: Column(
            children: [
              // Верхній сектор (більший) з іконкою та фоном
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(category.icon, size: 36, color: Colors.black87),
                  ),
                ),
              ),
              // Нижній сектор (менший) з інформацією, зміщеною нижче середини
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (!category.isFolder && category.price > 0)
                        Text(
                          '${category.price.toStringAsFixed(2)} грн',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      // if (category.isFolder)
                      //   Text(
                      //     '${category.itemCount} елементів',
                      //     style: const TextStyle(
                      //       fontSize: 12,
                      //       color: Colors.black54,
                      //     ),
                      //   )
                      // if (category.price > 0)
                      //   Text(
                      //     category.price.toStringAsFixed(2),
                      //     style: const TextStyle(
                      //       fontSize: 12,
                      //       color: Colors.black54,
                      //     ),
                      //   )
                      if (category.article?.isNotEmpty == true)
                        Text(
                          'Артикул: ${category.article}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        const SizedBox(height: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(bottom: BorderSide(color: Colors.grey[700]!)),
      ),
      child: Row(
        children: [
          // Кнопка "Назад"
          IconButton(
            onPressed: _navigateBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            tooltip: 'Повернутися назад',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _navigateToRoot,
            child: const Text(
              'Головна',
              style: TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ),
          for (int i = 0; i < _navigationStack.length; i++) ...[
            const Text(' > ', style: TextStyle(color: Colors.grey)),
            InkWell(
              onTap: () {
                // Перехід до конкретного рівня в стеку
                setState(() {
                  _navigationStack.removeRange(i + 1, _navigationStack.length);
                  _currentCategory = _navigationStack.isNotEmpty
                      ? _navigationStack.last
                      : null;
                });
                _loadCategories();
              },
              child: Text(
                _navigationStack[i].name,
                style: TextStyle(
                  color: i == _navigationStack.length - 1
                      ? Colors.white
                      : Colors.blue,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (_currentCategory != null) ...[
                TextButton.icon(
                  onPressed: _navigateBack,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Назад'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
                const SizedBox(width: 16),
              ],
              Text(
                _currentCategory == null
                    ? 'Категорії (${_categories.length})'
                    : '${_currentCategory!.name} (${_categories.length})',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Оновити'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
        ],
      ),
    );
  }
}
