import '../../../app/app_assets.dart';
import '../../../domain/app_enums.dart';
import '../../../domain/app_models.dart';

/// Answers collected from onboarding page 2.
///
/// This is intentionally small for now: it gives the app enough information to
/// create a clean local base with the company name, first depot, price mode,
/// and timbre fiscal preference.
class StoreSetupData {
  const StoreSetupData({
    required this.storeName,
    required this.taxId,
    required this.address,
    required this.city,
    required this.phone,
    required this.email,
    required this.commerceType,
    required this.depotName,
    required this.depotCode,
    required this.depotCity,
    required this.depotAddress,
    required this.priceMode,
    required this.timbreFiscal,
  });

  factory StoreSetupData.empty() => const StoreSetupData(
    storeName: '',
    taxId: '',
    address: '',
    city: '',
    phone: '',
    email: '',
    commerceType: 'Électronique',
    depotName: '',
    depotCode: '',
    depotCity: '',
    depotAddress: '',
    priceMode: 'Prix TTC',
    timbreFiscal: true,
  );

  final String storeName;
  final String taxId;
  final String address;
  final String city;
  final String phone;
  final String email;
  final String commerceType;
  final String depotName;
  final String depotCode;
  final String depotCity;
  final String depotAddress;
  final String priceMode;
  final bool timbreFiscal;

  String get normalizedStoreName {
    final value = storeName.trim();
    return value.isEmpty ? 'Nouveau magasin' : value;
  }

  String get normalizedDepotName {
    final value = depotName.trim();
    return value.isEmpty ? 'Dépôt principal' : value;
  }

  String get normalizedDepotCode {
    final value = depotCode.trim().toUpperCase();
    return value.isEmpty ? 'MAIN' : value;
  }

  String get normalizedDepotCity => depotCity.trim();

  StoreSetupData copyWith({
    String? storeName,
    String? taxId,
    String? address,
    String? city,
    String? phone,
    String? email,
    String? commerceType,
    String? depotName,
    String? depotCode,
    String? depotCity,
    String? depotAddress,
    String? priceMode,
    bool? timbreFiscal,
  }) {
    return StoreSetupData(
      storeName: storeName ?? this.storeName,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      commerceType: commerceType ?? this.commerceType,
      depotName: depotName ?? this.depotName,
      depotCode: depotCode ?? this.depotCode,
      depotCity: depotCity ?? this.depotCity,
      depotAddress: depotAddress ?? this.depotAddress,
      priceMode: priceMode ?? this.priceMode,
      timbreFiscal: timbreFiscal ?? this.timbreFiscal,
    );
  }

  String get defaultCategoryName {
    return switch (commerceType) {
      'Électronique' => 'Électronique',
      'Grossiste' => 'Grossiste',
      'Autre' => 'Général',
      _ => 'Général',
    };
  }

  Map<String, dynamic> toJson() => {
    'storeName': storeName,
    'taxId': taxId,
    'address': address,
    'city': city,
    'phone': phone,
    'email': email,
    'commerceType': commerceType,
    'depotName': depotName,
    'depotCode': depotCode,
    'depotCity': depotCity,
    'depotAddress': depotAddress,
    'priceMode': priceMode,
    'timbreFiscal': timbreFiscal,
  };

  factory StoreSetupData.fromJson(Map<String, dynamic> json) {
    return StoreSetupData(
      storeName: json['storeName'] as String? ?? '',
      taxId: json['taxId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      commerceType: json['commerceType'] as String? ?? 'Électronique',
      depotName: json['depotName'] as String? ?? '',
      depotCode: json['depotCode'] as String? ?? '',
      depotCity: json['depotCity'] as String? ?? '',
      depotAddress: json['depotAddress'] as String? ?? '',
      priceMode: json['priceMode'] as String? ?? 'Prix TTC',
      timbreFiscal: json['timbreFiscal'] as bool? ?? true,
    );
  }

  AppSnapshot toCleanSnapshot() {
    return AppSnapshot(
      company: CompanyProfile(
        name: normalizedStoreName,
        taxId: taxId.trim(),
        address: address.trim(),
        city: city.trim(),
        phone: phone.trim(),
        email: email.trim(),
        logoSource: AppAssets.systemLogoSource,
        invoiceFooter: 'Merci pour votre confiance.',
        legalInfo: '',
        timbreFiscalEnabled: timbreFiscal,
        timbreFiscalAmount: 1,
      ),
      warehouses: [
        Warehouse(
          id: 'main',
          name: normalizedDepotName,
          city: normalizedDepotCity,
          code: normalizedDepotCode,
          address: depotAddress.trim(),
        ),
      ],
      categories: [Category(id: 'cat-default', name: defaultCategoryName)],
      products: const [],
      partners: const [],
      documents: const [],
      movements: const [],
      sequences: {for (final type in DocumentType.values) type: 1},
      auditEvents: const [],
    );
  }
}
