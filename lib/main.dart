import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:poct_app/pages/home/home_binding.dart';
import 'package:poct_app/pages/router/app_pages.dart';
import 'package:poct_app/pages/router/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化本地存储（GetStorage）
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ThermoPress_SEU_Gulab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      getPages: AppPages.pages,
      // 这里注册全局的 HomeController / AuthController
      initialBinding: HomeBinding(),
      // 启动先进入登录页
      home: const LoginPage(),
    );
  }
}
