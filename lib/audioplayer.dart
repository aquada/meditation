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
    await audioPlayer.setSource(AssetSource(audioFile));
    // applied after setSource(), not before: audioplayers can reset the
    // player's volume back to its default when a new source is set, which
    // would otherwise silently undo the gain we're about to apply
    await hijackVolume();
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

  Future<void> hijackVolume() async {
    if (volumeHijackable) {
      lastSystemVolume = await VolumeController().getVolume();
      volumeHijackable = false;
    }
    double fraction = (Settings.getValue<double>('volume') ?? 6.0) / 10.0;

    // Android's system volume is quantized into a handful of discrete steps
    // (as few as 7-15 depending on device), so a small fraction can round
    // down to 0 steps - true silence - instead of "quiet". Force the system
    // volume to full headroom instead, and do the actual, continuous
    // low-end attenuation via the player's own (unquantized) gain, so
    // slider 1 is genuinely quiet rather than either too loud or silent.
    VolumeController().setVolume(1.0);
    await audioPlayer.setVolume(fraction * fraction);
  }

  void restoreVolume() {
    VolumeController().setVolume(lastSystemVolume);
    audioPlayer.setVolume(1.0);
    volumeHijackable = true;
  }
}
