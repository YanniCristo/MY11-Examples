import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../core/widgets/app_menu.dart';
import '../premium/lifetime_sheet.dart';
import '../../core/widgets/language_button.dart';
import '../../core/widgets/large_file_dialog.dart';
import '../../core/widgets/password_dialog.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/brand.dart';
import '../editor/application/saved_work.dart';
import '../rubble/application/rubble_store.dart';
import '../rubble/presentation/collection_screen.dart';
import '../rubble/presentation/counter_bar.dart';
import '../rubble/presentation/rubble_menu.dart';
import '../editor/presentation/editor_screen.dart';
import '../image_processing/services/image_loader.dart';
import '../image_processing/services/web_pick/web_pick.dart';
import '../pdf_processing/services/pdf_loader.dart';
import '../pdf_processing/services/pdf_service.dart';
import '../settings/preferences.dart';
import '../settings/work_file/work_file_store.dart';
import 'demo_illustration.dart';

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
  SavedWork? _saved;

  @override
  void initState() {
    super.initState();
    _saved = SavedWork.decode(widget.preferences.savedWork);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshSaved());
  }

  /// Copia del file del lavoro in sospeso, letta in anticipo: così
  /// "Riprendi" riparte subito, e se la copia non c'è il pulsante apre
  /// direttamente la scelta delle foto (niente cerchio bianco di Safari).
  Uint8List? _savedBytes;
  bool _savedChecked = false;

  void _refreshSaved() {
    if (!mounted) return;
    final w = SavedWork.decode(widget.preferences.savedWork);
    setState(() {
      _saved = w;
      _savedBytes = null;
      _savedChecked = false;
    });
    if (w == null) return;
    WorkFileStore.instance
        .load(name: w.name, size: w.size, isPdf: w.isPdf)
        .then(
          (bytes) {
            if (!mounted || _saved != w) return;
            setState(() {
              _savedBytes = bytes;
              _savedChecked = true;
            });
          },
          onError: (_) {
            if (mounted && _saved == w) setState(() => _savedChecked = true);
          },
        );
  }

  Future<void> _discard() async {
    await widget.preferences.clearSavedWork();
    await WorkFileStore.instance.clear();
    _refreshSaved();
  }

  Future<void> _resume() async {
    final w = _saved;
    if (w == null || _loading) return;
    final ready = _savedBytes;
    if (ready != null) {
      w.isPdf
          ? _loadPdf(resume: w, bytes: ready)
          : _loadImage(resume: w, bytes: ready);
      return;
    }
    if (_savedChecked) {
      // nessuna copia: si sceglie di nuovo lo stesso file
      _toast(S.resumeHint);
      w.isPdf ? _loadPdf(resume: w) : _loadImage(resume: w);
      return;
    }
    // c'è la copia del file: si riparte subito, senza sceglierlo di nuovo
    setState(() => _loading = true);
    final bytes = await WorkFileStore.instance.load(
      name: w.name,
      size: w.size,
      isPdf: w.isPdf,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (bytes != null) {
      w.isPdf
          ? _loadPdf(resume: w, bytes: bytes)
          : _loadImage(resume: w, bytes: bytes);
      return;
    }
    _toast(S.resumeHint);
    w.isPdf ? _loadPdf(resume: w) : _loadImage(resume: w);
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _loadImage({SavedWork? resume, Uint8List? bytes}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final picked = bytes != null && resume != null
          ? PickedImages.single(await ImageLoader.decode(bytes, resume.name))
          : await _loader.pickMany(
              confirmSize: (bytes) => confirmLargeImages(context, bytes),
              onTruncated: (max) => _toast(S.onlyFirstImages(max)),
            );
      if (picked == null || !mounted) return;
      final first = picked.files.first.bytes;
      if (bytes == null && picked.length == 1 && first != null) {
        WorkFileStore.instance.stage(
          first,
          name: picked.files.first.name,
          isPdf: false,
        );
      }
      if (resume != null &&
          (picked.length != 1 ||
              !resume.matches(
                isPdf: false,
                name: picked.files.first.name,
                size: picked.files.first.bytes?.length ?? -1,
              ))) {
        for (final d in picked.decoded) {
          d?.dispose();
        }
        _toast(S.resumeWrongFile(resume.name));
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditorScreen(
            images: picked,
            preferences: widget.preferences,
            restore: resume,
          ),
        ),
      );
      _refreshSaved();
    } on ImageLoadException catch (e) {
      _toast(e.tooLarge ? S.tooLarge : S.loadFailed);
    } catch (_) {
      _toast(S.loadFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPdf({SavedWork? resume, Uint8List? bytes}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      Future<String?> ask({required bool wrong}) =>
          askPdfPassword(context, wrong: wrong);
      final pdf = bytes != null && resume != null
          ? await PdfSession.open(bytes, resume.name, askPassword: ask)
          : await _pdfLoader.pick(
              askPassword: ask,
              confirmSize: (bytes) => confirmLargePdf(context, bytes),
              onBytes: (b, name) =>
                  WorkFileStore.instance.stage(b, name: name, isPdf: true),
            );
      if (pdf == null || !mounted) return;
      if (resume != null &&
          !resume.matches(isPdf: true, name: pdf.name, size: pdf.fileSize)) {
        await pdf.dispose();
        _toast(S.resumeWrongFile(resume.name));
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditorScreen(
            pdf: pdf,
            preferences: widget.preferences,
            restore: resume,
          ),
        ),
      );
      _refreshSaved();
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
              Row(
                children: [
                  const Flexible(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: BrandMark(size: 30),
                      ),
                    ),
                  ),
                  LifetimeChip(listenable: RubbleStore.instance),
                  const SizedBox(width: 8),
                  LanguageButton(preferences: widget.preferences),
                  const SizedBox(width: 8),
                  MenuButton(
                    onTap: () => showAppMenu(
                      context,
                      preferences: widget.preferences,
                      sections: rubbleMenuSections(
                        context,
                        RubbleStore.instance,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                S.editor,
                style: TextStyle(
                  fontFamily: kDisplayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                  height: 1.1,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              CounterBar(
                store: RubbleStore.instance,
                awake: widget.preferences.smashEnabled,
                compact: false,
                onTap: () =>
                    CollectionScreen.open(context, RubbleStore.instance),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Flexible(child: _DemoCard()),
                    const SizedBox(height: 18),
                    if (_saved != null) ...[
                      _ResumeCard(
                        work: _saved!,
                        // immagine senza copia: il dito tocca la scelta foto
                        pickImage:
                            _savedChecked &&
                            _savedBytes == null &&
                            !_saved!.isPdf,
                        onResume: _loading ? null : _resume,
                        onDiscard: _loading ? null : _discard,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ImagePickTarget(
                            onTap: _loading ? null : () => _loadImage(),
                            child: AppButton(
                              label: S.loadImage,
                              icon: const Icon(Icons.image_outlined),
                              style: AppButtonStyle.primary,
                              height: 58,
                              fontSize: 18,
                              onPressed: _loading ? null : _loadImage,
                            ),
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
                        : Text(
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
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final full = w * DemoIllustration.h / DemoIllustration.w;
                    final hh = c.maxHeight.isFinite
                        ? (c.maxHeight < full ? c.maxHeight : full)
                        : full;
                    return SizedBox(
                      width: w,
                      height: hh,
                      child: const ClipRect(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          alignment: Alignment(0, .35),
                          child: DemoIllustration(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
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

/// Lavoro rimasto a metà (per esempio dopo un ricaricamento della pagina).
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.work,
    this.pickImage = false,
    required this.onResume,
    required this.onDiscard,
  });

  final SavedWork work;
  final bool pickImage;
  final VoidCallback? onResume;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red.withValues(alpha: .6)),
      ),
      child: Row(
        children: [
          Icon(
            work.isPdf ? Icons.description_outlined : Icons.image_outlined,
            color: AppColors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.resumeTitle,
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  S.resumeBody(work.name, work.cutCount, work.removed.length),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                child: pickImage
                    ? ImagePickTarget(
                        onTap: onResume,
                        child: AppButton(
                          label: S.resume,
                          style: AppButtonStyle.primary,
                          height: 38,
                          fontSize: 15,
                          onPressed: onResume,
                        ),
                      )
                    : AppButton(
                        label: S.resume,
                        style: AppButtonStyle.primary,
                        height: 38,
                        fontSize: 15,
                        onPressed: onResume,
                      ),
              ),
              SizedBox(
                height: 30,
                child: TextButton(
                  onPressed: onDiscard,
                  child: Text(
                    S.discard,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
