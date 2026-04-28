import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings': 'Settings',
      'account': 'Account',
      'edit_name': 'Edit Name',
      'delete_account': 'Delete Account',
      'appearance': 'Appearance',
      'language': 'Language',
      'font_size': 'Font Size',
      'dark_mode': 'Dark Mode',
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm_delete': 'Are you sure you want to delete your account? This will clear your registration data.',
      'delete': 'Delete',
      'english': 'English',
      'arabic': 'Arabic',
      'reconnect': 'Reconnect to Laptop',
      'scan_qr': 'Scan QR Code',
      'select_member': 'Select Member Screen',
      'history': 'History Screen',
      'test': 'Test',
    },
    'ar': {
      'settings': 'الإعدادات',
      'account': 'الحساب',
      'edit_name': 'تعديل الاسم',
      'delete_account': 'حذف الحساب',
      'appearance': 'المظهر',
      'language': 'اللغة',
      'font_size': 'حجم الخط',
      'dark_mode': 'الوضع الليلي',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'confirm_delete': 'هل أنت متأكد أنك تريد حذف حسابك؟ سيؤدي ذلك إلى مسح بيانات التسجيل الخاصة بك.',
      'delete': 'حذف',
      'english': 'English',
      'arabic': 'العربية',
      'reconnect': 'إعادة الاتصال بالكمبيوتر',
      'scan_qr': 'مسح رمز QR',
      'select_member': 'شاشة اختيار الأعضاء',
      'history': 'شاشة السجل',
      'test': 'تجربة',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
