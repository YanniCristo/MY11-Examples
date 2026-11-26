/// Fuori dal browser non serve: si usa audioplayers.
class WebAudio {
  static final WebAudio instance = WebAudio();
  Future<void> load(String asset) async {}
  bool play(String asset, {double volume = 1}) => false;
}
