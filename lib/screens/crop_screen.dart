import 'package:flutter/material.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/video_editor.dart';
import 'package:helpers/helpers.dart' show OpacityTransition, SwipeTransition, AnimatedInteractiveViewer;
import 'package:video_player/video_player.dart';

class CropScreen extends StatefulWidget {
  const CropScreen({Key? key, required this.controller}) : super(key: key);

  final VideoEditorController controller;

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  bool _exported = false;
  String _exportText = "";
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  void _exportCover() async {
    setState(() => _exported = false);
    await widget.controller.extractCover(
      onError: (e, s) => _exportText = "Error on cover exportation :(",
      onCompleted: (cover) {
        if (!mounted) return;

        _exportText = "Cover exported! ${cover.path}";
        showDialog(
          context: context,
          builder: (_) => Padding(
            padding: const EdgeInsets.all(30),
            child: Center(child: Image.memory(cover.readAsBytesSync())),
          ),
        );

        setState(() => _exported = true);
        Future.delayed(const Duration(seconds: 2), () => setState(() => _exported = false));
      },
    );
  }

  @override
  void initState() {
    Future.delayed(Duration(seconds: 2), () {
      widget.controller.preferredCropAspectRatio = 4 / 5;
      widget.controller.updateCrop();
    }).whenComplete(_exportVideo);

    super.initState();
  }

  void _exportVideo() async {
    _exportingProgress.value = 0;
    _isExporting.value = true;
    // NOTE: To use `-crf 1` and [VideoExportPreset] you need `ffmpeg_kit_flutter_min_gpl` package (with `ffmpeg_kit` only it won't work)
    await widget.controller.exportVideo(
      // preset: VideoExportPreset.medium,
      // customInstruction: "-crf 17",
      onProgress: (stats, value) {
        _exportingProgress.value = value;
        print("Progress:${_exportingProgress.value}");
      },
      onError: (e, s) {
        _exportText = "Error on export video :( $e";
        print("error$_exportText");
      },
      onCompleted: (file) {
        print("file exported$file");
        _isExporting.value = false;
        if (!mounted) return;
        // final VideoPlayerController videoController = VideoPlayerController.file(file);
        // videoController.initialize().then((value) async {
        //   setState(() {});
        //   videoController.play();
        //   videoController.setLooping(true);
        //   await showDialog(
        //     context: context,
        //     builder: (_) => Padding(
        //       padding: const EdgeInsets.all(30),
        //       child: Center(
        //         child: AspectRatio(
        //           aspectRatio: videoController.value.aspectRatio,
        //           child: VideoPlayer(videoController),
        //         ),
        //       ),
        //     ),
        //   );
        //   await videoController.pause();
        //   videoController.dispose();
        // });

        _exportText = "Video success export!";

        Future.delayed(
            const Duration(seconds: 2),
            () => setState(() {
                  print("file after exported$file");
                  Navigator.pop(context, file);
                }));
      },
    );
    print("_exportText:${_exportText}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: IconButton(
                  onPressed: () => widget.controller.rotate90Degrees(RotateDirection.left),
                  icon: const Icon(Icons.rotate_left, color: Colors.white),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () => widget.controller.rotate90Degrees(RotateDirection.right),
                  icon: const Icon(Icons.rotate_right, color: Colors.white),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: _exportCover,
                  icon: const Icon(Icons.save_alt, color: Colors.white),
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: _exportVideo,
                  icon: const Icon(Icons.save, color: Colors.white),
                ),
              ),
            ]),
            const SizedBox(height: 15),
            Expanded(
              child: AnimatedInteractiveViewer(
                child: CropGridViewer(controller: widget.controller, horizontalMargin: 60),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: _isExporting,
              builder: (_, bool export, __) => OpacityTransition(
                visible: export,
                child: AlertDialog(
                  backgroundColor: Colors.white,
                  title: ValueListenableBuilder(
                    valueListenable: _exportingProgress,
                    builder: (_, double value, __) => Text(
                      "Exporting video ${(value * 100).ceil()}%",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Center(
                    child: Text(
                      "CANCEL",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
              // buildSplashTap("16:9", 16 / 9, padding: const EdgeInsets.symmetric(horizontal: 10)),
              // buildSplashTap("1:1", 1 / 1),
              // buildSplashTap("4:5", 4 / 5, padding: const EdgeInsets.symmetric(horizontal: 10)),
              // buildSplashTap("NO", null, padding: const EdgeInsets.only(right: 10)),
              Expanded(
                child: IconButton(
                  onPressed: () {
                    //2 WAYS TO UPDATE CROP
                    //WAY 1:
                    widget.controller.updateCrop();
                    /*WAY 2:
                    controller.minCrop = controller.cacheMinCrop;
                    controller.maxCrop = controller.cacheMaxCrop;
                    */
                    // Navigator.pop(context);
                  },
                  icon: const Center(
                    child: Text(
                      "OK",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget buildSplashTap(
    String title,
    double? aspectRatio, {
    EdgeInsetsGeometry? padding,
  }) {
    return InkWell(
      onTap: () => widget.controller.preferredCropAspectRatio = aspectRatio,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.aspect_ratio, color: Colors.white),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
