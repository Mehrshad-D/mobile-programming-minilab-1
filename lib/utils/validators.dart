/// Pure, reusable form validators. Returning `null` means the value is valid.
class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$',
  );

  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName را وارد کنید';
    }
    return null;
  }

  static String? name(String? value) {
    final required = requiredField(value, 'نام');
    if (required != null) return required;
    if (value!.trim().length < 3) {
      return 'نام باید حداقل ۳ نویسه باشد';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredField(value, 'ایمیل');
    if (required != null) return required;
    if (!_emailRegExp.hasMatch(value!.trim())) {
      return 'ایمیل معتبر نیست';
    }
    return null;
  }

  static String? password(String? value) {
    final required = requiredField(value, 'رمز عبور');
    if (required != null) return required;
    if (value!.length < 6) {
      return 'رمز عبور باید حداقل ۶ نویسه باشد';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final required = requiredField(value, 'تکرار رمز عبور');
    if (required != null) return required;
    if (value != original) {
      return 'رمز عبور و تکرار آن یکسان نیستند';
    }
    return null;
  }
}
