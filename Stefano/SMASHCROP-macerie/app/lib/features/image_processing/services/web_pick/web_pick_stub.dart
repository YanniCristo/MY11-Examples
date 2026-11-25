import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

/// Solo per il browser.
Future<List<XFile>> pickImagesWeb() async => const [];

void watchPointerWeb() {}

/// Fuori dal browser il pulsante resta com'è.
class ImagePickTarget extends StatelessWidget {
  const ImagePickTarget({super.key, required this.onTap, required this.child});
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
