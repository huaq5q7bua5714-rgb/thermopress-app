import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:poct_app/util/snack_bar_manager.dart';

class CameraService {
 
  CameraController? _controller;

  // // 获取可用的相机列表
  // Future<List<CameraDescription>> getAvailableCameras() async {
  //   return await availableCameras();
  // }

  // 初始化相机
  Future<void> initializeCamera(CameraDescription camera) async {
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
    );
    await _controller!.initialize();  // 确保初始化完成
  }

  // 获取相机控制器
  CameraController? get controller => _controller;

  // 拍照并返回文件路径
  Future<String?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    try {
      final image = await _controller!.takePicture();
      return image.path;
    } catch (e) {
      print("拍照失败: $e");
      return null;
    }
  }

  // 释放相机资源
  void dispose() {
    _controller?.dispose();
  }
}

/// 相机拍照界面，依赖 CameraService
class TakePictureScreen extends StatefulWidget {
  final CameraService cameraService;

  const TakePictureScreen({super.key, required this.cameraService});

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  @override
  void dispose() {
    widget.cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("相机")),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: widget.cameraService.controller?.initialize(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(widget.cameraService.controller!);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: FloatingActionButton(
                onPressed: () async {      
                  try {
                    final imagePath = await widget.cameraService.takePicture();
                    if (imagePath == null || !context.mounted) return;

                    // 跳转到预览页面并传递路径
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PhotoPreviewScreen(imagePath: imagePath),
                      ),
                    );
                  } catch (e) {
                    print(e);
                  }
                },
                child: const Icon(Icons.camera_alt),
                shape: const CircleBorder(),
                // backgroundColor: Colors.white,
                // foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      )      
    );
  }
}

/// 显示图片预览
class PhotoPreviewScreen extends StatelessWidget {
  final String imagePath;

  PhotoPreviewScreen({super.key, required this.imagePath});

  Future<void> saveAndUpload(BuildContext context) async {
    // 保存到相册
    await SaverGallery.saveFile(
      filePath: imagePath, 
      fileName: "IMG_${DateTime.now().millisecondsSinceEpoch}", 
      skipIfExists: false
      );
    
    // 模拟上传操作
    await uploadPhoto(imagePath);

    // 显示保存成功
    SnackBarManager.instance.showSnackBar("保存成功", "");

    // 返回相机页面
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> uploadPhoto(String imagePath) async {
    // 这里应该写上传服务器的逻辑，例如 HTTP 请求
    print("上传图片: $imagePath");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("照片预览")),
      body: Column(
        children: [
          Expanded(
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () async => saveAndUpload(context),
                icon: const Icon(Icons.upload),
                label: const Text("保存并上传"),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel),
                label: const Text("取消"),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}