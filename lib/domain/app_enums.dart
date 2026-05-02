import 'package:flutter/material.dart';

enum Section {
  dashboard,
  sales,
  products,
  customers,
  suppliers,
  documents,
  stock,
  purchases,
  reports,
  settings,
  tax,
  audit,
  team,
}

extension SectionDetails on Section {
  String get label {
    switch (this) {
      case Section.dashboard:
        return 'Tableau';
      case Section.sales:
        return 'Vendre';
      case Section.products:
        return 'Produits';
      case Section.customers:
        return 'Clients';
      case Section.suppliers:
        return 'Fournisseurs';
      case Section.documents:
        return 'Documents';
      case Section.stock:
        return 'Stock';
      case Section.purchases:
        return 'Achats';
      case Section.reports:
        return 'Rapports';
      case Section.settings:
        return 'Société';
      case Section.tax:
        return 'Fiscalité';
      case Section.audit:
        return 'Audit';
      case Section.team:
        return 'Équipe';
    }
  }

  IconData get icon {
    switch (this) {
      case Section.dashboard:
        return Icons.dashboard_outlined;
      case Section.sales:
        return Icons.point_of_sale_outlined;
      case Section.products:
        return Icons.inventory_2_outlined;
      case Section.customers:
        return Icons.groups_2_outlined;
      case Section.suppliers:
        return Icons.handshake_outlined;
      case Section.documents:
        return Icons.description_outlined;
      case Section.stock:
        return Icons.warehouse_outlined;
      case Section.purchases:
        return Icons.local_shipping_outlined;
      case Section.reports:
        return Icons.query_stats_outlined;
      case Section.settings:
        return Icons.storefront_outlined;
      case Section.tax:
        return Icons.receipt_long_outlined;
      case Section.audit:
        return Icons.verified_user_outlined;
      case Section.team:
        return Icons.group_outlined;
    }
  }
}

enum TvaRate {
  rate19(19),
  rate13(13),
  rate7(7),
  rate0(0);

  const TvaRate(this.value);
  final int value;

  double get multiplier => value / 100;
  String get label => '$value%';
}

enum PartnerType { client, supplier }

extension PartnerTypeDetails on PartnerType {
  String get label => this == PartnerType.client ? 'Client' : 'Fournisseur';
}

enum CustomerType { particulier, entreprise }

extension CustomerTypeDetails on CustomerType {
  String get label =>
      this == CustomerType.particulier ? 'Particulier' : 'Entreprise';
}

enum DocumentType { devis, bl, facture, creditNote, supplierOrder, stockEntry }

extension DocumentTypeDetails on DocumentType {
  String get label {
    switch (this) {
      case DocumentType.devis:
        return 'Devis';
      case DocumentType.bl:
        return 'Bon de livraison';
      case DocumentType.facture:
        return 'Facture';
      case DocumentType.creditNote:
        return 'Avoir';
      case DocumentType.supplierOrder:
        return 'Bon de commande fournisseur';
      case DocumentType.stockEntry:
        return "Bon d'entrée";
    }
  }

  String get shortLabel {
    switch (this) {
      case DocumentType.devis:
        return 'Devis';
      case DocumentType.bl:
        return 'BL';
      case DocumentType.facture:
        return 'Facture';
      case DocumentType.creditNote:
        return 'Avoir';
      case DocumentType.supplierOrder:
        return 'Commande';
      case DocumentType.stockEntry:
        return "Entrée";
    }
  }

  String get prefix {
    switch (this) {
      case DocumentType.devis:
        return 'DEV';
      case DocumentType.bl:
        return 'BL';
      case DocumentType.facture:
        return 'FAC';
      case DocumentType.creditNote:
        return 'AVR';
      case DocumentType.supplierOrder:
        return 'BCF';
      case DocumentType.stockEntry:
        return 'BE';
    }
  }
}

enum DocumentStatus { draft, validated, canceled }

extension DocumentStatusDetails on DocumentStatus {
  String get label {
    switch (this) {
      case DocumentStatus.draft:
        return 'Brouillon';
      case DocumentStatus.validated:
        return 'Validé';
      case DocumentStatus.canceled:
        return 'Annulé';
    }
  }
}

enum StockDirection { inbound, outbound }

enum PaymentMethod { cash, bankTransfer, check, card, other }

extension PaymentMethodDetails on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.bankTransfer:
        return 'Virement';
      case PaymentMethod.check:
        return 'Chèque';
      case PaymentMethod.card:
        return 'Carte';
      case PaymentMethod.other:
        return 'Autre';
    }
  }
}

enum PaymentStatus { unpaid, partial, paid }

extension PaymentStatusDetails on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Non payée';
      case PaymentStatus.partial:
        return 'Partiellement payée';
      case PaymentStatus.paid:
        return 'Payée';
    }
  }
}

T enumFromName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
