# Trace Ultra

Local-first Flutter product for Tunisian SMEs that sell electronics,
appliances, spare parts, phones, accessories, and technical products.

## What is included

- French interface built around daily Tunisian sales habits.
- Products with SKU, barcode, category, brand, description, purchase HT, sale
  HT/TTC, TVA 19% / 13% / 7% / 0%, minimum stock, warehouse stock, active state,
  and serial number tracking.
- CRUD for products, clients, suppliers, warehouses, and categories.
- Clients and suppliers with Tunisian business fields, notes, city, active state,
  and matricule fiscal where needed.
- Sales flow: Devis -> Bon de livraison -> Facture with duplicate conversion
  prevention.
- Direct delivered facture flow with outbound stock movement on validation.
- Purchase flow: Bon de commande fournisseur -> Bon d'entrée -> stock increase.
- Basic customer return / avoir flow from invoices.
- Document numbering such as `BL-2026-0001` and `FAC-2026-0001`.
- A4 document preview with company info, client matricule fiscal, TVA breakdown,
  total HT, TVA, timbre fiscal, and net à payer.
- Real PDF generation for documents and CSV export for master data, documents,
  and stock movements.
- Stock movement history for entrées, sorties, adjustments, transfers, BL,
  direct facture, bon d'entrée, and avoir.
- Browser persistence for products, stock, documents, sequences, movements, and
  the audit log.
- Windows/macOS persistence through a local app-data JSON cache.
- Company profile with logo, company name, matricule fiscal, contact details,
  legal information, invoice footer, and configurable timbre fiscal.
- Sequence reconciliation so document numbering resumes after reloads.
- Audit trail for document creation, validation, conversion, and supplier
  reception, stock operations, payments, and settings.
- Basic invoice payment tracking: non payée, partiellement payée, payée.
- Dashboard with monthly sales, daily sales, low stock alerts, best sellers, and
  fast actions.
- Reports for sales, purchases, low stock, stock movement, and estimated margin.
- WhatsApp share opens an external share URL where the platform supports it.

## Business rules

- A validated BL decreases stock.
- A validated Bon d'entrée increases stock.
- A facture created from a BL does not change stock again.
- A direct facture represents an immediate delivered sale and decreases stock
  when validated.
- A direct facture cannot be created when stock is insufficient.
- A devis can create one active BL.
- A BL can create one active facture.
- An invoice can create one active avoir.
- A validated avoir reintegrates returned stock.
- Canceling a stock-impacting validated document reverses the stock movement
  unless a child document blocks the cancellation.
- Validated and canceled documents are locked from unsafe editing.

## Run

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8081
flutter run -d macos
```

On Windows, run from a Windows host:

```bash
flutter run -d windows
```

## Verify

```bash
flutter analyze
flutter test
flutter build web
flutter build macos
```

Windows release builds must be produced on Windows:

```bash
flutter build windows
```

## Notes

This is still local-first. Web stores data in browser localStorage; macOS and
Windows store a JSON cache in the user's app data folder. The app supports JSON
export/import for client backup or migration. A full multi-user deployment
should add authentication, server-side database persistence, accountant-reviewed
numbering policies, automated backups, and Tunisian e-invoicing integrations
where required.
