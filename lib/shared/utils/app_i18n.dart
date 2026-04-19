import 'package:flutter/widgets.dart';

class AppI18n {
  static const Map<String, Map<String, String>> _values = {
    'vi': {
      'settings.title': 'Cai dat ung dung',
      'settings.section.display': 'Hien thi',
      'settings.appearance': 'Giao dien',
      'settings.theme.light': 'Sang',
      'settings.theme.dark': 'Toi',
      'settings.theme.system': 'He thong',
      'settings.theme.label.light': 'Che do sang',
      'settings.theme.label.dark': 'Che do toi',
      'settings.theme.label.system': 'Theo he thong',
      'settings.section.language': 'Ngon ngu',
      'settings.language.vi': 'Tieng Viet',
      'settings.language.en': 'English',
      'settings.section.notifications': 'Thong bao',
      'settings.notifications.enable': 'Bat thong bao',
      'settings.notifications.enable.desc': 'Nhan thong bao tu ung dung',
      'settings.notifications.reminder': 'Nhac lich hen',
      'settings.notifications.reminder.desc': 'Nhac truoc gio kham',
      'settings.notifications.promo': 'Khuyen mai va tin tuc',
      'settings.notifications.promo.desc': 'Thong tin chuong trinh moi',
      'settings.section.suggestion': 'Goi y mo rong',
      'settings.suggestion.security':
          'Bao mat: doi mat khau, dang xuat moi thiet bi',
      'settings.suggestion.privacy':
          'Quyen rieng tu: an thong tin nhay cam tren ve kham',
      'settings.suggestion.data': 'Du lieu: xoa cache, dong bo lai du lieu',
      'settings.suggestion.help': 'Tro giup: FAQ, lien he ho tro, bao loi',
      'profile.settings': 'Cai dat ung dung',
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
