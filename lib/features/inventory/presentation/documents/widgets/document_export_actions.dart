part of '../../inventory_shell_page.dart';

extension _InventoryDocumentExportActions on _InventoryHomePageState {
  Future<void> _showPaymentDialog(BusinessDocument document) async {
    if (document.type != DocumentType.facture) return;
    final blockReason = PaymentService.paymentBlockReason(_documents, document);
    final creditedAmount = _creditedAmountForInvoice(document);
    final effectiveNet = _invoiceNetAfterCredits(document);
    final remainingDue = _invoiceRemainingDue(document);
    if (blockReason != null) {
      _showMessage(
        blockReason,
        isError: document.status != DocumentStatus.validated,
      );
      return;
    }
    final amount = TextEditingController(text: remainingDue.toStringAsFixed(3));
    final reference = TextEditingController();
    final note = TextEditingController();
    var method = PaymentMethod.cash;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text('Paiement ${document.number}'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    TotalItem(
                      label: 'Net facture',
                      value: formatMoney(_documentNetToPay(document)),
                    ),
                    if (creditedAmount > .001)
                      TotalItem(
                        label: 'Avoir validés',
                        value: '-${formatMoney(creditedAmount)}',
                      ),
                    if (creditedAmount > .001)
                      TotalItem(
                        label: 'Net après avoir',
                        value: formatMoney(effectiveNet),
                      ),
                    TotalItem(
                      label: 'Déjà payé',
                      value: formatMoney(_paidAmount(document)),
                    ),
                    TotalItem(
                      label: 'Reste',
                      value: formatMoney(remainingDue),
                      strong: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _dialogField(
                      width: 160,
                      controller: amount,
                      label: 'Montant',
                      number: true,
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<PaymentMethod>(
                        initialValue: method,
                        decoration: const InputDecoration(labelText: 'Mode'),
                        items: [
                          for (final item in PaymentMethod.values)
                            DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => method = value);
                          }
                        },
                      ),
                    ),
                    _dialogField(
                      width: 260,
                      controller: reference,
                      label: 'Référence',
                    ),
                    SizedBox(
                      width: 460,
                      child: TextField(
                        controller: note,
                        decoration: const InputDecoration(labelText: 'Note'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (document.payments.isNotEmpty)
                  Text(
                    'Historique: ${document.payments.map((payment) => '${formatMoney(payment.amount)} ${payment.method.label}').join(' · ')}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = _parseAmount(amount.text, fallback: -1);
                final amountError = PaymentService.paymentAmountError(
                  _documents,
                  document,
                  parsed,
                  formatMoney: formatMoney,
                );
                if (amountError != null) {
                  _showMessage(amountError, isError: true);
                  return;
                }
                final payment = PaymentEntry(
                  id: _newId('pay'),
                  date: DateTime.now(),
                  amount: parsed,
                  method: method,
                  reference: reference.text.trim(),
                  note: note.text.trim(),
                );
                _updateState(() {
                  _documentsCubit.addPayment(
                    document: document,
                    documents: _documents,
                    payment: payment,
                    formatMoney: formatMoney,
                    auditAction: 'Paiement facture',
                    auditDetail:
                        '${formatMoney(payment.amount)} - ${payment.method.label}',
                  );
                  _applyRepositoryState(selectedDocumentId: document.id);
                });
                Navigator.of(dialogContext).pop();
                final remainingAfterPayment = remainingDue - parsed;
                _showMessage(
                  'Paiement enregistré: ${formatMoney(parsed)}. Reste à payer: ${formatMoney(remainingAfterPayment <= 0 ? 0 : remainingAfterPayment)}.',
                );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportDocumentPdf(BusinessDocument document) async {
    if (_pdfExportInProgress) {
      _showMessage('Téléchargement déjà en cours.');
      return;
    }
    _updateState(() => _pdfExportInProgress = true);
    try {
      final bytes = await _buildDocumentPdf(document);
      final fileName =
          '${document.number.toLowerCase()}-${document.type.shortLabel.toLowerCase()}.pdf'
              .replaceAll(RegExp(r'[^a-z0-9_.-]'), '-');
      final message = await saveBinaryFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/pdf',
      );
      _showMessage(message);
    } finally {
      if (mounted) {
        _updateState(() => _pdfExportInProgress = false);
      }
    }
  }

  Future<Uint8List> _buildDocumentPdf(BusinessDocument document) async {
    final pdf = pw.Document();
    final warehouse = _warehouseById(document.warehouseId);
    final company = document.companySnapshot ?? _company;
    final logoBytes = await _loadLogoBytes(company.logoSource);
    final pdfLogo = logoBytes == null ? null : pw.MemoryImage(logoBytes);
    final statusLabel = document.status == DocumentStatus.draft
        ? 'BROUILLON'
        : document.status == DocumentStatus.canceled
        ? 'ANNULE'
        : 'VALIDE';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (pdfLogo != null) ...[
                      pw.Container(
                        width: 58,
                        height: 58,
                        padding: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Image(pdfLogo, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(width: 12),
                    ],
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            company.name,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(_companyDisplayAddress(company)),
                          pw.Text('MF: ${company.taxId}'),
                          pw.Text('${company.phone} - ${company.email}'),
                          if (company.legalInfo.isNotEmpty)
                            pw.Text(company.legalInfo),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    document.type.label.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(document.number),
                  pw.Text(formatDate(document.date)),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey600),
                    ),
                    child: pw.Text(statusLabel),
                  ),
                ],
              ),
            ],
          ),
          pw.Divider(height: 28),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (document.type == DocumentType.bonSortie) ...[
                      pw.Text(
                        'Destination',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        _warehouseById(
                          document.metadata['targetWarehouseId'] ?? '',
                        ).name,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (document.metadata['destination']
                              ?.toString()
                              .isNotEmpty ??
                          false)
                        pw.Text('Zone: ${document.metadata['destination']}'),
                      pw.Text(
                        'Transfert interne vers unité mobile',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ] else ...[
                      pw.Text(
                        'Tiers',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(document.partnerName),
                      pw.Text('MF: ${document.partnerTaxId}'),
                      pw.Text(document.partnerAddress),
                    ],
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Logistique',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Dépôt: ${warehouse.name}'),
                    if (document.metadata['driverName']
                            ?.toString()
                            .isNotEmpty ??
                        false)
                      pw.Text('Chauffeur: ${document.metadata['driverName']}'),
                    if (document.metadata['vehiclePlate']
                            ?.toString()
                            .isNotEmpty ??
                        false)
                      pw.Text('Véhicule: ${document.metadata['vehiclePlate']}'),
                    if (document.sourceNumber != null)
                      pw.Text('Origine: ${document.sourceNumber}'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Désignation',
              'Qté',
              'PU HT',
              'Remise',
              'TVA',
              'TTC',
            ],
            data: [
              for (final line in document.lines)
                [
                  '${line.sku}\n${line.label}',
                  '${line.quantity}',
                  formatMoney(line.unitHt),
                  '${line.discountRate.toStringAsFixed(1)}%',
                  line.tvaRate.label,
                  formatMoney(_lineTotalTtc(line)),
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 230,
              child: pw.Column(
                children: [
                  _pdfTotalRow(
                    'Total HT',
                    formatMoney(_documentTotalHt(document)),
                  ),
                  _pdfTotalRow('TVA', formatMoney(_documentTotalTva(document))),
                  if (document.applyTimbreFiscal)
                    _pdfTotalRow(
                      'Timbre fiscal',
                      formatMoney(document.timbreFiscalAmount),
                    ),
                  pw.Divider(),
                  _pdfTotalRow(
                    'Net à payer',
                    formatMoney(_documentNetToPay(document)),
                    strong: true,
                  ),
                ],
              ),
            ),
          ),
          if (document.lines.any((line) => line.serialNumbers.isNotEmpty)) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              'N° série: ${document.lines.expand((line) => line.serialNumbers).join(', ')}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.Text(
            company.invoiceFooter.isEmpty
                ? 'TVA calculée sur les prix hors taxe.'
                : company.invoiceFooter,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  Future<void> _shareWhatsApp(BusinessDocument document) async {
    final message = Uri.encodeComponent(
      'Bonjour, ${document.type.label} ${document.number} - Net à payer ${formatMoney(_documentNetToPay(document))}.',
    );
    final uri = Uri.parse('https://wa.me/?text=$message');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) {
      _showMessage('WhatsApp ouvert pour ${document.number}.');
    } else {
      _showMessage(
        'Ouverture WhatsApp indisponible sur cette plateforme.',
        isError: true,
      );
    }
  }
}
