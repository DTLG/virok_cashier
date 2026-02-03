part of 'home_bloc.dart';

enum HomeStatus {
  initial,
  loading,
  loggedIn,
  error,
  checkedOut,
  putOffCheck,
  lastOpenedShiftOpen,
  lastOpenedShiftClosed,
}

class HomeViewState extends Equatable {
  final HomeStatus status;
  final UserData? user;
  final bool isSidebarCollapsed;
  final DateTime? openedShiftAt;
  final bool shiftChecked;
  final List<CartItem> cart;
  final String paymentForm; // 'Готівка', 'Картка', ...
  final String errorMessage;
  final List<dynamic> searchResults; // Результати пошуку
  final String currentPage; // Поточна сторінка
  final VchasnoException? vchasnoError; // Помилка Vchasno для показу діалогу
  final FiscalResult? fiscalResult; // Результат фіскалізації для показу QR
  final XReportData? xReportData; // Дані X-звіту для показу діалогу
  final List<PrroInfo>? prroInfo;

  const HomeViewState({
    this.status = HomeStatus.initial,
    this.user,
    this.isSidebarCollapsed = false,
    this.openedShiftAt,
    this.shiftChecked = false,
    this.cart = const [],
    this.paymentForm = 'Готівка',
    this.errorMessage = '',
    this.searchResults = const [],
    this.currentPage = '/menu', // За замовчуванням показуємо каталог
    this.vchasnoError,
    this.fiscalResult,
    this.xReportData,
    this.prroInfo,
  });

  HomeViewState copyWith({
    HomeStatus? status,
    UserData? user,
    bool? isSidebarCollapsed,
    DateTime? openedShiftAt,
    bool? shiftChecked,
    List<CartItem>? cart,
    String? paymentForm,
    String? errorMessage,
    List<dynamic>? searchResults,
    String? currentPage,
    VchasnoException? vchasnoError,
    FiscalResult? fiscalResult,
    XReportData? xReportData,
    List<PrroInfo>? prroInfo,
    // Спеціальні прапорці для явного встановлення null
    bool clearOpenedShiftAt = false,
    bool clearXReportData = false,
    bool clearFiscalResult = false,
    bool clearVchasnoError = false,
  }) {
    return HomeViewState(
      status: status ?? this.status,
      user: user ?? this.user,
      isSidebarCollapsed: isSidebarCollapsed ?? this.isSidebarCollapsed,
      openedShiftAt: clearOpenedShiftAt
          ? null
          : (openedShiftAt ?? this.openedShiftAt),
      shiftChecked: shiftChecked ?? this.shiftChecked,
      cart: cart ?? this.cart,
      paymentForm: paymentForm ?? this.paymentForm,
      errorMessage: errorMessage ?? this.errorMessage,
      searchResults: searchResults ?? this.searchResults,
      currentPage: currentPage ?? this.currentPage,
      vchasnoError: clearVchasnoError
          ? null
          : (vchasnoError ?? this.vchasnoError),
      fiscalResult: clearFiscalResult
          ? null
          : (fiscalResult ?? this.fiscalResult),
      xReportData: clearXReportData ? null : (xReportData ?? this.xReportData),
      prroInfo: prroInfo ?? this.prroInfo,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    isSidebarCollapsed,
    openedShiftAt,
    shiftChecked,
    cart,
    paymentForm,
    errorMessage,
    searchResults,
    currentPage,
    vchasnoError,
    fiscalResult,
    xReportData,
    prroInfo,
  ];
}

class CartItem extends Equatable {
  final String guid;
  final String name;
  final String article;
  final double price;
  final int quantity;

  const CartItem({
    required this.guid,
    required this.name,
    required this.article,
    required this.price,
    this.quantity = 1,
  });

  CartItem copyWith({
    String? guid,
    String? name,
    String? article,
    double? price,
    int? quantity,
  }) => CartItem(
    guid: guid ?? this.guid,
    name: name ?? this.name,
    article: article ?? this.article,
    price: price ?? this.price,
    quantity: quantity ?? this.quantity,
  );

  @override
  List<Object> get props => [guid, name, article, price, quantity];
}
