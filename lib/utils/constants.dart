import 'package:flutter/material.dart';

/// Server routes from the spec, used as the `Location` of post-login redirects
/// (section 5.3) and to model the real endpoint paths.
class ApiRoutes {
  ApiRoutes._();

  static const String loginPage = '/login/user';
  static const String home = '/';
}

/// Color palette inspired by Jobinja's brand (teal/green).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0A9D8E);
  static const Color primaryDark = Color(0xFF077C70);
  static const Color accent = Color(0xFFF2994A);
  static const Color background = Color(0xFFF4F6F8);
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
}

/// Consistent spacing scale used across the app.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double radius = 12;
  static const double radiusSm = 8.0;
}

/// All user-facing Persian strings live here so screens stay clean.
class AppStrings {
  AppStrings._();

  static const String appName = 'جابینجا';
  static const String appTagline = 'کاریابی هوشمند';

  // Auth
  static const String login = 'ورود';
  static const String signup = 'ثبت‌نام';
  static const String logout = 'خروج از حساب';
  static const String name = 'نام و نام خانوادگی';
  static const String email = 'ایمیل';
  static const String password = 'رمز عبور';
  static const String confirmPassword = 'تکرار رمز عبور';
  static const String noAccount = 'حساب کاربری ندارید؟';
  static const String haveAccount = 'قبلاً ثبت‌نام کرده‌اید؟';
  static const String welcomeBack = 'خوش آمدید';
  static const String rememberMe = 'مرا به خاطر بسپار';
  static const String createAccount = 'ساخت حساب کاربری';

  // Home / Jobs
  static const String searchHint = 'عنوان شغلی، مهارت یا شرکت';
  static const String allLocations = 'همه استان‌ها';
  static const String search = 'جستجو';
  static const String jobsTitle = 'فرصت‌های شغلی';
  static const String noJobs = 'فرصت شغلی‌ای یافت نشد';
  static const String remote = 'دورکاری';

  // Job detail
  static const String jobDescription = 'شرح موقعیت شغلی';
  static const String jobRequirements = 'مهارت‌ها و نیازمندی‌ها';
  static const String apply = 'ارسال رزومه';
  static const String applied = 'رزومه ارسال شد';
  static const String aboutCompany = 'درباره شرکت';
  static const String viewCompany = 'مشاهده صفحه شرکت';
  static const String contractType = 'نوع همکاری';
  static const String experience = 'سابقه کار';
  static const String salary = 'حقوق';

  // Profile
  static const String profile = 'پروفایل';
  static const String appliedJobs = 'درخواست‌های ارسال‌شده';
  static const String noAppliedJobs = 'هنوز برای شغلی رزومه ارسال نکرده‌اید';

  // Company
  static const String companyJobs = 'فرصت‌های شغلی این شرکت';

  // Filters
  static const String filters = 'فیلترها';
  static const String category = 'دسته‌بندی شغلی';
  static const String jobType = 'نوع همکاری';
  static const String benefits = 'مزایا و امکانات';
  static const String minSalary = 'حداقل حقوق';
  static const String internship = 'فقط موقعیت‌های کارآموزی';
  static const String applyFilters = 'اعمال فیلتر';
  static const String clearFilters = 'حذف فیلترها';
  static const String anyOption = 'همه';

  // Generic states
  static const String retry = 'تلاش دوباره';
  static const String loading = 'در حال بارگذاری...';
  static const String genericError = 'خطای غیرمنتظره‌ای رخ داد. دوباره تلاش کنید.';
  static const String networkError = 'ارتباط با سرور برقرار نشد. اتصال اینترنت را بررسی کنید.';
}
