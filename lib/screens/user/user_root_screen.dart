import 'package:flutter/material.dart';

import 'user_home_screen.dart';
// import 'user_orders_screen.dart';
import 'service_explorer_screen.dart';
// import 'user_chat_screen.dart';
// import 'user_discovery_screen.dart';

class UserRootScreen extends StatefulWidget {
  const UserRootScreen({super.key});

  @override
  State<UserRootScreen> createState() => _UserRootScreenState();
}

class _UserRootScreenState extends State<UserRootScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  late final PageController _pageController;

  final pages = const [
    UserHomeScreen(),
    UserOrdersScreen(),
    ServiceExplorerScreen(),
    UserChatScreen(),
    UserDiscoveryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _onTap(int i) {
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Discover"),
        ],
      ),
    );
  }
}

class UserDiscoveryScreen extends StatelessWidget {
  const UserDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

class UserChatScreen extends StatelessWidget {
  const UserChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

class UserOrdersScreen extends StatelessWidget {
  const UserOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
