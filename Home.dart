import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quitemate/login.dart';
import 'package:quitemate/profile.dart';
import 'package:quitemate/register.dart';
import 'package:quitemate/location.dart';
import 'package:quitemate/money.dart';
import 'package:quitemate/calendar.dart';
import 'package:quitemate/leaderboard.dart';
import 'package:quitemate/chatbot.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _currentUser;
  String? _userAvatar;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            _userAvatar = userData?['avatar'] ?? 'avatar1.png';
            _userName = userData?['name'] ?? 'User';
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  void _navigateToPage(Widget page) {
    if (_currentUser == null) {
      // Show login prompt if user is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to access this feature'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EDE2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF303870),
        title: Image.asset('img/logo.png', height: 40),
        actions: [
          // Avatar Button
          if (_currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Profile()),
                  ).then((_) => _loadUserData()); // Reload data when returning
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFABA5C), width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'img/$_userAvatar',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white,
                          child: const Icon(
                            Icons.person,
                            size: 24,
                            color: Color(0xFF303870),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 10),
          // Show Login/Register only if not logged in
          if (_currentUser == null) ...[
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                ).then((_) => _loadUserData()); // Reload data after login
              },
              child: const Text('Log In', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Register()),
                ).then((_) => _loadUserData()); // Reload data after registration
              },
              child: const Text('Register', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'WELCOME TO QUITMATE',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF303870),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 42,
                    color: Color(0xFF303870),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                if (_currentUser != null && _userName != null)
                  Text(
                    _userName!,
                    style: TextStyle(
                      fontSize: 42,
                      color: const Color(0xFF303870).withOpacity(0.7),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'About Us',
                        style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFF303870),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        'QuitMate is your companion on the journey to freedom from smoking and vaping. We understand how challenging it can be to quit, and we\'re here to support you every step of the way.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF303870),
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // ChatBot Button with Tooltip
                Tooltip(
                  message: 'ChatBot',
                  decoration: BoxDecoration(
                    color: const Color(0xFF303870),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  preferBelow: true,
                  verticalOffset: 20,
                  child: InkWell(
                    onTap: () => _navigateToPage(const ChatBot()),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFABA5C),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFABA5C).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child:    IconButton(
                            icon: const Icon(
                            Icons.chat_bubble,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => _navigateToPage(const ChatBot()),
                          tooltip: 'ChatBot',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF303870),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Money/Savings
              IconButton(
                icon: const Icon(
                  Icons.attach_money,
                  color: Color(0xFFFABA5C),
                  size: 28,
                ),
                onPressed: () => _navigateToPage(const Money()),
                tooltip: 'Savings',
              ),
              // Calendar
              IconButton(
                icon: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFFFABA5C),
                  size: 28,
                ),
                onPressed: () => _navigateToPage(const Calendar()),
                tooltip: 'Calendar',
              ),
              // Leaderboard
              IconButton(
                icon: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFABA5C),
                  size: 28,
                ),
                onPressed: () => _navigateToPage(const Leaderboard()),
                tooltip: 'Leaderboard',
              ),
              // Location
              IconButton(
                icon: const Icon(
                  Icons.location_on,
                  color: Color(0xFFFABA5C),
                  size: 28,
                ),
                onPressed: () => _navigateToPage(const Location()),
                tooltip: 'Find Bins',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
