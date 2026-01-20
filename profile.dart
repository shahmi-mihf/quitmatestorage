import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _smokeDays = 0;

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
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
            _calculateSmokeDays();
            _isLoading = false;
          });
          
          // Check if profile is incomplete and show dialog
          if (_isProfileIncomplete()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showProfileSetupDialog();
            });
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _isProfileIncomplete() {
    return _userData?['cigarettesPerDay'] == null ||
           _userData?['timeOfSmoking'] == null ||
           _userData?['mainReasonForSmoking'] == null ||
           _userData?['motivationToStop'] == null;
  }

  void _calculateSmokeDays() {
    if (_userData != null && _userData!['createdAt'] != null) {
      Timestamp createdAt = _userData!['createdAt'];
      DateTime createdDate = createdAt.toDate();
      DateTime now = DateTime.now();
      setState(() {
        _smokeDays = now.difference(createdDate).inDays;
      });
    }
  }

  void _showProfileSetupDialog() {
    String? selectedCigarettesPerDay = _userData?['cigarettesPerDay'];
    String? selectedTimeOfSmoking = _userData?['timeOfSmoking'];
    String? selectedMainReason = _userData?['mainReasonForSmoking'];
    String? selectedMotivation = _userData?['motivationToStop'];
    String? selectedAvatar = _userData?['avatar'] ?? 'avatar1.png';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Complete Your Profile',
                style: TextStyle(color: Color(0xFF303870)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar Selection
                    const Text(
                      'Choose Your Avatar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF303870),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFABA5C), width: 3),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'img/$selectedAvatar',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 50);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedAvatar,
                      decoration: InputDecoration(
                        labelText: 'Select Avatar',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: List.generate(6, (index) {
                        String avatarName = 'avatar${index + 1}.png';
                        return DropdownMenuItem(
                          value: avatarName,
                          child: Text('Avatar ${index + 1}'),
                        );
                      }),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAvatar = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Cigarettes Per Day
                    DropdownButtonFormField<String>(
                      value: selectedCigarettesPerDay,
                      decoration: InputDecoration(
                        labelText: 'Cigarettes Per Day',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: '1-10', child: Text('1-10 cigarettes')),
                        DropdownMenuItem(value: '11-20', child: Text('11-20 cigarettes')),
                        DropdownMenuItem(value: '20+', child: Text('More than 20')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCigarettesPerDay = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    
                    // Time of Smoking
                    DropdownButtonFormField<String>(
                      value: selectedTimeOfSmoking,
                      decoration: InputDecoration(
                        labelText: 'When Do You Usually Smoke?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                        DropdownMenuItem(value: 'Afternoon', child: Text('Afternoon')),
                        DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedTimeOfSmoking = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    
                    // Main Reason for Smoking
                    DropdownButtonFormField<String>(
                      value: selectedMainReason,
                      decoration: InputDecoration(
                        labelText: 'Main Reason for Smoking',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Stress Relief', child: Text('Stress Relief')),
                        DropdownMenuItem(value: 'Social Habit', child: Text('Social Habit')),
                        DropdownMenuItem(value: 'Addiction', child: Text('Addiction')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMainReason = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    
                    // Motivation to Stop
                    DropdownButtonFormField<String>(
                      value: selectedMotivation,
                      decoration: InputDecoration(
                        labelText: 'Motivation to Stop',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Health', child: Text('Health')),
                        DropdownMenuItem(value: 'Family', child: Text('Family')),
                        DropdownMenuItem(value: 'Financial', child: Text('Financial')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMotivation = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (selectedCigarettesPerDay != null &&
                        selectedTimeOfSmoking != null &&
                        selectedMainReason != null &&
                        selectedMotivation != null) {
                      try {
                        await _firestore
                            .collection('users')
                            .doc(_currentUser!.uid)
                            .update({
                          'cigarettesPerDay': selectedCigarettesPerDay,
                          'timeOfSmoking': selectedTimeOfSmoking,
                          'mainReasonForSmoking': selectedMainReason,
                          'motivationToStop': selectedMotivation,
                          'avatar': selectedAvatar,
                        });
                        
                        Navigator.of(context).pop();
                        _loadUserData();
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully!'),
                              backgroundColor: Color(0xFFFABA5C),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFFFABA5C),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4EDE2),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFABA5C),
          ),
        ),
      );
    }

    String userName = _userData?['name'] ?? 'User';
    String userAvatar = _userData?['avatar'] ?? 'avatar1.png';
    String memberSince = _userData?['createdAt'] != null
        ? 'Member since ${(_userData!['createdAt'] as Timestamp).toDate().toString().split(' ')[0]}'
        : 'Member since 2026';

    return Scaffold(
      backgroundColor: const Color(0xFFF4EDE2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF303870),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Header
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFABA5C), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'img/$userAvatar',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white,
                        child: const Icon(Icons.person, size: 60, color: Color(0xFF303870)),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF303870),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFABA5C).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFFFABA5C), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '$_smokeDays Smoke-Free Days',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF303870),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                memberSince,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF303870).withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 40),
              
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    // Edit Profile Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showProfileSetupDialog,
                        icon: const Icon(Icons.edit, size: 20),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF303870),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Manage Quit Plan Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today, size: 20),
                        label: const Text(
                          'Manage Quit Plan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF303870),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Log Out Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFABA5C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}