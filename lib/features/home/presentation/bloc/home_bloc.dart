import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:get_it/get_it.dart';
import '../../../../core/services/storage_service.dart';
// import '../../../../core/services/cashalot_service.dart';
import '../../../../core/models/cashalot_models.dart';
import '../../../../services/vchasno_service.dart';
import '../../../../services/vchasno_errors.dart';
import '../../../../services/fiscal_result.dart';
import '../../../../services/x_report_data.dart';
import '../../../../services/terminal_payment_service.dart';
import '../../../../services/raw_printer_service.dart';
import '../../../../core/config/vchasno_config.dart';
import '../../data/datasources/shift_remote_data_source.dart';
import '../../data/datasources/check_remote_data_source.dart';
import '../../../login/domain/entities/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeViewState> {
  final StorageService storageService;
  final VchasnoService vchasnoService;
  final TerminalPaymentService terminalPaymentService =
      TerminalPaymentService();
  final RawPrinterService _rawPrinterService = RawPrinterService();
  final ShiftRemoteDataSource shiftRemoteDataSource = ShiftRemoteDataSource(
    Supabase.instance.client,
  );
  final CheckRemoteDataSource checkRemoteDataSource = CheckRemoteDataSource(
    Supabase.instance.client,
  );

  HomeBloc({required this.storageService, VchasnoService? vchasnoService})
    : vchasnoService = vchasnoService ?? GetIt.instance<VchasnoService>(),
      super(const HomeViewState()) {
    on<CheckUserLoginStatus>(_onCheckUserLoginStatus);
    on<LogoutUser>(_onLogoutUser);
    on<ToggleSidebarCollapsed>(_onToggleSidebarCollapsed);
    on<CheckTodayShiftPrompt>(_onCheckTodayShiftPrompt);
    on<CheckLastOpenedShift>(_onCheckLastOpenedShift);
    on<CheckShiftsSequentially>(_onCheckShiftsSequentially);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<CheckoutEvent>(_onCheckout);
    on<SetPaymentForm>(_onSetPaymentForm);
    on<PutOffCheckEvent>(_onPutOffCheck);
    on<SetSearchResults>(_onSetSearchResults);
    on<ClearSearchResults>(_onClearSearchResults);
    on<NavigateToPage>(_onNavigateToPage);
    on<OpenCashalotShift>(_onOpenCashalotShift);
    on<CloseCashalotShift>(_onCloseCashalotShift);
    on<ServiceDepositEvent>(_onServiceDeposit);
    on<ServiceIssueEvent>(_onServiceIssue);
    on<XReportEvent>(_onXReport);
    on<ClearXReportData>(_onClearXReportData);
  }

  /// Публічний метод для тестового депозиту (для використання з інших модулів)
  void testDeposit({required int prroFiscalNum, required String cashier}) {
    add(
      ServiceDepositEvent(
        amount: 1.0,
        prroFiscalNum: prroFiscalNum,
        cashier: cashier,
      ),
    );
  }

  /// Отримує активну касу (ПРРО)
  /// Для Vchasno не потрібно отримувати список ПРРО, повертаємо дефолтне значення
  Future<int> _getActivePrroFiscalNum() async {
    // Перевіряємо збережену касу
    final savedPrroNum = await storageService.getCashalotSelectedPrro();
    if (savedPrroNum != null) {
      try {
        final prroNum = int.parse(savedPrroNum);
        debugPrint('📋 [PRRO] Використовується збережена каса: $prroNum');
        return prroNum;
      } catch (e) {
        debugPrint('⚠️ [PRRO] Помилка парсингу збереженої каси: $e');
      }
    }

    // Для Vchasno не потрібно отримувати список ПРРО
    // Повертаємо дефолтне значення (не використовується в Vchasno API)
    debugPrint('📋 [PRRO] Використовується дефолтна каса для Vchasno');
    return 1; // Дефолтне значення, не використовується в Vchasno
  }

  Future<void> _onCheckUserLoginStatus(
    CheckUserLoginStatus event,
    Emitter<HomeViewState> emit,
  ) async {
    // emit(state.copyWith(status: HomeStatus.loading));

    // Перевіряємо чи користувач залогінений
    final isLoggedIn = await storageService.isUserLoggedIn();

    if (isLoggedIn) {
      // Отримуємо збережені дані користувача
      final email = await storageService.getUserEmail();
      final password = await storageService.getUserPassword();

      if (email != null && password != null) {
        // Створюємо об'єкт UserData з збережених даних
        final userData = UserData(
          id: '1',
          name: email.split('@')[0],
          email: email,
          password: password,
        );

        emit(state.copyWith(status: HomeStatus.loggedIn, user: userData));
      } else {
        // Якщо дані пошкоджені, очищаємо їх
        await storageService.clearUserCredentials();
        emit(state.copyWith(status: HomeStatus.initial, user: null));
      }
    } else {
      emit(state.copyWith(status: HomeStatus.initial, user: null));
    }
  }

  Future<void> _onLogoutUser(
    LogoutUser event,
    Emitter<HomeViewState> emit,
  ) async {
    // Очищаємо дані користувача
    await storageService.clearUserCredentials();
    emit(state.copyWith(status: HomeStatus.initial, user: null));
  }

  void _onToggleSidebarCollapsed(
    ToggleSidebarCollapsed event,
    Emitter<HomeViewState> emit,
  ) {
    emit(state.copyWith(isSidebarCollapsed: !state.isSidebarCollapsed));
  }

  Future<void> _onCheckTodayShiftPrompt(
    CheckTodayShiftPrompt event,
    Emitter<HomeViewState> emit,
  ) async {
    try {
      final latest = await shiftRemoteDataSource.getTodayLatestShift();
      if (latest == null) {
        emit(state.copyWith(openedShiftAt: null, shiftChecked: true));
        return;
      }
      final openedAtStr = latest['opened_at'] as String?;
      final closedAtStr = latest['closed_at'] as String?;
      final isOpen = closedAtStr == null || closedAtStr.isEmpty;
      final openedAt = openedAtStr != null ? DateTime.parse(openedAtStr) : null;
      emit(
        state.copyWith(
          openedShiftAt: isOpen ? openedAt : null,
          shiftChecked: true,
        ),
      );
    } catch (_) {
      emit(state.copyWith(openedShiftAt: null, shiftChecked: true));
    }
  }

  Future<void> _onCheckShiftsSequentially(
    CheckShiftsSequentially event,
    Emitter<HomeViewState> emit,
  ) async {
    // 2. Потім перевіряємо сьогоднішню
    await _onCheckTodayShiftPrompt(const CheckTodayShiftPrompt(), emit);
    // 1. Спочатку перевіряємо останню зміну
    await _onCheckLastOpenedShift(const CheckLastOpenedShift(), emit);
  }

  Future<void> _onCheckLastOpenedShift(
    CheckLastOpenedShift event,
    Emitter<HomeViewState> emit,
  ) async {
    try {
      final latest = await shiftRemoteDataSource
          .getLastOpenedShiftBeforeToday();
      if (latest == null) {
        // Не встановлюємо openedShiftAt: null, бо це перевірка попередньої зміни,
        // а не поточної. Поточний стан openedShiftAt не повинен змінюватися.
        emit(state.copyWith(status: HomeStatus.lastOpenedShiftClosed));
        return;
      }

      final closedAtStr = latest['closed_at'] as String?;
      final isOpen = closedAtStr == null || closedAtStr.isEmpty;

      if (isOpen) {
        emit(state.copyWith(status: HomeStatus.lastOpenedShiftOpen));
      } else {
        emit(state.copyWith(status: HomeStatus.lastOpenedShiftClosed));
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage: 'Помилка при перевірці попередньої зміни',
        ),
      );
    }
  }

  void _onAddToCart(AddToCart event, Emitter<HomeViewState> emit) {
    final existingIndex = state.cart.indexWhere((c) => c.guid == event.guid);
    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(state.cart);
      final current = updated[existingIndex];
      updated[existingIndex] = current.copyWith(quantity: current.quantity + 1);
      emit(state.copyWith(cart: updated));
    } else {
      final updated = List<CartItem>.from(state.cart)
        ..add(
          CartItem(
            guid: event.guid,
            name: event.name,
            article: event.article,
            price: event.price,
            quantity: 1,
          ),
        );
      emit(state.copyWith(cart: updated));
    }
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<HomeViewState> emit) {
    final updated = state.cart.where((c) => c.guid != event.guid).toList();
    emit(state.copyWith(cart: updated));
  }

  void _onUpdateCartItemQuantity(
    UpdateCartItemQuantity event,
    Emitter<HomeViewState> emit,
  ) {
    print('Updating cart item quantity: ${event.guid} -> ${event.quantity}');

    if (event.quantity <= 0) {
      // Якщо кількість 0 або менше, видаляємо товар з кошика
      print('Removing item from cart (quantity <= 0)');
      _onRemoveFromCart(RemoveFromCart(guid: event.guid), emit);
      return;
    }

    final updatedCart = state.cart.map((item) {
      if (item.guid == event.guid) {
        print(
          'Updated item: ${item.name} quantity from ${item.quantity} to ${event.quantity}',
        );
        return item.copyWith(quantity: event.quantity);
      }
      return item;
    }).toList();

    emit(state.copyWith(cart: updatedCart));
    print('Cart updated, new cart length: ${updatedCart.length}');
  }

  void _onSetPaymentForm(SetPaymentForm event, Emitter<HomeViewState> emit) {
    emit(state.copyWith(paymentForm: event.paymentForm));
  }

  Future<void> _onCheckout(
    CheckoutEvent event,
    Emitter<HomeViewState> emit,
  ) async {
    try {
      emit(state.copyWith(status: HomeStatus.loading));

      final cashierName =
          state.user?.name ??
          (await storageService.getUserEmail())?.split('@')[0] ??
          'Касир';

      if (state.cart.isEmpty) {
        throw Exception('Кошик порожній');
      }

      // Отримуємо активну касу
      final prroFiscalNum = await _getActivePrroFiscalNum();
      debugPrint('📋 [CHECKOUT] Використовується ПРРО: $prroFiscalNum');

      // Формуємо тіло чека з кошика
      debugPrint(
        '🛒 [CHECKOUT] Формування чека з кошика (${state.cart.length} товарів)...',
      );
      final checkBody = state.cart
          .map(
            (item) => CheckBodyRow(
              code: item.article.isNotEmpty ? item.article : item.guid,
              name: item.name,
              amount: item.quantity.toDouble(),
              price: item.price,
            ),
          )
          .toList();

      final totalSum = checkBody.fold(0.0, (sum, item) => sum + item.cost);

      // Формуємо CheckPayload
      final checkPayload = CheckPayload(
        checkHead: CheckHead(
          docType: "SaleGoods",
          docSubType: "CheckGoods",
          cashier: cashierName,
        ),
        checkTotal: CheckTotal(sum: totalSum),
        checkBody: checkBody,
        checkPay: [
          CheckPayRow(
            payFormNm: state.paymentForm, // "ГОТІВКА" або "КАРТКА"
            sum: totalSum,
          ),
        ],
      );

      // Логуємо тіло запиту
      debugPrint('📤 [CHECKOUT] Тіло запиту (CheckPayload):');
      debugPrint('   Касир: $cashierName');
      debugPrint('   Тип документа: ${checkPayload.checkHead.docType}');
      debugPrint('   Підтип: ${checkPayload.checkHead.docSubType}');
      debugPrint('   Сума: ${checkPayload.checkTotal.sum} UAH');
      debugPrint('   Метод оплати: ${checkPayload.checkPay.first.payFormNm}');
      debugPrint('   Товарів: ${checkPayload.checkBody.length}');
      for (var i = 0; i < checkPayload.checkBody.length; i++) {
        final item = checkPayload.checkBody[i];
        debugPrint(
          '     ${i + 1}. ${item.name} x${item.amount} = ${item.cost} UAH',
        );
      }
      debugPrint('📦 [CHECKOUT] JSON тіло запиту:');
      debugPrint(
        const JsonEncoder.withIndent('  ').convert(checkPayload.toJson()),
      );

      // Якщо обрано оплату КАРТКОЮ – спочатку проводимо операцію через термінал
      if (state.paymentForm.toUpperCase().contains('КАРТ')) {
        debugPrint(
          '💳 [CHECKOUT] Обрано оплату карткою – запускаємо TerminalPaymentService',
        );

        // КРОК 1: task 6 – запит на оплату з очікуванням підтвердження
        final preAuthResult = await terminalPaymentService.requestCardPreAuth(
          amount: totalSum,
        );

        if (!preAuthResult.success) {
          debugPrint(
            '❌ [CHECKOUT] Помилка на етапі pre-auth (task 6): ${preAuthResult.message}',
          );
          emit(
            state.copyWith(
              status: HomeStatus.error,
              errorMessage: preAuthResult.message ?? 'Помилка оплати карткою',
            ),
          );
          return;
        }

        final cardInfo = preAuthResult.cardInfo;
        if (cardInfo != null) {
          debugPrint('💳 [CHECKOUT] Картка: ${cardInfo.cardMask}');
          debugPrint(
            '💳 [CHECKOUT] Платіжна система: ${cardInfo.paymentSystem}',
          );
          debugPrint('💳 [CHECKOUT] Банк: ${cardInfo.bankName}');
        }

        // TODO: тут можна додати свою бізнес-логіку перевірки карти
        // (наприклад, заблоковані BIN-и, власні правила лояльності тощо)

        // КРОК 2: task 7 – підтверджуємо оплату по картці
        final finishResult = await terminalPaymentService.finishCardPayment(
          approve: true,
          overrideAmount: totalSum,
        );

        if (!finishResult.success) {
          debugPrint(
            '❌ [CHECKOUT] Помилка на етапі підтвердження (task 7): ${finishResult.message}',
          );
          emit(
            state.copyWith(
              status: HomeStatus.error,
              errorMessage:
                  finishResult.message ?? 'Помилка завершення оплати карткою',
            ),
          );
          return;
        }

        debugPrint(
          '✅ [CHECKOUT] Оплата по картці успішно проведена на терміналі',
        );

        // Друкуємо банківський сліп (термінальний чек) перед фіскальним чеком
        final String? slipText = finishResult.bankReceiptText;
        if (slipText != null && slipText.isNotEmpty) {
          debugPrint("🖨️ [CHECKOUT] Отримано текст банківського сліпа, друкуємо...");
          try {
            // Отримуємо налаштування принтера з SharedPreferences
            final printerIp =
                await storageService.getString('printer_ip') ??
                VchasnoConfig.printerIp;
            final printerPort =
                await storageService.getInt('printer_port') ??
                VchasnoConfig.printerPort;

            // Друкуємо ПЕРШУ копію (Клієнт)
            await _rawPrinterService.printBankSlip(
              printerIp: printerIp,
              slipText: slipText,
              port: printerPort,
            );
            debugPrint("✅ [CHECKOUT] Банківський сліп (клієнт) надруковано");

            // Друкуємо ДРУГУ копію (Мерчант) з паузою
            await Future.delayed(const Duration(seconds: 2));
            await _rawPrinterService.printBankSlip(
              printerIp: printerIp,
              slipText: slipText,
              port: printerPort,
            );
            debugPrint("✅ [CHECKOUT] Банківський сліп (мерчант) надруковано");
          } catch (e) {
            debugPrint(
              "⚠️ [CHECKOUT] Помилка друку банківського сліпа: $e",
            );
            // Не перериваємо процес, якщо друк сліпа не вдався
            // Фіскалізація все одно має пройти
          }
        } else {
          debugPrint(
            "⚠️ [CHECKOUT] Банк не повернув текст чека "
            "(можливо, він друкується самим терміналом?)",
          );
        }
      }

      // Після успішної (або готівкової) оплати проводимо фіскалізацію через Vchasno
      debugPrint(
        '🚀 [CHECKOUT] Відправка запиту printSale до VchasnoService...',
      );
      final fiscalResult = await vchasnoService.printSale(checkPayload);

      if (!fiscalResult.success) {
        debugPrint(
          '❌ [CHECKOUT] Помилка реєстрації чека: ${fiscalResult.message}',
        );
        // Зберігаємо помилку для показу діалогу
        emit(
          state.copyWith(
            status: HomeStatus.error,
            errorMessage: fiscalResult.message,
            vchasnoError: fiscalResult.error,
            fiscalResult: fiscalResult,
          ),
        );
        return;
      }

      debugPrint('✅ [CHECKOUT] Чек успішно зареєстровано через Вчасно!');

      // Зберігаємо чек в Supabase для історії
      debugPrint('💾 [CHECKOUT] Збереження чека в Supabase...');
      final items = state.cart.map((c) {
        final amount = c.quantity * c.price;
        return {
          'product_code': c.article.isNotEmpty ? c.article : c.guid,
          'product_name': c.name,
          'unit': 'шт',
          'quantity': c.quantity,
          'price': c.price,
          'discount_percent': 0,
          'amount': amount,
          'seller': cashierName,
        };
      }).toList();

      final checkId = await checkRemoteDataSource.createCheck(
        amount: totalSum,
        paymentForm: state.paymentForm,
        seller: state.user?.email ?? '',
      );
      debugPrint('   ID чека в Supabase: $checkId');

      await checkRemoteDataSource.insertCheckItems(checkId, items);
      debugPrint('   Збережено ${items.length} товарів');

      // Очистити кошик після успішного проведення чеку та зберегти результат для показу QR
      // Оновлюємо fiscalResult з сумою чека
      final finalResult = FiscalResult.success(
        message: fiscalResult.message,
        qrUrl: fiscalResult.qrUrl,
        docNumber: fiscalResult.docNumber,
        totalAmount: totalSum,
      );

      emit(
        state.copyWith(
          cart: const [],
          status: HomeStatus.checkedOut,
          fiscalResult: finalResult, // Зберігаємо для показу QR-коду
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage: e.toString(),
          vchasnoError: null,
          fiscalResult: null,
        ),
      );
    }
  }

  Future<void> _onPutOffCheck(
    PutOffCheckEvent event,
    Emitter<HomeViewState> emit,
  ) async {
    try {
      final seller = await storageService.getUserEmail() ?? '';
      if (state.cart.isEmpty) {
        throw Exception('Кошик порожній');
      }

      final items = state.cart.map((c) {
        final amount = c.quantity * c.price;
        return {
          'product_code': c.article.isNotEmpty ? c.article : c.guid,
          'product_name': c.name,
          'unit': 'шт',
          'quantity': c.quantity,
          'price': c.price,
          'discount_percent': 0,
          'amount': amount,
          'seller': seller,
        };
      }).toList();

      final totalAmount = state.cart.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      final checkId = await checkRemoteDataSource.createCheck(
        amount: totalAmount,
        paymentForm: state.paymentForm,
        seller: state.user?.email ?? '',
        status: 'Чек відкладений',
      );

      await checkRemoteDataSource.insertCheckItems(checkId, items);

      // Очистити кошик після успішного проведення чеку
      emit(state.copyWith(cart: const [], status: HomeStatus.putOffCheck));
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void _onSetSearchResults(
    SetSearchResults event,
    Emitter<HomeViewState> emit,
  ) {
    emit(state.copyWith(searchResults: event.results));
  }

  void _onClearSearchResults(
    ClearSearchResults event,
    Emitter<HomeViewState> emit,
  ) {
    emit(state.copyWith(searchResults: const []));
  }

  void _onNavigateToPage(NavigateToPage event, Emitter<HomeViewState> emit) {
    emit(state.copyWith(currentPage: event.pageRoute));
  }

  /// Відкриття зміни через VchasnoService
  /// Для Vchasno не потрібно відкривати зміну окремо
  Future<void> _onOpenCashalotShift(
    OpenCashalotShift event,
    Emitter<HomeViewState> emit,
  ) async {
    try {
      emit(state.copyWith(status: HomeStatus.loading));
      // debugPrint('🔓 [OPEN_SHIFT] Вчасно не потребує відкриття зміни окремо');
      await vchasnoService.openShift();
      debugPrint('✅ [OPEN_SHIFT] Готово до роботи');
      // Отримуємо X-звіт, але не зберігаємо в стані (не показуємо діалог)
      await vchasnoService.printXReport();
      emit(
        state.copyWith(
          status: HomeStatus.loggedIn,
          openedShiftAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('❌ [OPEN_SHIFT] Помилка: $e');
      emit(
        state.copyWith(status: HomeStatus.error, errorMessage: e.toString()),
      );
    }
  }

  /// Закриття зміни через VchasnoService (Z-звіт)
  Future<void> _onCloseCashalotShift(
    CloseCashalotShift event,
    Emitter<HomeViewState> emit,
  ) async {
    try {
      emit(state.copyWith(status: HomeStatus.loading));
      debugPrint('🔒 [CLOSE_SHIFT] Початок закриття зміни (Z-звіт)...');

      debugPrint(
        '🚀 [CLOSE_SHIFT] Відправка запиту printZReport до VchasnoService...',
      );
      final reportData = await vchasnoService.printZReport();

      if (reportData != null) {
        debugPrint('✅ [CLOSE_SHIFT] Z-звіт успішно отримано!');
        // Зберігаємо дані звіту, щоб показати діалог
        emit(
          state.copyWith(
            status: HomeStatus.loggedIn,
            xReportData: reportData,
            clearOpenedShiftAt: true,
          ),
        );
      } else {
        debugPrint('❌ [CLOSE_SHIFT] Не вдалося отримати Z-звіт');
        emit(state.copyWith(status: HomeStatus.loggedIn));
      }
    } catch (e) {
      debugPrint('❌ [CLOSE_SHIFT] Помилка: $e');
      emit(
        state.copyWith(status: HomeStatus.error, errorMessage: e.toString()),
      );
    }
  }

  /// Службове внесення грошей
  Future<void> _onServiceDeposit(
    ServiceDepositEvent event,
    Emitter<HomeViewState> emit,
  ) async {
    try {
      emit(state.copyWith(status: HomeStatus.loading));
      debugPrint('💰 [SERVICE_DEPOSIT] Початок службового внесення...');

      // Використовуємо касира з події, якщо вказано, інакше з state
      final cashierName =
          event.cashier ??
          state.user?.name ??
          (await storageService.getUserEmail())?.split('@')[0] ??
          'Касир';
      debugPrint('   Касир: $cashierName');
      debugPrint('   Сума: ${event.amount} UAH');

      debugPrint(
        '🚀 [SERVICE_DEPOSIT] Відправка запиту serviceIn до VchasnoService...',
      );
      debugPrint('   Сума: ${event.amount} UAH');
      debugPrint('   Касир: $cashierName');
      await vchasnoService.serviceIn(event.amount);

      debugPrint('✅ [SERVICE_DEPOSIT] Службове внесення успішно виконано!');

      emit(state.copyWith(status: HomeStatus.loggedIn));
    } catch (e) {
      debugPrint('❌ [SERVICE_DEPOSIT] Помилка: $e');
      emit(
        state.copyWith(status: HomeStatus.error, errorMessage: e.toString()),
      );
    }
  }

  /// Службова видача грошей
  Future<void> _onServiceIssue(
    ServiceIssueEvent event,
    Emitter<HomeViewState> emit,
  ) async {
    try {
      emit(state.copyWith(status: HomeStatus.loading));
      debugPrint('💸 [SERVICE_ISSUE] Початок службової видачі...');

      final cashierName =
          state.user?.name ??
          (await storageService.getUserEmail())?.split('@')[0] ??
          'Касир';
      debugPrint('   Касир: $cashierName');
      debugPrint('   Сума: ${event.amount} UAH');

      debugPrint(
        '🚀 [SERVICE_ISSUE] Відправка запиту serviceOut до VchasnoService...',
      );
      debugPrint('   Сума: ${event.amount} UAH');
      debugPrint('   Касир: $cashierName');
      await vchasnoService.serviceOut(event.amount);

      debugPrint('✅ [SERVICE_ISSUE] Службова видача успішно виконано!');
      emit(state.copyWith(status: HomeStatus.loggedIn));
    } catch (e) {
      debugPrint('❌ [SERVICE_ISSUE] Помилка: $e');
      emit(
        state.copyWith(status: HomeStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onXReport(
    XReportEvent event,
    Emitter<HomeViewState> emit,
  ) async {
    try {
      // emit(state.copyWith(status: HomeStatus.loading));
      debugPrint('🔒 [X_REPORT] Початок отримання X-звіту...');
      final reportData = await vchasnoService.printXReport();
      if (reportData != null) {
        debugPrint('✅ [X_REPORT] X-звіт успішно отримано!');
        emit(state.copyWith(xReportData: reportData));
      } else {
        debugPrint('❌ [X_REPORT] Не вдалося отримати X-звіт');
        emit(
          state.copyWith(
            status: HomeStatus.error,
            errorMessage: 'Не вдалося отримати X-звіт',
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [X_REPORT] Помилка: $e');
      emit(
        state.copyWith(status: HomeStatus.error, errorMessage: e.toString()),
      );
    }
  }

  /// Очищає дані X-звіту після показу
  void _onClearXReportData(
    ClearXReportData event,
    Emitter<HomeViewState> emit,
  ) {
    emit(state.copyWith(clearXReportData: true));
  }
}
