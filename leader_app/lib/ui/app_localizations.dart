import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('en'));
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
      'confirm_delete':
          'Are you sure you want to delete your account? This will clear your registration data.',
      'delete': 'Delete',
      'english': 'English',
      'arabic': 'Arabic',
      'reconnect': 'Reconnect to Laptop',
      'scan_qr': 'Scan QR Code',
      'select_member': 'Select Member',
      'history': 'History',
      'test': 'Test',
      'ok': 'OK',
      'error': 'Error',
      'details': 'Details',
      'loading': 'Loading...',
      'try_again': 'Try Again',
      'connected': 'Connected!',
      'connection_failed': 'Connection Failed',
      'reconnecting': 'Re-scanning network for Admin laptop...',
      'laptop_not_found': 'Laptop not found. Check Wi-Fi.',
      'please_enter_name': 'Please enter your name',
      'server_url_not_found': 'Server URL not found. Please scan again.',
      'detailed_error': 'Detailed Error',
      'leader_registration': 'Leader Registration',
      'connected_to_server': 'Connected to Server',
      'searching_for_server': 'Searching for Server...',
      'registration_instruction':
          'Enter your name to join the tournament as a Leader.',
      'full_name': 'Full Name',
      'register_and_continue': 'Register and Continue',
      'scan_admin_qr': 'Scan Admin QR Code',
      'trouble_scanning': 'Trouble scanning?',
      'enter_ip_manually': 'Enter Server IP Manually',
      'manual_server_connect': 'Manual Server Connect',
      'server_ip': 'Server IP',
      'connected_successfully': 'Connected to server successfully!',
      'connection_failed_details':
          'Could not reach server at {url}. Check Wi-Fi/Firewall.',
      'connection_failed_title': 'Connection Failed',
      'connection_failed_message':
          'The app tried to reach {url} but got no response.\n\nPossible causes:\n1. Phone and Laptop are on DIFFERENT Wi-Fi.\n2. Windows Firewall is blocking Port 8080.\n3. The IP address has changed on the laptop.',
      'registration_removed_title': 'Registration Removed',
      'registration_removed_message':
          'Your registration was removed by the Admin. Please register again to join the tournament.',
      'return_to_scan': 'Return to Scan',
      'access_denied_title': 'Access Denied',
      'access_denied_message':
          'Your registration was not approved by the Admin.',
      'waiting_for_approval': 'Waiting for Admin Approval...',
      'ask_admin_approval':
          'Please ask the Admin to approve your device on the laptop.',
      'check_status_now': 'Check Status Now',
      'score_member': 'Score {name}',
      'points_to_award': 'Points to Award',
      'reason_tag': 'Reason / Tag',
      'select_tag': 'Select a tag',
      'description_optional': 'Description (Optional)',
      'add_details_hint': 'Add any additional details...',
      'submit_score': 'Submit Score',
      'connection_lost_message':
          'Connection lost! Please ensure you are connected to the Admin Laptop.',
      'access_revoked_message':
          'Access Revoked: Your account is no longer approved.',
      'registration_not_found_message':
          'Registration Lost: Your account was removed by the Admin.',
      'score_submitted_success': '✅ Score submitted for approval!',
      'score_submit_failed': '❌ Failed to connect to Admin Laptop.',
      'loading_members': 'Loading members...',
      'oops_something_wrong': 'Oops! Something went wrong',
      'could_not_load_members':
          'We couldn\'t load the members right now. Please try again.',
      'no_members_found': 'No members found in this team.',
      'select_team': 'Select Team',
      'loading_tournament_data': 'Loading tournament data...',
      'connection_not_found': 'Connection Not Found',
      'connection_not_found_message':
          'It looks like we can\'t find the team data. Did you scan the correct QR code for this event?',
      'retry_connection': 'Retry Connection',
      'no_teams_registered': 'No Teams Registered',
      'teams_will_appear_here': 'Once teams are added, they will appear here.',
      'my_scoring_requests': 'My Scoring Requests',
      'no_scores_yet': 'You haven\'t submitted any scores yet.',
      'pending_requests': 'PENDING REQUESTS',
      'approved': 'APPROVED',
      'rejected': 'REJECTED',
      'unknown_member': 'Unknown Member',
      'reconnected_successfully': 'Reconnected successfully!',
      'could_not_find_server': 'Could not find server. Please check Wi-Fi.',
      'reset_points': 'Reset Points',
      'app_title': 'Tournament Leader',
      'dashboard': 'Dashboard',
      'welcome_back': 'Welcome back, {name}!',
      'success': 'Success',
      'score_another': 'Score Another Member',
      'back_to_home': 'Back to Home',
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
      'confirm_delete':
          'هل أنت متأكد أنك تريد حذف حسابك؟ سيؤدي ذلك إلى مسح بيانات التسجيل الخاصة بك.',
      'delete': 'حذف',
      'english': 'English',
      'arabic': 'العربية',
      'reconnect': 'إعادة الاتصال بالكمبيوتر',
      'scan_qr': 'مسح رمز QR',
      'select_member': 'اختيار الأعضاء',
      'history': 'السجل',
      'test': 'تجربة',
      'ok': 'موافق',
      'error': 'خطأ',
      'details': 'التفاصيل',
      'loading': 'جاري التحميل...',
      'try_again': 'إعادة المحاولة',
      'connected': 'تم الاتصال!',
      'connection_failed': 'فشل الاتصال',
      'reconnecting': 'جاري البحث عن الكمبيوتر المسؤول في الشبكة...',
      'laptop_not_found':
          'لم يتم العثور على الكمبيوتر. تأكد من اتصال الـ Wi-Fi.',
      'please_enter_name': 'يرجى إدخال اسمك',
      'server_url_not_found': 'عنوان الخادم غير موجود. يرجى المسح مرة أخرى.',
      'detailed_error': 'تفاصيل الخطأ',
      'leader_registration': 'تسجيل القائد',
      'connected_to_server': 'متصل بالخادم',
      'searching_for_server': 'جاري البحث عن الخادم...',
      'registration_instruction': 'أدخل اسمك للانضمام إلى البطولة كقائد.',
      'full_name': 'الاسم الكامل',
      'register_and_continue': 'تسجيل ومتابعة',
      'scan_admin_qr': 'مسح رمز QR للمسؤول',
      'trouble_scanning': 'هل تواجه مشكلة في المسح؟',
      'enter_ip_manually': 'إدخال عنوان IP يدوياً',
      'manual_server_connect': 'اتصال يدوي بالخادم',
      'server_ip': 'عنوان IP الخاص بالخادم',
      'connected_successfully': 'تم الاتصال بالخادم بنجاح!',
      'connection_failed_details':
          'تعذر الوصول إلى الخادم في {url}. تحقق من الـ Wi-Fi/جدار الحماية.',
      'connection_failed_title': 'فشل الاتصال',
      'connection_failed_message':
          'حاول التطبيق الوصول إلى {url} ولكن لم يتلق أي رد.\n\nالأسباب المحتملة:\n1. الهاتف والكمبيوتر متصلان بشبكات Wi-Fi مختلفة.\n2. جدار حماية ويندوز يحظر المنفذ 8080.\n3. تغير عنوان IP الخاص بالكمبيوتر.',
      'registration_removed_title': 'تمت إزالة التسجيل',
      'registration_removed_message':
          'قام المسؤول بإزالة تسجيلك. يرجى التسجيل مرة أخرى للانضمام إلى البطولة.',
      'return_to_scan': 'العودة للمسح',
      'access_denied_title': 'تم رفض الوصول',
      'access_denied_message': 'لم يتم قبول تسجيلك من قبل المسؤول.',
      'waiting_for_approval': 'في انتظار موافقة المسؤول...',
      'ask_admin_approval':
          'يرجى الطلب من المسؤول الموافقة على جهازك من الكمبيوتر.',
      'check_status_now': 'تحقق من الحالة الآن',
      'score_member': 'تسجيل نقاط لـ {name}',
      'points_to_award': 'النقاط المراد منحها',
      'reason_tag': 'السبب / الوسم',
      'select_tag': 'اختر وسماً',
      'description_optional': 'الوصف (اختياري)',
      'add_details_hint': 'أضف أي تفاصيل إضافية...',
      'submit_score': 'إرسال النقاط',
      'connection_lost_message':
          'فُقد الاتصال! يرجى التأكد من اتصالك بالكمبيوتر المسؤول.',
      'access_revoked_message': 'تم سحب الوصول: حسابك لم يعد معتمداً.',
      'registration_not_found_message':
          'فُقد التسجيل: قام المسؤول بإزالة حسابك.',
      'score_submitted_success': '✅ تم إرسال النقاط للموافقة!',
      'score_submit_failed': '❌ فشل الاتصال بالكمبيوتر المسؤول.',
      'loading_members': 'جاري تحميل الأعضاء...',
      'oops_something_wrong': 'عذراً! حدث خطأ ما',
      'could_not_load_members':
          'لم نتمكن من تحميل الأعضاء حالياً. يرجى المحاولة مرة أخرى.',
      'no_members_found': 'لا يوجد أعضاء في هذا الفريق.',
      'select_team': 'اختر فريقاً',
      'loading_tournament_data': 'جاري تحميل بيانات البطولة...',
      'connection_not_found': 'الاتصال غير موجود',
      'connection_not_found_message':
          'يبدو أننا لا نستطيع العثور على بيانات الفريق. هل قمت بمسح رمز QR الصحيح لهذا الحدث؟',
      'retry_connection': 'إعادة محاولة الاتصال',
      'no_teams_registered': 'لا توجد فرق مسجلة',
      'teams_will_appear_here': 'بمجرد إضافة الفرق، ستظهر هنا.',
      'my_scoring_requests': 'طلبات النقاط الخاصة بي',
      'no_scores_yet': 'لم تقم بإرسال أي نقاط بعد.',
      'pending_requests': 'طلبات معلقة',
      'approved': 'تمت الموافقة',
      'rejected': 'مرفوض',
      'unknown_member': 'عضو غير معروف',
      'reconnected_successfully': 'تمت إعادة الاتصال بنجاح!',
      'could_not_find_server':
          'لم يتم العثور على الخادم. يرجى التحقق من الـ Wi-Fi.',
      'reset_points': 'إعادة ضبط النقاط',
      'app_title': 'قائد البطولة',
      'dashboard': 'لوحة التحكم',
      'welcome_back': 'أهلاً بك مجدداً، {name}!',
      'success': 'نجاح',
      'score_another': 'تسجيل نقاط لعضو آخر',
      'back_to_home': 'العودة للرئيسية',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String translateWithParam(String key, String param, String value) {
    String text = translate(key);
    return text.replaceAll('{$param}', value);
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
