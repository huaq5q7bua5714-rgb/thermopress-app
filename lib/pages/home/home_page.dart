import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'home_contolller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 底部图标按钮区域
  late List<BottomNavigationBarItem> _navigationViews;

  @override
  Widget build(BuildContext context) {
    _navigationViews = makeTabItems();

    return GetBuilder<HomeController>(builder: (controller) {
      return Scaffold(
        body: controller.pageList[controller.currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          currentIndex: controller.currentIndex,
          onTap: (int index) {
            controller.changeIndex(index);
            },
          items: _navigationViews,
        ),
      );
    });
  }

  ///创建底部tab按钮
  List<BottomNavigationBarItem> makeTabItems() {
    return [
            const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: '患者管理',
      ),  
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: '实时测量',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: '蓝牙连接',
      ),
    ];
  }
}
