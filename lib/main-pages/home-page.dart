import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ims/main-pages/profil_page.dart';
import 'package:ims/main-pages/avil_internship.dart';
import 'package:ims/main-pages/avail_jobs.dart';
import 'package:ims/components/top_app_bar.dart';
import 'package:ims/pages/auth_page.dart';
import 'package:ims/main-pages/intern_dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isTextVisible = false;
  bool _isInternshipAccepted = false; // For internship status check

  late AnimationController _animationController;
  late Animation<double> _animation;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    // Fetch internship status on startup
    _fetchInternshipStatus();

    // Initialize the animation controller and animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start the animation and set text visibility to true after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
      setState(() {
        _isTextVisible = true;
      });
    });
  }

  // Fetch the internship status from Firestore
  Future<void> _fetchInternshipStatus() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('internship_applications')
          .doc(user!.uid) // Assuming each user has a document with their UID
          .get();

      if (doc.exists) {
        setState(() {
          _isInternshipAccepted = doc.data()?['status'] == 'accepted';
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                opacity: _isTextVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: const Text(
                  'Welcome to Nicozn Technologies',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Check if internship is accepted, otherwise redirect to internship page
                  if (_isInternshipAccepted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InternDashboard()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AvilInternshipPage()),
                    );
                  }
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Get Started'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
              ),
            ],
          ),
        ),
      ),
      const AvailJobsPage(), // Jobs Page
      const AvilInternshipPage(), // Internships Page
      const ProfilePage(), // Profile Page
    ];

    return Scaffold(
      appBar: TopAppBar(
        title: 'IMS',
        isLoggedIn: true,
        onLogout: _logout,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Drawer Header',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.business_center),
              title: const Text('Jobs'),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Internships'),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      floatingActionButton: _isInternshipAccepted
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InternDashboard()),
                );
              },
              backgroundColor: Colors.blue, // Color matching your app theme
              child: const Icon(Icons.dashboard, color: Colors.white), // Icon for the FAB
              elevation: 8, // Added elevation for a more modern look
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // Rounded edges for a modern look
              ),
            )
          : null, // Hide FAB if internship is not accepted
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Internships',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
