import 'package:flutter/widgets.dart';

class AppI18n {
  static const Map<String, Map<String, String>> _values = {
    'vi': {
      'settings.title': 'Cài đặt ứng dụng',
      'settings.section.display': 'Hiển thị',
      'settings.appearance': 'Giao diện',
      'settings.theme.light': 'Sáng',
      'settings.theme.dark': 'Tối',
      'settings.theme.system': 'Hệ thống',
      'settings.theme.label.light': 'Chế độ sáng',
      'settings.theme.label.dark': 'Chế độ tối',
      'settings.theme.label.system': 'Theo hệ thống',
      'settings.section.language': 'Ngôn ngữ',
      'settings.language.vi': 'Tiếng Việt',
      'settings.language.en': 'English',
      'settings.section.notifications': 'Thông báo',
      'settings.notifications.enable': 'Bật thông báo',
      'settings.notifications.enable.desc': 'Nhận thông báo từ ứng dụng',
      'settings.notifications.reminder': 'Nhắc lịch hẹn',
      'settings.notifications.reminder.desc': 'Nhắc trước giờ khám',
      'settings.notifications.promo': 'Khuyến mãi và tin tức',
      'settings.notifications.promo.desc': 'Thông tin chương trình mới',
      'settings.section.suggestion': 'Gợi ý mở rộng',
      'settings.suggestion.security':
          'Bảo mật: đổi mật khẩu, đăng xuất mọi thiết bị',
      'settings.suggestion.privacy':
          'Quyền riêng tư: ẩn thông tin nhạy cảm trên vé khám',
      'settings.suggestion.data': 'Dữ liệu: xóa cache, đồng bộ lại dữ liệu',
      'settings.suggestion.help': 'Trợ giúp: FAQ, liên hệ hỗ trợ, báo lỗi',
      'profile.settings': 'Cài đặt ứng dụng',
    },
    'en': {
      'settings.title': 'App Settings',
      'settings.section.display': 'Display',
      'settings.appearance': 'Appearance',
      'settings.theme.light': 'Light',
      'settings.theme.dark': 'Dark',
      'settings.theme.system': 'System',
      'settings.theme.label.light': 'Light mode',
      'settings.theme.label.dark': 'Dark mode',
      'settings.theme.label.system': 'Follow system',
      'settings.section.language': 'Language',
      'settings.language.vi': 'Vietnamese',
      'settings.language.en': 'English',
      'settings.section.notifications': 'Notifications',
      'settings.notifications.enable': 'Enable notifications',
      'settings.notifications.enable.desc': 'Receive app notifications',
      'settings.notifications.reminder': 'Appointment reminders',
      'settings.notifications.reminder.desc': 'Remind before appointment time',
      'settings.notifications.promo': 'Promotions and news',
      'settings.notifications.promo.desc': 'Latest campaign updates',
      'settings.section.suggestion': 'Suggested next settings',
      'settings.suggestion.security':
          'Security: change password, sign out from all devices',
      'settings.suggestion.privacy':
          'Privacy: hide sensitive data on booking ticket',
      'settings.suggestion.data': 'Data: clear cache, force sync',
      'settings.suggestion.help': 'Support: FAQ, contact support, report issue',
      'profile.settings': 'App Settings',
    },
  };

  static String tr(BuildContext context, String key) {
    final lang = Localizations.localeOf(context).languageCode;
    return _values[lang]?[key] ?? _values['vi']?[key] ?? key;
  }
}

extension AppI18nX on BuildContext {
  String tr(String key) => AppI18n.tr(this, key);
}
