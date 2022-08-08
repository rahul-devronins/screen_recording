import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_painter/flutter_painter.dart';
import 'package:helpers/helpers/transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:screenrecorder/custom_progress_indicator.dart';
import 'package:screenrecorder/screens/crop_screen.dart';
import 'package:screenrecorder/screens/video_editor_screen.dart';
import 'package:screenrecorder/selected_sticker_image_dialog.dart';
import 'package:screenrecorder/video_items.dart';
import 'package:screenrecorder/video_piker.dart';
import 'package:video_editor/domain/bloc/controller.dart';
import 'package:video_editor/domain/entities/crop_style.dart';
import 'package:video_editor/ui/crop/crop_grid.dart';
import 'package:video_editor/ui/trim/trim_slider.dart';
import 'package:video_editor/ui/trim/trim_timeline.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' as ui;

import '../custom_controller_video.dart';
import '../render_image_dialog.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static const Color red = Color(0xFFFF0000);
  FocusNode textFocusNode = FocusNode();
  late PainterController controller;

  ui.Image? backgroundImage;
  Paint shapePaint = Paint()
    ..strokeWidth = 5
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static const List<String> imageLinks = [
    "https://i.imgur.com/btoI5OX.png",
    "https://i.imgur.com/EXTQFt7.png",
    "https://i.imgur.com/EDNjJYL.png",
    "https://i.imgur.com/uQKD6NL.png",
    "https://i.imgur.com/cMqVRbl.png",
    "https://i.imgur.com/1cJBAfI.png",
    "https://i.imgur.com/eNYfHKL.png",
    "https://i.imgur.com/c4Ag5yt.png",
    "https://i.imgur.com/GhpCJuf.png",
    "https://i.imgur.com/XVMeluF.png",
    "https://i.imgur.com/mt2yO6Z.png",
    "https://i.imgur.com/rw9XP1X.png",
    "https://i.imgur.com/pD7foZ8.png",
    "https://i.imgur.com/13Y3vp2.png",
    "https://i.imgur.com/ojv3yw1.png",
    "https://i.imgur.com/f8ZNJJ7.png",
    "https://i.imgur.com/BiYkHzw.png",
    "https://i.imgur.com/snJOcEz.png",
    "https://i.imgur.com/b61cnhi.png",
    "https://i.imgur.com/FkDFzYe.png",
    "https://i.imgur.com/P310x7d.png",
    "https://i.imgur.com/5AHZpua.png",
    "https://i.imgur.com/tmvJY4r.png",
    "https://i.imgur.com/PdVfGkV.png",
    "https://i.imgur.com/1PRzwBf.png",
    "https://i.imgur.com/VeeMfBS.png",
  ];
  EdScreenRecorder? screenRecorder;
  Map<String, dynamic>? _response;
  bool inProgress = false;
  File? file;
  File? result;
  late VideoEditorController _controller;
  late VideoPlayerController _videoPlayerController;
  double sliderValue = 0.0;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    screenRecorder = EdScreenRecorder();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 450));
    controller = PainterController(
      settings: PainterSettings(
          text: TextSettings(
            focusNode: textFocusNode,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, color: red, fontSize: 18),
          ),
          freeStyle: const FreeStyleSettings(
            color: red,
            strokeWidth: 5,
          ),
          shape: ShapeSettings(
            paint: shapePaint,
          ),
          scale: const ScaleSettings(
            enabled: true,
            minScale: 1,
            maxScale: 5,
          )),
    );
    // Listen to focus events of the text field
    textFocusNode.addListener(onFocus);
    // Initialize background
    initBackground();
    _videoPlayerController = VideoPlayerController.network(
        'https://assets.mixkit.co/videos/preview/mixkit-a-girl-blowing-a-bubble-gum-at-an-amusement-park-1226-large.mp4')
      ..initialize().then((value) => setState(() {}));
    super.initState();
  }

  void initBackground() async {
    // Extension getter (.image) to get [ui.Image] from [ImageProvider]
    final image = await const NetworkImage(
            'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/HD_transparent_picture.png/800px-HD_transparent_picture.png')
        .image;

    setState(() {
      backgroundImage = image;
      controller.background = image.backgroundDrawable;
    });
  }

  /// Updates UI when the focus changes
  void onFocus() {
    setState(() {});
  }

  Future<void> startRecord({required String fileName}) async {
    Directory? tempDir = await getApplicationDocumentsDirectory();
    String? tempPath = tempDir.path;
    try {
      var startResponse = await screenRecorder?.startRecordScreen(
        fileName: fileName,
        //Optional. It will save the video there when you give the file path with whatever you want.
        //If you leave it blank, the Android operating system will save it to the gallery.
        dirPathToSave: tempPath,
        audioEnable: true,
      );
      setState(() {
        _response = startResponse;
      });
      try {
        screenRecorder?.watcher?.events.listen(
          (event) {
            log(event.type.toString(), name: "Event: ");
          },
          onError: (e) => kDebugMode ? debugPrint('ERROR ON STREAM: $e') : null,
          onDone: () {
            kDebugMode ? debugPrint('Watcher closed!') : null;
          },
        );
      } catch (e) {
        kDebugMode ? debugPrint('ERROR WAITING FOR READY: $e') : null;
      }
    } on PlatformException {
      kDebugMode ? debugPrint("Error: An error occurred while starting the recording!") : null;
    }
  }

  Future<void> pauseRecord() async {
    try {
      await screenRecorder?.pauseRecord();
    } on PlatformException {
      kDebugMode ? debugPrint("Error: An error occurred while pause recording.") : null;
    }
  }

  Future<void> resumeRecord() async {
    try {
      await screenRecorder?.resumeRecord();
    } on PlatformException {
      kDebugMode ? debugPrint("Error: An error occurred while resume recording.") : null;
    }
  }

  Future<void> stopRecord() async {
    try {
      var stopResponse = await screenRecorder?.stopRecord();
      setState(() {
        _response = stopResponse;
        file = _response!['file'];
        print("FILE:$file");
      });
      if (!mounted) return;
      if (file != null) {
        _controller = VideoEditorController.file(file!, maxDuration: const Duration(seconds: 60))..initialize().then((_) => setState(() {}));
        await Navigator.push(context, MaterialPageRoute(builder: (context) => CropScreen(controller: _controller))).then((value) {
          setState(() {
            result = value;
          });
        });
      }
    } on PlatformException {
      kDebugMode ? debugPrint("Error: An error occurred while stopping recording.") : null;
    }
  }

  String formatter(Duration duration) =>
      [duration.inMinutes.remainder(60).toString().padLeft(2, '0'), duration.inSeconds.remainder(60).toString().padLeft(2, '0')].join(":");
  final double height = 60;

  AnimationController? _animationController;
  bool isPlaying = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size(double.infinity, kToolbarHeight),
          child: ValueListenableBuilder<PainterControllerValue>(
              valueListenable: controller,
              child: Text("Painting"),
              builder: (context, _, child) {
                return AppBar(
                  title: child,
                  actions: [
                    // IconButton(
                    //   icon: const Icon(PhosphorIcons.trash),
                    //   onPressed: controller.selectedObjectDrawable == null ? null : removeSelectedDrawable,
                    // ),
                    // IconButton(
                    //   icon: const Icon(
                    //     Icons.flip,
                    //   ),
                    //   onPressed: controller.selectedObjectDrawable != null && controller.selectedObjectDrawable is ImageDrawable
                    //       ? flipSelectedImageDrawable
                    //       : null,
                    // ),
                    IconButton(
                      icon: const Icon(
                        PhosphorIcons.arrowClockwise,
                      ),
                      onPressed: controller.canRedo ? redo : null,
                    ),
                    IconButton(
                      icon: const Icon(
                        PhosphorIcons.arrowCounterClockwise,
                      ),
                      onPressed: controller.canUndo ? undo : null,
                    ),
                    IconButton(
                        onPressed: () {
                          setState(() {
                            isPlaying = !isPlaying;
                            isPlaying ? _animationController!.forward() : _animationController!.reverse();
                          });
                          if (isPlaying) {
                            startRecord(fileName: "eren");
                          } else {
                            stopRecord();
                          }
                        },
                        icon: AnimatedIcon(icon: AnimatedIcons.play_pause, color: Colors.red, progress: _animationController!)),
                  ],
                );
              }),
        ),
        // Generate image
        // floatingActionButton: FloatingActionButton(
        //   onPressed: renderAndDisplayImage,
        //   child: const Icon(
        //     PhosphorIcons.imageFill,
        //   ),
        // ),
        body: Column(
          children: [
            result != null
                ? Expanded(
                    child: VideoItems(
                      videoPlayerController: VideoPlayerController.file(result!),
                      autoplay: false,
                      looping: false,
                    ),
                  )
                : Container(),
            Expanded(
              child: Stack(
                children: [
                  if (backgroundImage != null && result == null)
                    Positioned.fill(
                      child: Center(
                        child: Stack(
                          children: [
                            VideoItems(
                              videoPlayerController: _videoPlayerController,
                              looping: false,
                              autoplay: true,
                            ),
                            FlutterPainter(
                              controller: controller,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: ValueListenableBuilder(
                      valueListenable: controller,
                      builder: (context, _, __) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: 400,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                color: Colors.white54,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (controller.freeStyleMode != FreeStyleMode.none) ...[
                                    const Divider(),
                                    const Text("Free Style Settings"),
                                    // Control free style stroke width
                                    Row(
                                      children: [
                                        const Expanded(flex: 1, child: Text("Stroke Width")),
                                        Expanded(
                                          flex: 3,
                                          child: Slider.adaptive(
                                              min: 2, max: 25, value: controller.freeStyleStrokeWidth, onChanged: setFreeStyleStrokeWidth),
                                        ),
                                      ],
                                    ),
                                    if (controller.freeStyleMode == FreeStyleMode.draw)
                                      Row(
                                        children: [
                                          const Expanded(flex: 1, child: Text("Color")),
                                          // Control free style color hue
                                          Expanded(
                                            flex: 3,
                                            child: Slider.adaptive(
                                                min: 0,
                                                max: 359.99,
                                                value: HSVColor.fromColor(controller.freeStyleColor).hue,
                                                activeColor: controller.freeStyleColor,
                                                onChanged: setFreeStyleColor),
                                          ),
                                        ],
                                      ),
                                  ],
                                  if (textFocusNode.hasFocus) ...[
                                    const Divider(),
                                    const Text("Text settings"),
                                    // Control text font size
                                    Row(
                                      children: [
                                        const Expanded(flex: 1, child: Text("Font Size")),
                                        Expanded(
                                          flex: 3,
                                          child: Slider.adaptive(
                                              min: 8, max: 96, value: controller.textStyle.fontSize ?? 14, onChanged: setTextFontSize),
                                        ),
                                      ],
                                    ),

                                    // Control text color hue
                                    Row(
                                      children: [
                                        const Expanded(flex: 1, child: Text("Color")),
                                        Expanded(
                                          flex: 3,
                                          child: Slider.adaptive(
                                              min: 0,
                                              max: 359.99,
                                              value: HSVColor.fromColor(controller.textStyle.color ?? red).hue,
                                              activeColor: controller.textStyle.color,
                                              onChanged: setTextColor),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (controller.shapeFactory != null) ...[
                                    const Divider(),
                                    const Text("Shape Settings"),

                                    // Control text color hue
                                    Row(
                                      children: [
                                        const Expanded(flex: 1, child: Text("Stroke Width")),
                                        Expanded(
                                          flex: 3,
                                          child: Slider.adaptive(
                                              min: 2,
                                              max: 25,
                                              value: controller.shapePaint?.strokeWidth ?? shapePaint.strokeWidth,
                                              onChanged: (value) => setShapeFactoryPaint((controller.shapePaint ?? shapePaint).copyWith(
                                                    strokeWidth: value,
                                                  ))),
                                        ),
                                      ],
                                    ),

                                    // Control shape color hue
                                    Row(
                                      children: [
                                        const Expanded(flex: 1, child: Text("Color")),
                                        Expanded(
                                          flex: 3,
                                          child: Slider.adaptive(
                                              min: 0,
                                              max: 359.99,
                                              value: HSVColor.fromColor((controller.shapePaint ?? shapePaint).color).hue,
                                              activeColor: (controller.shapePaint ?? shapePaint).color,
                                              onChanged: (hue) => setShapeFactoryPaint((controller.shapePaint ?? shapePaint).copyWith(
                                                    color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                                                  ))),
                                        ),
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        const Expanded(flex: 1, child: Text("Fill shape")),
                                        Expanded(
                                          flex: 3,
                                          child: Center(
                                            child: Switch(
                                                value: (controller.shapePaint ?? shapePaint).style == PaintingStyle.fill,
                                                onChanged: (value) => setShapeFactoryPaint((controller.shapePaint ?? shapePaint).copyWith(
                                                      style: value ? PaintingStyle.fill : PaintingStyle.stroke,
                                                    ))),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center(
            //   child: Column(
            //     children: [
            //       VideoItems(
            //         videoPlayerController: VideoPlayerController.network(
            //             'https://assets.mixkit.co/videos/preview/mixkit-a-girl-blowing-a-bubble-gum-at-an-amusement-park-1226-large.mp4'),
            //         looping: true,
            //         autoplay: false,
            //       ),
            //
            //       result != null
            //           ? VideoItems(
            //               videoPlayerController: VideoPlayerController.file(result!),
            //               autoplay: false,
            //               looping: false,
            //             )
            //           : Container()
            //
            //       // file == null
            //       //     ? Container()
            //       //     : VideoItems(
            //       //         videoPlayerController: VideoPlayerController.file(file!),
            //       //         looping: true,
            //       //         autoplay: true,
            //       //       ),
            //       // Text("File: ${(_response?['file'] as File?)?.path}"),
            //       // Text("Status: ${(_response?['success']).toString()}"),
            //       // Text("Event: ${_response?['eventname']}"),
            //       // Text("Progress: ${(_response?['progressing']).toString()}"),
            //       // Text("Message: ${_response?['message']}"),
            //       // Text("Video Hash: ${_response?['videohash']}"),
            //       // Text("Start Date: ${(_response?['startdate']).toString()}"),
            //       // Text("End Date: ${(_response?['enddate']).toString()}"),
            //       // ElevatedButton(onPressed: () => startRecord(fileName: "eren"), child: const Text('START RECORD')),
            //       // ElevatedButton(onPressed: () => stopRecord(), child: const Text('STOP RECORD')),
            //       // Wrap(
            //       //   children: [
            //       //     OutlinedButton(onPressed: () {}, child: Text('Outline Button')),
            //       //     ElevatedButton(onPressed: () {}, child: Text('Outline Button')),
            //       //     TextButton(onPressed: () {}, child: Text('Text Button')),
            //       //     IconButton(
            //       //         onPressed: () {
            //       //           setState(() {
            //       //             isPlaying = !isPlaying;
            //       //             isPlaying ? _animationController!.forward() : _animationController!.reverse();
            //       //           });
            //       //         },
            //       //         icon: AnimatedIcon(
            //       //           icon: AnimatedIcons.menu_arrow,
            //       //           progress: _animationController!,
            //       //           semanticLabel: 'Show menu',
            //       //         ))
            //       //   ],
            //       // )
            //     ],
            //   ),
            // ),
            result == null
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomVideoProgressIndicator(_videoPlayerController, allowScrubbing: true),
                  )
                : Container(),
          ],
        ),
        bottomNavigationBar: ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, _, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Free-style eraser
                    // IconButton(
                    //   icon: Icon(
                    //     PhosphorIcons.eraser,
                    //     color: controller.freeStyleMode == FreeStyleMode.erase ? Theme.of(context).accentColor : null,
                    //   ),
                    //   onPressed: toggleFreeStyleErase,
                    // ),
                    // Free-style drawing
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.scribbleLoop,
                        color: controller.freeStyleMode == FreeStyleMode.draw ? Theme.of(context).accentColor : null,
                      ),
                      onPressed: toggleFreeStyleDraw,
                    ),
                    // Add text
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.textT,
                        color: textFocusNode.hasFocus ? Theme.of(context).accentColor : null,
                      ),
                      onPressed: addText,
                    ),
                    // Add sticker image
                    // IconButton(
                    //   icon: const Icon(PhosphorIcons.sticker),
                    //   onPressed: addSticker,
                    // ),
                    // Add shapes
                    if (controller.shapeFactory == null)
                      PopupMenuButton<ShapeFactory?>(
                        tooltip: "Add shape",
                        itemBuilder: (context) => <ShapeFactory, String>{
                          LineFactory(): "Line",
                          ArrowFactory(): "Arrow",
                          DoubleArrowFactory(): "Double Arrow",
                          RectangleFactory(): "Rectangle",
                          OvalFactory(): "Oval",
                        }
                            .entries
                            .map((e) => PopupMenuItem(
                                value: e.key,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      getShapeIcon(e.key),
                                      color: Colors.black,
                                    ),
                                    Text(" ${e.value}")
                                  ],
                                )))
                            .toList(),
                        onSelected: selectShape,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            getShapeIcon(controller.shapeFactory),
                            color: controller.shapeFactory != null ? Theme.of(context).accentColor : null,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          getShapeIcon(controller.shapeFactory),
                          color: Theme.of(context).accentColor,
                        ),
                        onPressed: () => selectShape(null),
                      ),
                  ],
                )));
  }

  static IconData getShapeIcon(ShapeFactory? shapeFactory) {
    if (shapeFactory is LineFactory) return PhosphorIcons.lineSegment;
    if (shapeFactory is ArrowFactory) return PhosphorIcons.arrowUpRight;
    if (shapeFactory is DoubleArrowFactory) {
      return PhosphorIcons.arrowsHorizontal;
    }
    if (shapeFactory is RectangleFactory) return PhosphorIcons.rectangle;
    if (shapeFactory is OvalFactory) return PhosphorIcons.circle;
    return PhosphorIcons.polygon;
  }

  void undo() {
    controller.undo();
  }

  void redo() {
    controller.redo();
  }

  void toggleFreeStyleDraw() {
    controller.freeStyleMode = controller.freeStyleMode != FreeStyleMode.draw ? FreeStyleMode.draw : FreeStyleMode.none;
  }

  void toggleFreeStyleErase() {
    controller.freeStyleMode = controller.freeStyleMode != FreeStyleMode.erase ? FreeStyleMode.erase : FreeStyleMode.none;
  }

  void addText() {
    if (controller.freeStyleMode != FreeStyleMode.none) {
      controller.freeStyleMode = FreeStyleMode.none;
    }
    controller.addText();
  }

  void addSticker() async {
    final imageLink = await showDialog<String>(
        context: context,
        builder: (context) => const SelectStickerImageDialog(
              imagesLinks: imageLinks,
            ));
    if (imageLink == null) return;
    controller.addImage(await NetworkImage(imageLink).image, const Size(100, 100));
  }

  void setFreeStyleStrokeWidth(double value) {
    controller.freeStyleStrokeWidth = value;
  }

  void setFreeStyleColor(double hue) {
    controller.freeStyleColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
  }

  void setTextFontSize(double size) {
    // Set state is just to update the current UI, the [FlutterPainter] UI updates without it
    setState(() {
      controller.textSettings = controller.textSettings.copyWith(textStyle: controller.textSettings.textStyle.copyWith(fontSize: size));
    });
  }

  void setShapeFactoryPaint(Paint paint) {
    // Set state is just to update the current UI, the [FlutterPainter] UI updates without it
    setState(() {
      controller.shapePaint = paint;
    });
  }

  void setTextColor(double hue) {
    controller.textStyle = controller.textStyle.copyWith(color: HSVColor.fromAHSV(1, hue, 1, 1).toColor());
  }

  void selectShape(ShapeFactory? factory) {
    controller.shapeFactory = factory;
  }

  void renderAndDisplayImage() {
    if (backgroundImage == null) return;
    final backgroundImageSize = Size(backgroundImage!.width.toDouble(), backgroundImage!.height.toDouble());

    // Render the image
    // Returns a [ui.Image] object, convert to to byte data and then to Uint8List
    final imageFuture = controller.renderImage(backgroundImageSize).then<Uint8List?>((ui.Image image) => image.pngBytes);

    // From here, you can write the PNG image data a file or do whatever you want with it
    // For example:
    // ```dart
    // final file = File('${(await getTemporaryDirectory()).path}/img.png');
    // await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    // ```
    // I am going to display it using Image.memory

    // Show a dialog with the image
    showDialog(context: context, builder: (context) => RenderedImageDialog(imageFuture: imageFuture));
  }

  void removeSelectedDrawable() {
    final selectedDrawable = controller.selectedObjectDrawable;
    if (selectedDrawable != null) controller.removeDrawable(selectedDrawable);
  }

  void flipSelectedImageDrawable() {
    final imageDrawable = controller.selectedObjectDrawable;
    if (imageDrawable is! ImageDrawable) return;

    controller.replaceDrawable(imageDrawable, imageDrawable.copyWith(flipped: !imageDrawable.flipped));
  }
}
