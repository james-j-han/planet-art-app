import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:planet_art_app/pages/account/account_page.dart';
import 'package:planet_art_app/pages/event/event_page.dart';
import 'package:planet_art_app/pages/explore/explore_page.dart';
import 'package:planet_art_app/pages/message/message_page.dart';

import '../auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = Auth().currentUser;

  int _selectedIndex = 0;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _userUid() {
    return Text(user?.email ?? 'User email');
  }

  Widget _mainNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded), label: 'Explore'),
        BottomNavigationBarItem(
            icon: Icon(Icons.event_rounded), label: 'Events'),
        BottomNavigationBarItem(
            icon: Icon(Icons.message_rounded), label: 'Messages'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded), label: 'Account'),
      ],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    Center(
      child: const ExplorePage(),
    ),
    Center(
      child: EventPage(),
    ),
    Center(
      child: MessagePage(),
    ),
    Center(
      child: AccountPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _mainNavigationBar(),
    );
  }
}
