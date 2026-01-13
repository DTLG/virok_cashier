import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../nomenclatura/domain/usecases/search_nomenclatura.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(List<dynamic>)? onSearchResults;
  final Function()? onClearSearch;

  const SearchBarWidget({super.key, this.onSearchResults, this.onClearSearch});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      widget.onClearSearch?.call();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final searchNomenclatura = GetIt.instance<SearchNomenclatura>();
      final result = await searchNomenclatura(query.trim().toLowerCase());

      result.fold(
        (failure) {
          // Помилка пошуку - показуємо порожній результат
          widget.onSearchResults?.call([]);
        },
        (nomenclaturas) {
          // Успішний пошук - передаємо результати
          widget.onSearchResults?.call(nomenclaturas);
        },
      );
    } catch (e) {
      // Обробка помилок
      widget.onSearchResults?.call([]);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    // Дебаунс для уникнення занадто частих запитів
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text == value) {
        _performSearch(value);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onClearSearch?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Пошук товарів...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: _isSearching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  ),
                )
              : const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
