import 'package:expanse_mate/firebase_options.dart';
import 'package:expanse_mate/pages/login_page.dart';
import 'package:expanse_mate/pages/profile_setting_page.dart';
import 'package:expanse_mate/pages/reports_statistics_page.dart';
import 'package:expanse_mate/pages/signup_page.dart';
import 'package:expanse_mate/pages/categories_page.dart';
import 'package:expanse_mate/pages/add_transaction.dart';
import 'package:expanse_mate/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ExpenseMateApp());
}

class ExpenseMateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ExpenseMate',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/sign-up': (context) => SignupPage(),
        '/home': (context) => AppLayout(child: HomePage(), selectedIndex: 0),
        '/add-transaction': (context) => AppLayout(child: AddTransactionPage(), selectedIndex: 0),
        '/categories': (context) => AppLayout(child: CategoriesPage(), selectedIndex: 1),
        '/reports-statistics': (context) => AppLayout(child: ReportsStatisticsPage(), selectedIndex: 2),
        '/profile-setting': (context) => AppLayout(child: ProfileSettingsPage(), selectedIndex: 3),
      },
    );
  }
}

// AppLayout widget wraps other pages and provides the shared BottomNavigationBar
class AppLayout extends StatefulWidget {
  final Widget child;
  final int selectedIndex;

  AppLayout({required this.child, required this.selectedIndex});

  @override
  _AppLayoutState createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  late int _selectedIndex;

  final List<String> routes = [
    '/home',
    '/categories',
    '/reports-statistics',
    '/profile-setting',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;  // Initialize with the passed index
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      FirebaseAuth.instance.signOut().then((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey, // Grey for non-selected items
        onTap: _onItemTapped,
      ),
    );
  }
}
