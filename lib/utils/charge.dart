import 'dart:convert';

import 'package:moneta/common/strings.dart';

class Charge {
  /// The email of the customer
  String email;
  String transRef;

  /// Amount to pay in base currency. Must be a valid positive number
  int amount = 0;
  Map<String, dynamic> _metadata;
  List<Map<String, dynamic>> _customFields;
  bool _hasMeta = false;
  bool _hasParams = false;
  Map<String, String> _additionalParameters;

  /// The locale used for formatting amount in the UI prompt. Defaults to [Strings.nigerianLocale]
  String locale;
  String accessCode;
  String plan;
  String reference;

  /// ISO 4217 payment currency code (e.g USD). Defaults to [Strings.ngn].
  ///
  /// If you're setting this value, also set [locale] for better formatting.
  String currency;
  int transactionCharge;

  /// Who bears charges? [Bearer.Account] or [Bearer.SubAccount]
  Bearer bearer;

  String subAccount;

  Charge() {
    this._metadata = {};
    this.amount = -1;
    this.transRef = "";
    this._additionalParameters = {};
    this._customFields = [];
    this._metadata['custom_fields'] = this._customFields;
    this.locale = Strings.nigerianLocale;
    this.currency = Strings.ngn;
  }

  addParameter(String key, String value) {
    this._additionalParameters[key] = value;
    this._hasParams = true;
  }

  Map<String, String> get additionalParameters => _additionalParameters;

  putMetaData(String name, dynamic value) {
    this._metadata[name] = value;
    this._hasMeta = true;
  }

  putCustomField(String displayName, String value) {
    var customMap = {
      'value': value,
      'display_name': displayName,
      'variable_name':
          displayName.toLowerCase().replaceAll(new RegExp(r'[^a-z0-9 ]'), "_")
    };
    this._customFields.add(customMap);
    this._hasMeta = true;
  }

  String get metadata {
    if (!_hasMeta) {
      return null;
    }

    return jsonEncode(_metadata);
  }

  set metadata(dynamic metas) {
    if (metas.runtimeType.toString().toLowerCase().contains("map")) {
      _metadata = metas;
    }
  }

  String get parameters {
    if (!_hasParams) {
      return null;
    }

    return jsonEncode(_additionalParameters);
  }
}

enum Bearer {
  Account,
  SubAccount,
}
