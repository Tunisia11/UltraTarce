import '../../core/iterable_extensions.dart';
import '../app_enums.dart';
import '../app_models.dart';

class DocumentLifecycleService {
  const DocumentLifecycleService._();

  static bool salesDocumentNeedsStock(DocumentType type) =>
      type == DocumentType.bl || type == DocumentType.facture;

  static String? validationBlockReason(BusinessDocument document) {
    if (document.status == DocumentStatus.canceled) {
      return 'Validation bloquée. ${document.number} est annulé; créez un nouveau document si la vente doit repartir.';
    }
    if (document.type == DocumentType.bonSortie) {
      final target = document.metadata['targetWarehouseId'] as String?;
      if (target == null || target.isEmpty) {
        return 'Validation bloquée. Aucun dépôt de destination sélectionné pour le Bon de Sortie.';
      }
      if (target == document.warehouseId) {
        return 'Validation bloquée. Le dépôt de départ et de destination doivent être différents.';
      }
    }
    return null;
  }

  static bool validationRequiresOutboundStock(BusinessDocument document) {
    return document.type == DocumentType.bl ||
        (document.type == DocumentType.facture &&
            document.sourceNumber == null);
  }

  static bool validationRequiresTransferStock(BusinessDocument document) {
    return document.type == DocumentType.bonSortie;
  }

  static bool validationRequiresInboundStock(BusinessDocument document) {
    return document.type == DocumentType.stockEntry ||
        document.type == DocumentType.creditNote;
  }

  static BusinessDocument markValidated(
    BusinessDocument document, {
    required List<DocumentLine> lines,
    required bool stockApplied,
  }) {
    return document.copyWith(
      status: DocumentStatus.validated,
      lines: lines,
      stockApplied: stockApplied,
    );
  }

  static BusinessDocument markCanceled(BusinessDocument document) {
    return document.copyWith(
      status: DocumentStatus.canceled,
      stockApplied: false,
    );
  }

  static BusinessDocument? activeChildOf(
    Iterable<BusinessDocument> documents,
    BusinessDocument source,
    DocumentType targetType,
  ) {
    return documents
        .where(
          (document) =>
              document.type == targetType &&
              document.sourceNumber == source.number &&
              document.status != DocumentStatus.canceled,
        )
        .firstOrNull;
  }

  static String stockEffectHintFor(DocumentType type) {
    return switch (type) {
      DocumentType.devis =>
        'Aucun mouvement de stock. Le devis reste commercial.',
      DocumentType.bl =>
        'Stock réservé visuellement ici, puis sorti à la validation du BL.',
      DocumentType.facture =>
        'Facture directe: le stock sortira à la validation de la facture.',
      DocumentType.bonSortie =>
        'Stock transféré vers le dépôt mobile à la validation.',
      _ => 'Le stock suit la règle du document au moment de la validation.',
    };
  }

  static String validationSuccessMessage(
    BusinessDocument document, {
    required String warehouseName,
  }) {
    return switch (document.type) {
      DocumentType.bl =>
        '${document.number} validé. Stock sorti de $warehouseName et document verrouillé.',
      DocumentType.facture when document.sourceNumber == null =>
        '${document.number} validée. Facture directe: stock sorti de $warehouseName.',
      DocumentType.facture =>
        '${document.number} validée. Aucun stock supplémentaire: elle est liée au BL ${document.sourceNumber}.',
      DocumentType.stockEntry =>
        '${document.number} validé. Stock ajouté à $warehouseName.',
      DocumentType.creditNote =>
        '${document.number} validé. Stock réintégré à $warehouseName.',
      DocumentType.devis =>
        '${document.number} validé. Aucun stock ne bouge sur un devis.',
      DocumentType.supplierOrder =>
        '${document.number} validé. Commande fournisseur sans mouvement de stock.',
      DocumentType.bonSortie =>
        document.status == DocumentStatus.closed
            ? '${document.number} clôturé: stock mobile apuré.'
            : document.status == DocumentStatus.partialReturn
            ? '${document.number}: retour partiel enregistré.'
            : 'Sortie camion validée. Le stock est transféré vers le camion.',
    };
  }

  static String? cancelBlockReason(
    Iterable<BusinessDocument> documents,
    BusinessDocument document,
  ) {
    if (document.status == DocumentStatus.canceled) {
      return 'Action bloquée. ${document.number} est déjà annulé.';
    }
    if (document.type == DocumentType.devis) {
      final child = activeChildOf(documents, document, DocumentType.bl);
      if (child != null) {
        return 'Annulation bloquée. ${document.number} a déjà créé ${child.number}; annulez d’abord le BL si vous devez revenir en arrière.';
      }
    }
    if (document.type == DocumentType.bl) {
      final child = activeChildOf(documents, document, DocumentType.facture);
      if (child != null) {
        return 'Annulation bloquée. ${document.number} est déjà facturé avec ${child.number}; traitez d’abord la facture ou créez un avoir.';
      }
    }
    if (document.type == DocumentType.facture && document.payments.isNotEmpty) {
      return 'Annulation bloquée. Cette facture contient déjà un paiement; créez un avoir si la vente doit être corrigée.';
    }
    return null;
  }

