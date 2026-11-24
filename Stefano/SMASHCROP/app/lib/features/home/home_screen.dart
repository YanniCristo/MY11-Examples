import 'package:material_ui/material_ui.dart';

import '../../core/widgets/password_dialog.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/brand.dart';
import '../editor/presentation/editor_screen.dart';
import '../image_processing/services/image_loader.dart';
import '../pdf_processing/services/pdf_loader.dart';
import '../pdf_processing/services/pdf_service.dart';
import '../settings/preferences.dart';

/// Schermata iniziale: spiega l'app con il prima/dopo e porta all'editor
/// con un solo tocco. Niente account, niente procedure introduttive.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _loader = ImageLoader();
  final _pdfLoader = const PdfLoader();
  bool _loading = false;

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _loadImage() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final img = await _loader.pick();
      if (img == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              EditorScreen(image: img, preferences: widget.preferences),
        ),
      );
    } on ImageLoadException catch (e) {
      _toast(e.tooLarge ? S.tooLarge : S.loadFailed);
    } catch (_) {
      _toast(S.loadFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPdf() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final pdf = await _pdfLoader.pick(
        askPassword: ({required bool wrong}) =>
            askPdfPassword(context, wrong: wrong),
      );
      if (pdf == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              EditorScreen(pdf: pdf, preferences: widget.preferences),
        ),
      );
    } on PdfOpenException catch (e) {
      if (!e.cancelled) {
        _toast(
          e.locked
              ? S.pdfLocked
              : (e.password
                    ? S.pdfPassword
                    : S.withDetail(S.pdfInvalid, e.detail)),
        );
      }
    } catch (e) {
      _toast(S.withDetail(S.pdfInvalid, '$e'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: BrandMark(size: 30),
              ),
              const SizedBox(height: 10),
              const Text(
                S.editor,
                style: TextStyle(
                  fontFamily: kDisplayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                  height: 1.1,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Flexible(child: _DemoCard()),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: S.loadImage,
                            icon: const Icon(Icons.image_outlined),
                            style: AppButtonStyle.primary,
                            height: 58,
                            fontSize: 18,
                            onPressed: _loading ? null : _loadImage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: S.loadPdf,
                            icon: const Icon(Icons.description_outlined),
                            height: 58,
                            fontSize: 18,
                            onPressed: _loading ? null : _loadPdf,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _loading
                        ? const Center(
                            child: SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.red,
                              ),
                            ),
                          )
                        : const Text(
                            S.homeHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 15,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La card al neon con il prima/dopo e SMASH col pollice alzato.
class _DemoCard extends StatelessWidget {
  const _DemoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.neonViolet, AppColors.neonPink, AppColors.red],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x55FF2BD6), blurRadius: 24, spreadRadius: -4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF070A1C), Color(0xFF120F24)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // al massimo alta quanto l'illustrazione: niente vuoti nella card;
              // se manca spazio si accorcia tagliando il cielo, non i documenti
              Flexible(
                child: LayoutBuilder(
                  builder: (context, c) => ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: c.maxWidth * 738 / 732,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Image.asset(
                        'assets/home/home_illustration.webp',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, .35),
                        semanticLabel: 'Esempio: una tabella tra due paragrafi viene rimossa e i paragrafi si uniscono',
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    Text(
                      S.homeTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 21,
                        height: 1.15,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      S.homeSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.35,
                        color: Color(0xFFCFC8EA),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
