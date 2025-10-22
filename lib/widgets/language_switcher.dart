import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.language),
      tooltip: 'switch_lang'.tr(),
      onPressed: () {
        final newLocale =
        context.locale.languageCode == 'ru' ? const Locale('en') : const Locale('ru');
        context.setLocale(newLocale);
      },
    );
  }
}