  static String? conversionBlockReason(
    Iterable<BusinessDocument> documents,
    BusinessDocument source,
    DocumentType targetType,
  ) {
    final existing = activeChildOf(documents, source, targetType);
    if (existing == null) return null;
    return switch (targetType) {
      DocumentType.bl =>
        'Conversion bloquée. ${source.number} a déjà créé ${existing.number}; ouvrez ce BL ou annulez-le avant de recommencer.',
      DocumentType.facture =>
        'Facturation bloquée. ${source.number} a déjà créé ${existing.number}; ouvrez la facture existante pour éviter un doublon.',
      DocumentType.stockEntry =>
        'Réception bloquée. ${source.number} a déjà créé ${existing.number}; ouvrez le bon d’entrée existant pour éviter une double entrée stock.',
      _ =>
        'Conversion bloquée. ${source.number} a déjà créé ${existing.number}.',
    };
  }

  static BusinessDocument buildBlFromQuote({
    required BusinessDocument source,
    required String id,
    required String number,
    required DateTime date,
  }) {
    return BusinessDocument(
      id: id,
      type: DocumentType.bl,
      number: number,
      status: DocumentStatus.draft,
      partnerId: source.partnerId,
      partnerName: source.partnerName,
      partnerTaxId: source.partnerTaxId,
      partnerAddress: source.partnerAddress,
      date: date,
      lines: source.lines,
      warehouseId: source.warehouseId,
      companySnapshot: source.companySnapshot,
      sourceNumber: source.number,
      note: 'Converti depuis ${source.number}.',
    );
  }

  static BusinessDocument buildSalesDocument({
    required String id,
    required DocumentType type,
    required String number,
    required Partner client,
    required DateTime date,
    required List<DocumentLine> lines,
    required String warehouseId,
    required CompanyProfile company,
    required bool applyTimbreFiscal,
    required double timbreFiscalAmount,
    Map<String, dynamic> metadata = const {},
    String note = 'Vente préparée depuis Faire une vente.',
  }) {
    return BusinessDocument(
      id: id,
      type: type,
      number: number,
      status: DocumentStatus.draft,
      partnerId: client.id,
      partnerName: client.name,
      partnerTaxId: client.taxId,
      partnerAddress: client.address,
      date: date,
      lines: lines,
      warehouseId: warehouseId,
      companySnapshot: company,
      note: note,
      applyTimbreFiscal: applyTimbreFiscal,
      timbreFiscalAmount: timbreFiscalAmount,
      metadata: metadata,
    );
  }

  static BusinessDocument buildSupplierDocument({
    required String id,
    required DocumentType type,
    required String number,
    required Partner supplier,
    required DateTime date,
    required String warehouseId,
    required CompanyProfile company,
    required DocumentLine line,
    required String note,
  }) {
    return BusinessDocument(
      id: id,
      type: type,
      number: number,
      status: DocumentStatus.draft,
      partnerId: supplier.id,
      partnerName: supplier.name,
      partnerTaxId: supplier.taxId,
      partnerAddress: supplier.address,
      date: date,
      warehouseId: warehouseId,
      companySnapshot: company,
      lines: [line],
      note: note,
    );
  }

  static BusinessDocument buildInvoiceFromBl({
    required BusinessDocument source,
    required String id,
    required String number,
    required DateTime date,
    required bool applyTimbreFiscal,
    required double timbreFiscalAmount,
  }) {
    return BusinessDocument(
      id: id,
      type: DocumentType.facture,
      number: number,
      status: DocumentStatus.validated,
      partnerId: source.partnerId,
      partnerName: source.partnerName,
      partnerTaxId: source.partnerTaxId,
      partnerAddress: source.partnerAddress,
      date: date,
      lines: source.lines,
      warehouseId: source.warehouseId,
      companySnapshot: source.companySnapshot,
      sourceNumber: source.number,
      note: 'Facture liée au BL ${source.number}.',
      applyTimbreFiscal: applyTimbreFiscal,
      timbreFiscalAmount: timbreFiscalAmount,
    );
  }

  static BusinessDocument buildStockEntryFromSupplierOrder({
    required BusinessDocument source,
    required String id,
    required String number,
    required DateTime date,
  }) {
    return BusinessDocument(
      id: id,
      type: DocumentType.stockEntry,
      number: number,
      status: DocumentStatus.draft,
      partnerId: source.partnerId,
      partnerName: source.partnerName,
      partnerTaxId: source.partnerTaxId,
      partnerAddress: source.partnerAddress,
      date: date,
      lines: source.lines,
      warehouseId: source.warehouseId,
      companySnapshot: source.companySnapshot,
      sourceNumber: source.number,
      note: 'Réception liée à ${source.number}.',
    );
  }
}
