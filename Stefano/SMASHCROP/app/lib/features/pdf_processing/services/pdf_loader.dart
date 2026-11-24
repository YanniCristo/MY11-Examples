import 'package:file_picker/file_picker.dart';

import 'pdf_service.dart';

/// Importa un PDF scelto dall'utente.
class PdfLoader {
  const PdfLoader();

  /// `null` se l'utente annulla la scelta.
  Future<PdfSession?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null) return null;
    final bytes = await file.xFile.readAsBytes();
    return PdfSession.open(bytes, file.name);
  }
}
