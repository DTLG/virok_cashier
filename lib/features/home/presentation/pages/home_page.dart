import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/services/prro/prro_service.dart';
import '../bloc/home_bloc.dart';
import '../widgets/navigation/sidebar_navigation.dart';
import '../widgets/pages/page_content.dart';
import '../widgets/header/cashier_header.dart';
import '../widgets/cart/cart_items_list.dart';
import '../widgets/payment/payment_method_selector.dart';
import '../widgets/cart/checkout_button.dart';
import '../widgets/common/home_loading_widget.dart';
import '../dialogs/open_shift_dialog.dart';
import '../dialogs/shift_already_open_dialog.dart';
import '../../../../core/widgets/notificarion_toast/view.dart';
import '../dialogs/close_prev_shift_dialog.dart';
import '../dialogs/vchasno_error_dialog.dart';
import '../dialogs/order_success_dialog.dart';
import '../dialogs/x_report_dialog.dart';
import '../../../login/presentation/pages/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _openShiftPromptShown = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        storageService: StorageService(),
        prroService: GetIt.instance<PrroService>(),
      )..add(GetAvailablePrrosInfo()),
      child: MultiBlocListener(
        listeners: [
          // 1. Загальний слухач для toasts/помилок/навігації
          BlocListener<HomeBloc, HomeViewState>(listener: _handleStateChanges),
          // 2. Окремий слухач тільки коли X-звіт з'явився (null -> not null)
          BlocListener<HomeBloc, HomeViewState>(
            listenWhen: (prev, curr) =>
                prev.xReportData == null && curr.xReportData != null,
            listener: (context, state) {
              final report = state.xReportData;
              if (report == null) return;

              // Визначаємо тип звіту за полем task (10 = X, 11 = Z)
              final isZReport = report.task == 11;
              final title = isZReport
                  ? 'Z-Звіт (Закриття зміни)'
                  : 'X-Звіт (Поточний)';

              showDialog(
                context: context,
                builder: (ctx) =>
                    XReportDialog(reportData: report, title: title),
              ).then((_) {
                if (context.mounted) {
                  context.read<HomeBloc>().add(const ClearXReportData());
                }
              });
            },
          ),
        ],
        child: BlocBuilder<HomeBloc, HomeViewState>(
          builder: (context, state) {
            _handleInitialChecks(context, state);
            return _buildContent(context, state);
          },
        ),
      ),
    );
  }

  /// Обробка змін стану (toasts, діалоги, навігація)
  void _handleStateChanges(BuildContext context, HomeViewState state) async {
    switch (state.status) {
      case HomeStatus.loggedIn:
        // Після успішного логіну перевіряємо попередню зміну
        if (!state.shiftChecked) {
          context.read<HomeBloc>().add(const CheckLastOpenedShift());
        }
        break;

      case HomeStatus.lastOpenedShiftOpen:
        ToastManager.show(
          context,
          type: ToastType.error,
          title: 'Попередня зміна відкрита',
          message: 'Потрібно закрити попередню зміну',
          duration: const Duration(seconds: 4),
        );
        await closePreviousShiftDialog(context);
        if (context.mounted) {
          context.read<HomeBloc>().add(const CheckUserLoginStatus());
        }
        break;

      case HomeStatus.error:
        // Перевіряємо чи це помилка Vchasno
        if (state.vchasnoError != null) {
          // Показуємо спеціальний діалог для помилок Vchasno
          showVchasnoErrorDialog(context, state.vchasnoError!);
        } else {
          // Звичайна помилка - показуємо toast
          ToastManager.show(
            context,
            type: ToastType.error,
            title: 'Помилка',
            exception: Exception(state.errorMessage),
          );
        }
        // Очищаємо помилку після показу
        context.read<HomeBloc>().add(const CheckUserLoginStatus());
        break;

      case HomeStatus.lastOpenedShiftClosed:
        context.read<HomeBloc>().add(const CheckUserLoginStatus());
        break;

      case HomeStatus.checkedOut:
        // Показуємо діалог з QR-кодом, якщо є результат фіскалізації
        if (state.fiscalResult != null && state.fiscalResult!.success) {
          final fiscalResult = state.fiscalResult!;
          final totalAmount = fiscalResult.totalAmount ?? 0.0;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => OrderSuccessDialog(
              qrUrl: fiscalResult.qrUrl,
              docNumber: fiscalResult.docNumber,
              totalAmount: totalAmount,
            ),
          );
        } else {
          ToastManager.show(
            context,
            type: ToastType.success,
            title: 'Чек проведений успішно',
          );
        }
        context.read<HomeBloc>().add(const CheckUserLoginStatus());
        break;

      case HomeStatus.putOffCheck:
        ToastManager.show(
          context,
          type: ToastType.success,
          title: 'Чек відкладено',
        );
        context.read<HomeBloc>().add(const CheckUserLoginStatus());
        break;

      default:
        break;
    }
  }

  /// Початкові перевірки при рендері
  void _handleInitialChecks(BuildContext context, HomeViewState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.status == HomeStatus.initial) {
        // Спочатку перевіряємо чи користувач залогінений
        context.read<HomeBloc>().add(const CheckUserLoginStatus());
      }
    });
  }

  /// Побудова контенту на основі стану
  Widget _buildContent(BuildContext context, HomeViewState state) {
    switch (state.status) {
      case HomeStatus.initial:
        return const LoginPage();

      case HomeStatus.loading:
      case HomeStatus.lastOpenedShiftOpen:
      case HomeStatus.returnLoading:
        return const HomeLoadingWidget();

      case HomeStatus.loggedIn:
      case HomeStatus.checkedOut:
      case HomeStatus.putOffCheck:
      case HomeStatus.error:
      case HomeStatus.returnSuccess:
      case HomeStatus.returnError:
        return _buildLoggedInContent(context, state);

      case HomeStatus.lastOpenedShiftClosed:
        // Перехідний стан, показуємо loading
        return const HomeLoadingWidget();

      case HomeStatus.kkmSearchSuccess:
        return _buildLoggedInContent(context, state);

      case HomeStatus.cleanupCashalot:
        return const HomeLoadingWidget();

      case HomeStatus.cleanupSuccess:
        return _buildLoggedInContent(context, state);
    }
  }

  /// Побудова контенту для авторизованого користувача
  Widget _buildLoggedInContent(BuildContext context, HomeViewState state) {
    // Перевіряємо зміну, якщо ще не перевірена
    if (!state.shiftChecked) {
      context.read<HomeBloc>().add(const CheckTodayShiftPrompt());
      return const HomeLoadingWidget();
    }

    // Показуємо діалог зміни один раз
    _showShiftDialogIfNeeded(context, state);

    return _buildMainContent(context, state);
  }

  /// Показ діалогу зміни (якщо потрібно)
  void _showShiftDialogIfNeeded(BuildContext context, HomeViewState state) {
    if (_openShiftPromptShown) return;

    _openShiftPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (state.openedShiftAt != null) {
        await showShiftAlreadyOpenDialog(
          context,
          openedAt: state.openedShiftAt!,
        );
      } else {
        showOpenShiftDialog(context);
      }
    });
  }

  /// Побудова основного контенту (sidebar + контент + кошик)
  Widget _buildMainContent(BuildContext context, HomeViewState state) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Row(
        children: [
          _buildSidebar(context, state),
          _buildPageContent(),
          if (state.currentPage == '/menu') _buildCart(),
        ],
      ),
    );
  }

  /// Побудова sidebar
  Widget _buildSidebar(BuildContext context, HomeViewState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: state.isSidebarCollapsed ? 72 : 280,
      color: const Color(0xFF2A2A2A),
      child: Column(
        children: [
          _buildSidebarHeader(context, state),
          Expanded(child: _buildSidebarNavigation(state)),
        ],
      ),
    );
  }

  /// Заголовок sidebar з логотипом
  Widget _buildSidebarHeader(BuildContext context, HomeViewState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              context.read<HomeBloc>().add(const ToggleSidebarCollapsed());
            },
            child: const Icon(Icons.menu, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.horizontal,
                  child: child,
                ),
              );
            },
            child: state.isSidebarCollapsed
                ? const SizedBox.shrink(key: ValueKey('collapsed_text'))
                : const Text(
                    'Virok',
                    key: ValueKey('expanded_text'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Навігація sidebar
  Widget _buildSidebarNavigation(HomeViewState state) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: child,
          ),
        );
      },
      child: state.isSidebarCollapsed
          ? const SizedBox.shrink(key: ValueKey('collapsed'))
          : const SidebarNavigation(key: ValueKey('expanded')),
    );
  }

  /// Основний контент сторінки
  Widget _buildPageContent() {
    return Expanded(
      child: Container(
        color: const Color(0xFF1E1E1E),
        child: const PageContent(),
      ),
    );
  }

  /// Кошик (тільки для каталогу)
  Widget _buildCart() {
    return Container(
      width: 350,
      color: const Color(0xFF2A2A2A),
      child: Column(
        children: [
          const CashierHeader(),
          const Expanded(child: CartItemsList()),
          Container(
            padding: const EdgeInsets.all(20),
            child: const PaymentMethodSelector(),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: const CheckoutButton(),
          ),
        ],
      ),
    );
  }
}
