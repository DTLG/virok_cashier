class SyncUtils {
  static String formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Щойно';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} хв тому';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} год тому';
    } else {
      return '${difference.inDays} дн тому';
    }
  }

  static String getStatusText(String status) {
    switch (status) {
      case 'Дані актуальні':
        return 'Актуально';
      case 'Потребує оновлення':
        return 'Потребує оновлення';
      case 'Немає з\'єднання':
        return 'Немає мережі';
      case 'Немає локальних даних':
        return 'Немає даних';
      case 'Помилка при перевірці':
        return 'Помилка';
      default:
        return status;
    }
  }
}
