import 'package:get/get.dart';
import 'home_contolller.dart';
import 'auth_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Home 主控制器，常驻
    Get.put<HomeController>(HomeController(), permanent: true);

    // 医生账号控制器，常驻
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
