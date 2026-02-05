part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

final class CheckUserLoginStatus extends HomeEvent {
  const CheckUserLoginStatus();
}

final class LogoutUser extends HomeEvent {
  const LogoutUser();
}

final class ToggleSidebarCollapsed extends HomeEvent {
  const ToggleSidebarCollapsed();
}

final class CheckTodayShiftPrompt extends HomeEvent {
  const CheckTodayShiftPrompt();
}

final class CheckShiftsSequentially extends HomeEvent {
  const CheckShiftsSequentially();
}

final class CheckLastOpenedShift extends HomeEvent {
  const CheckLastOpenedShift();
}

final class AddToCart extends HomeEvent {
  final String guid;
  final String name;
  final String article;
  final double price;

  const AddToCart({
    required this.guid,
    required this.name,
    required this.article,
    required this.price,
  });

  @override
  List<Object> get props => [guid, name, article, price];
}

final class RemoveFromCart extends HomeEvent {
  final String guid;

  const RemoveFromCart({required this.guid});

  @override
  List<Object> get props => [guid];
}

final class UpdateCartItemQuantity extends HomeEvent {
  final String guid;
  final int quantity;

  const UpdateCartItemQuantity({required this.guid, required this.quantity});

  @override
  List<Object> get props => [guid, quantity];
}

final class CheckoutEvent extends HomeEvent {
  const CheckoutEvent();
}

final class XReportEvent extends HomeEvent {
  const XReportEvent();
}

final class SetPaymentForm extends HomeEvent {
  final String paymentForm; // e.g., 'Готівка', 'Картка', 'Онлайн'

  const SetPaymentForm(this.paymentForm);

  @override
  List<Object> get props => [paymentForm];
}

final class PutOffCheckEvent extends HomeEvent {
  const PutOffCheckEvent();
}

final class SetSearchResults extends HomeEvent {
  final List<dynamic> results;

  const SetSearchResults({required this.results});

  @override
  List<Object> get props => [results];
}

final class ClearSearchResults extends HomeEvent {
  const ClearSearchResults();
}

/// Очищення даних X-звіту після показу
final class ClearXReportData extends HomeEvent {
  const ClearXReportData();
}

final class NavigateToPage extends HomeEvent {
  final String pageRoute;

  const NavigateToPage({required this.pageRoute});

  @override
  List<Object> get props => [pageRoute];
}

/// Відкриття зміни через CashalotService
final class OpenCashalotShift extends HomeEvent {
  final int? prroFiscalNum;
  final double amount;

  const OpenCashalotShift({this.prroFiscalNum, required this.amount});

  @override
  List<Object> get props => [prroFiscalNum ?? 0];
}

final class GetAvailablePrrosInfo extends HomeEvent {
  final int? prroFiscalNum;
  GetAvailablePrrosInfo({this.prroFiscalNum});

  @override
  List<Object> get props => [prroFiscalNum ?? 0];
}

/// Закриття зміни через CashalotService
final class CloseCashalotShift extends HomeEvent {
  final int? prroFiscalNum;

  const CloseCashalotShift({this.prroFiscalNum});

  @override
  List<Object> get props => [prroFiscalNum ?? 0];
}

/// Службове внесення грошей
final class ServiceDepositEvent extends HomeEvent {
  final double amount;
  final int? prroFiscalNum;
  final String? cashier;

  const ServiceDepositEvent({
    required this.amount,
    this.prroFiscalNum,
    this.cashier,
  });

  @override
  List<Object> get props => [amount, prroFiscalNum ?? 0, cashier ?? ''];
}

/// Службова видача грошей
final class ServiceIssueEvent extends HomeEvent {
  final double amount;
  final int? prroFiscalNum;

  const ServiceIssueEvent({required this.amount, this.prroFiscalNum});

  @override
  List<Object> get props => [amount, prroFiscalNum ?? 0];
}

final class CleanupCashalotEvent extends HomeEvent {
  final int? prroFiscalNum;

  const CleanupCashalotEvent({this.prroFiscalNum});

  @override
  List<Object> get props => [prroFiscalNum ?? 0];
}
