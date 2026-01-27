import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  DateTime? _quitDate;
  int _currentStreak = 0;
  int _longestStreak = 0;
  Map<DateTime, String> _smokingHistory = {}; // 'smoke-free' or 'relapse'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

          if (userData?['createdAt'] != null) {
            Timestamp createdAt = userData!['createdAt'];
            DateTime quitDate = createdAt.toDate();

            setState(() {
              _quitDate = quitDate;
            });

            // Load smoking history from Firestore
            await _loadSmokingHistory(currentUser.uid);
            _calculateStreaks();
          }
        }
      } catch (e) {
        print('Error loading user data: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSmokingHistory(String uid) async {
    try {
      QuerySnapshot historySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('smokingHistory')
          .get();

      Map<DateTime, String> history = {};
      
      for (var doc in historySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['date'] != null) {
          Timestamp timestamp = data['date'];
          DateTime date = DateTime(
            timestamp.toDate().year,
            timestamp.toDate().month,
            timestamp.toDate().day,
          );
          history[date] = data['status'] ?? 'smoke-free';
        }
      }

      setState(() {
        _smokingHistory = history;
      });
    } catch (e) {
      print('Error loading smoking history: $e');
    }
  }

  void _calculateStreaks() {
    if (_quitDate == null) return;

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    DateTime today = DateTime.now();
    DateTime currentDate = DateTime(_quitDate!.year, _quitDate!.month, _quitDate!.day);
    DateTime todayNormalized = DateTime(today.year, today.month, today.day);

    while (currentDate.isBefore(todayNormalized) || currentDate.isAtSameMomentAs(todayNormalized)) {
      String status = _smokingHistory[currentDate] ?? 'smoke-free';

      if (status == 'smoke-free') {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Calculate current streak (from most recent relapse or quit date)
    currentDate = todayNormalized;
    while (currentDate.isAfter(_quitDate!) || currentDate.isAtSameMomentAs(DateTime(_quitDate!.year, _quitDate!.month, _quitDate!.day))) {
      String status = _smokingHistory[currentDate] ?? 'smoke-free';
      
      if (status == 'smoke-free') {
        currentStreak++;
      } else {
        currentStreak = 0;
      }

      currentDate = currentDate.subtract(const Duration(days: 1));
      
      if (currentStreak == 0 && currentDate.isBefore(DateTime(_quitDate!.year, _quitDate!.month, _quitDate!.day))) {
        break;
      }
    }

    setState(() {
      _currentStreak = currentStreak;
      _longestStreak = longestStreak;
    });
  }

  Future<void> _markDayAsRelapse(DateTime day) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    DateTime normalizedDay = DateTime(day.year, day.month, day.day);

    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Mark as Relapse',
            style: TextStyle(color: Color(0xFF303870)),
          ),
          content: const Text(
            'Are you sure you want to mark this day as a relapse? This will reset your current streak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF303870)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('smokingHistory')
          .doc('${normalizedDay.year}-${normalizedDay.month}-${normalizedDay.day}')
          .set({
        'date': Timestamp.fromDate(normalizedDay),
        'status': 'relapse',
        'timestamp': Timestamp.now(),
      });

      setState(() {
        _smokingHistory[normalizedDay] = 'relapse';
      });

      _calculateStreaks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Day marked as relapse. Don\'t give up - you can start again!'),
            backgroundColor: Colors.orange,
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
  }

  Future<void> _markDayAsSmokeFree(DateTime day) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    DateTime normalizedDay = DateTime(day.year, day.month, day.day);

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('smokingHistory')
          .doc('${normalizedDay.year}-${normalizedDay.month}-${normalizedDay.day}')
          .set({
        'date': Timestamp.fromDate(normalizedDay),
        'status': 'smoke-free',
        'timestamp': Timestamp.now(),
      });

      setState(() {
        _smokingHistory[normalizedDay] = 'smoke-free';
      });

      _calculateStreaks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Great! Day marked as smoke-free!'),
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
  }

  void _showDayOptions(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    String currentStatus = _smokingHistory[normalizedDay] ?? 'smoke-free';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${day.day}/${day.month}/${day.year}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF303870),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Current status: ${currentStatus == 'relapse' ? 'Relapse' : 'Smoke-Free'}',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF303870).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              if (currentStatus != 'relapse')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _markDayAsRelapse(day);
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Mark as Relapse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              if (currentStatus == 'relapse') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _markDayAsSmokeFree(day);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Smoke-Free'),
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
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EDE2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF303870),
        title: const Text('Calendar', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFABA5C),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Streak Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStreakCard(
                            'Current Streak',
                            _currentStreak,
                            Icons.local_fire_department,
                            const Color(0xFFFABA5C),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildStreakCard(
                            'Longest Streak',
                            _longestStreak,
                            Icons.emoji_events,
                            const Color(0xFF303870),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Calendar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TableCalendar(
                        firstDay: _quitDate ?? DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!selectedDay.isAfter(DateTime.now())) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            _showDayOptions(selectedDay);
                          }
                        },
                        onFormatChanged: (format) {
                          if (_calendarFormat != format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: const Color.fromARGB(255, 57, 63, 177).withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Color(0xFF303870),
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          outsideDaysVisible: false,
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          formatButtonShowsNext: false,
                          formatButtonDecoration: BoxDecoration(
                            color: const Color(0xFFFABA5C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          formatButtonTextStyle: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            DateTime normalizedDay = DateTime(day.year, day.month, day.day);
                            String status = _smokingHistory[normalizedDay] ?? 'smoke-free';

                            if (status == 'relapse') {
                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            } else if (_quitDate != null && 
                                       normalizedDay.isAfter(_quitDate!) || 
                                       normalizedDay.isAtSameMomentAs(DateTime(_quitDate!.year, _quitDate!.month, _quitDate!.day))) {
                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFABA5C).withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(color: Color(0xFF303870)),
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Legend
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Legend',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF303870),
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildLegendItem(
                            Colors.white,
                            'Before quit date',
                            hasBorder: true,
                          ),
                          const SizedBox(height: 10),
                          _buildLegendItem(
                            const Color(0xFFFABA5C).withOpacity(0.3),
                            'Smoke-free day',
                          ),
                          const SizedBox(height: 10),
                          _buildLegendItem(
                            Colors.red,
                            'Relapse day',
                          ),
                          const SizedBox(height: 10),
                          _buildLegendItem(
                            const Color.fromARGB(255, 57, 63, 177).withOpacity(0.5),
                            'Today',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Motivational Message
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFABA5C), Color(0xFFFF9800)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              _currentStreak > 0
                                  ? 'Amazing! You\'ve been smoke-free for $_currentStreak days. Keep it up!'
                                  : 'Don\'t give up! Every day is a new opportunity to stay smoke-free.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStreakCard(String title, int days, IconData icon, Color color) {
    return Container(
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
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            '$days',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF303870).withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            days == 1 ? 'day' : 'days',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF303870).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: hasBorder
                ? Border.all(color: const Color(0xFF303870).withOpacity(0.3), width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF303870),
          ),
        ),
      ],
    );
  }
}