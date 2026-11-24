import 'package:file_picker/file_picker.dart';
import 'package:file_picker_web/file_picker_web.dart';

/// Su iPhone Safari restituisce la pagina prima di consegnare il file: con
/// un file da iCloud (download di qualche secondo) il selettore lo scambiava
/// per un annullamento e il PDF non si apriva. L'annullamento vero arriva
/// comunque con l'evento `cancel` del campo file.
const WebOptions pickerWebOptions = FilePickerWebOptions(
  cancelUploadOnWindowBlur: false,
);
