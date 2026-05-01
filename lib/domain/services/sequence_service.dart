import '../app_enums.dart';
import '../app_models.dart';

class SequenceService {
  const SequenceService._();

  static Map<DocumentType, int> initialSequences({int initialValue = 1}) {
    return {for (final type in DocumentType.values) type: initialValue};
  }

  static int? sequenceFromNumber({
    required String number,
    required DocumentType type,
    required int year,
  }) {
    final prefix = '${type.prefix}-$year-';
    if (!number.startsWith(prefix)) return null;
    return int.tryParse(number.substring(prefix.length));
  }

  static Map<DocumentType, int> reconcile({
    required Map<DocumentType, int> sequences,
    required Iterable<BusinessDocument> documents,
    DateTime? now,
  }) {
    final year = (now ?? DateTime.now()).year;
    final reconciled = Map<DocumentType, int>.from(sequences);
    for (final type in DocumentType.values) {
      var next = reconciled[type] ?? 1;
      for (final document in documents.where((item) => item.type == type)) {
        final sequence = sequenceFromNumber(
          number: document.number,
          type: type,
          year: year,
        );
        if (sequence != null && sequence >= next) {
          next = sequence + 1;
        }
      }
      reconciled[type] = next;
    }
    return reconciled;
  }

  static String peekNextNumber({
    required Map<DocumentType, int> sequences,
    required DocumentType type,
    DateTime? now,
  }) {
    final year = (now ?? DateTime.now()).year;
    final next = sequences[type] ?? 1;
    return '${type.prefix}-$year-${next.toString().padLeft(4, '0')}';
  }

  static String consumeNextNumber({
    required Map<DocumentType, int> sequences,
    required DocumentType type,
    DateTime? now,
  }) {
    final number = peekNextNumber(sequences: sequences, type: type, now: now);
    sequences[type] = (sequences[type] ?? 1) + 1;
    return number;
  }
}
