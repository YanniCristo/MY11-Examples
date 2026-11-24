import 'package:file_picker/file_picker.dart';

import 'pdf_service.dart';
import 'picker_options/picker_options.dart';

/// Importa un PDF scelto dall'utente.
class PdfLoader {
  const PdfLoader();

  /// `null` se l'utente annulla la scelta.
  Future<PdfSession?> pick({PasswordPrompt? askPassword}) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      webOptions: pickerWebOptions,
    );
    if (file == null) return null;
    final bytes = await file.xFile.readAsBytes();
    return PdfSession.open(bytes, file.name, askPassword: askPassword);
  }
}
