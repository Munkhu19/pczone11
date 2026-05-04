import 'package:flutter/material.dart';

class LocaleController extends ValueNotifier<Locale> {
  LocaleController() : super(const Locale('mn'));

  void toggleLanguage() {
    value = value.languageCode == 'mn'
        ? const Locale('en')
        : const Locale('mn');
  }
}

final LocaleController localeController = LocaleController();
