import 'package:file_picker/file_picker.dart';

import 'pdf_service.dart';
import 'picker_options/picker_options.dart';

/// Importa un PDF scelto dall'utente.
class PdfLoader {
  const PdfLoader();

  /// `null` se l'utente annulla la scelta.
  /// [confirmSize] riceve il peso del file prima di leggerlo: se risponde
  /// `false` l'apertura si annulla.
  Future<PdfSession?> pick({
    PasswordPrompt? askPassword,
    Future<bool> Function(int bytes)? confirmSize,
  }) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      webOptions: pickerWebOptions,
    );
    if (file == null) return null;
    if (confirmSize != null && !await confirmSize(await file.length() ?? 0)) {
      return null;
    }
    final bytes = await file.xFile.readAsBytes();
    return PdfSession.open(bytes, file.name, askPassword: askPassword);
  }
}
