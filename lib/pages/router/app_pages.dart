import 'package:poct_app/pages/home/home_binding.dart';
import 'package:poct_app/pages/home/home_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

import 'app_routes.dart';

abstract class AppPages {
  static final pages = [
    GetPage(
        name: Routes.HOME,
        page: () => const HomePage(),
        binding: HomeBinding()
    )
  ];
}