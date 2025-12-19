import 'package:esheba_fixian/screens/user/service_explorer_screen.dart';
import 'package:flutter/material.dart';

import 'user_home_screen.dart';


class UserMainShell extends StatefulWidget {
  const UserMainShell({super.key});

  @override
  State<UserMainShell> createState() => _UserMainShellState();
}

class _UserMainShellState extends State<UserMainShell> {
  int _index = 0;

  final pages = const [
    UserHomeScreen(),
    UserOrdersScreen(),
    ServiceExplorerScreen(),
    UserChatsScreen(),
    UserDiscoveryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: IndexedStack(
          key: ValueKey(_index),
          index: _index,
          children: pages,
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        height: 68,
        onDestinationSelected: (i) {
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: "Orders",
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: "Search",
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: "Chats",
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: "Discover",
          ),
        ],
      ),
    );
  }
}



class UserOrdersScreen extends StatelessWidget {
  const UserOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Orders"));
  }
}

class UserSearchScreen extends StatelessWidget {
  const UserSearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Search"));
  }
}

class UserChatsScreen extends StatelessWidget {
  const UserChatsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Chats"));
  }
}

class UserDiscoveryScreen extends StatelessWidget {
  const UserDiscoveryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Discover"));
  }
}
