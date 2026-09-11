import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:volume_controller/volume_controller.dart';

import 'package:meditation/settings.dart';
import 'package:meditation/utils.dart';

class NAudioPlayer {
  final audioPlayer = AudioPlayer();
  double lastSystemVolume = 0;
  bool volumeHijackable = true;

  NAudioPlayer() {
    init();
  }

  void init() {
    log.i("naudioplayer init");
    // can only hide on android
    VolumeController().showSystemUI = false;
  }

  Future<void> play(String audioFile) async {
    stopPrevious();
    hijackVolume();
    await audioPlayer.setSource(AssetSource(audioFile));
    await audioPlayer.resume();
    // restore volume when audio is done playing
    audioPlayer.onPlayerComplete.listen((_) {
      restoreVolume();
    });
  }

  Future<int> stopPrevious() async {
    await audioPlayer.stop();
    return 0;
  }

  Future<void> playSound(String soundKey) async {
    int audioIndex = Settings.getValue<int>(soundKey) ?? 0;
    String audioFile = audioFiles.keys.elementAt(audioIndex);
    await play(audioFile);
  }

  void hijackVolume() async {
    if (volumeHijackable) {
      lastSystemVolume = await VolumeController().getVolume();
      volumeHijackable = false;
    }
    // slider step is 0.5 (see settings.dart) specifically so the low end
    // has finer steps to choose from - the quietest step that's still
    // audible is device-dependent (Android's system volume is a small
    // number of discrete steps, varying by device), so this is
    // deliberately just a plain linear mapping rather than a guessed
    // curve: pick whichever step actually works on your phone.
    double volume = (Settings.getValue<double>('volume') ?? 6.0) / 10.0;
    VolumeController().setVolume(volume);
  }

  void restoreVolume() {
    VolumeController().setVolume(lastSystemVolume);
    volumeHijackable = true;
  }
}
