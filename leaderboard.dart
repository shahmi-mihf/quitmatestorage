import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({super.key});

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<LeaderboardUser> _users = [];
  bool _isLoading = true;
  String? _currentUserId;
  int _currentUserRank = 0;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      List<LeaderboardUser> users = [];

      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        String name = data['name'] ?? 'Anonymous';
        String avatar = data['avatar'] ?? 'avatar1.png';
        String uid = doc.id;

        // Calculate smoke-free days
        int smokeFreesDays = 0;
        if (data['createdAt'] != null) {
          Timestamp createdAt = data['createdAt'];
          DateTime quitDate = createdAt.toDate();
          DateTime now = DateTime.now();
          
          // Get current streak from smoking history
          int currentStreak = await _calculateCurrentStreak(uid, quitDate);
          smokeFreesDays = currentStreak;
        }

        users.add(LeaderboardUser(
          uid: uid,
          name: name,
          avatar: avatar,
          smokeFreesDays: smokeFreesDays,
        ));
      }

      // Sort by smoke-free days (highest first)
      users.sort((a, b) => b.smokeFreesDays.compareTo(a.smokeFreesDays));

      // Assign ranks
      for (int i = 0; i < users.length; i++) {
        users[i].rank = i + 1;
        if (users[i].uid == _currentUserId) {
          _currentUserRank = i + 1;
        }
      }

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading leaderboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<int> _calculateCurrentStreak(String uid, DateTime quitDate) async {
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

      // Calculate current streak
      int currentStreak = 0;
      DateTime today = DateTime.now();
      DateTime currentDate = DateTime(today.year, today.month, today.day);
      DateTime normalizedQuitDate = DateTime(quitDate.year, quitDate.month, quitDate.day);

      while (currentDate.isAfter(normalizedQuitDate) || currentDate.isAtSameMomentAs(normalizedQuitDate)) {
        String status = history[currentDate] ?? 'smoke-free';
        
        if (status == 'smoke-free') {
          currentStreak++;
        } else {
          break; // Stop at first relapse
        }

        currentDate = currentDate.subtract(const Duration(days: 1));
      }

      return currentStreak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EDE2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF303870),
        title: const Text('Leaderboard', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadLeaderboard();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFABA5C),
              ),
            )
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 80,
                        color: const Color(0xFF303870).withOpacity(0.3),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No users yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: const Color(0xFF303870).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFABA5C),
                  onRefresh: _loadLeaderboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Your Rank Card
                          if (_currentUserRank > 0)
                            Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFABA5C), Color(0xFFFF9800)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFABA5C).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      const SizedBox(width: 15),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Your Rank',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '#$_currentUserRank',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_users.firstWhere((u) => u.uid == _currentUserId).smokeFreesDays} days',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Top 3 Podium
                          if (_users.length >= 3)
                            _buildPodium()
                          else if (_users.isNotEmpty)
                            ..._users.take(3).map((user) => _buildUserCard(user)),

                          const SizedBox(height: 30),

                          // Rest of the users
                          if (_users.length > 3) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: const Color(0xFF303870).withOpacity(0.3),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  child: Text(
                                    'Other Participants',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF303870).withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: const Color(0xFF303870).withOpacity(0.3),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ..._users.skip(3).map((user) => _buildUserCard(user)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildPodium() {
    LeaderboardUser first = _users[0];
    LeaderboardUser second = _users.length > 1 ? _users[1] : first;
    LeaderboardUser third = _users.length > 2 ? _users[2] : first;

    return Container(
      height: 350,
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // Podium bases
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Second place
                Expanded(
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[300]!],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '2',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${second.smokeFreesDays} days',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // First place
                Expanded(
                  child: Container(
                    height: 180,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 35,
                        ),
                        const Text(
                          '1',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${first.smokeFreesDays} days',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Third place
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.brown[400]!, Colors.brown[300]!],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '3',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${third.smokeFreesDays} days',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // User avatars on top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Second place avatar
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      _buildPodiumAvatar(second, 70),
                      const SizedBox(height: 8),
                      Text(
                        second.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF303870),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // First place avatar
                Expanded(
                  child: Column(
                    children: [
                      _buildPodiumAvatar(first, 90),
                      const SizedBox(height: 8),
                      Text(
                        first.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF303870),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Third place avatar
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      _buildPodiumAvatar(third, 70),
                      const SizedBox(height: 8),
                      Text(
                        third.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF303870),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumAvatar(LeaderboardUser user, double size) {
    Color borderColor;
    if (user.rank == 1) {
      borderColor = const Color(0xFFFFD700); // Gold
    } else if (user.rank == 2) {
      borderColor = Colors.grey[400]!; // Silver
    } else {
      borderColor = Colors.brown[400]!; // Bronze
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'img/${user.avatar}',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.white,
              child: Icon(
                Icons.person,
                size: size * 0.6,
                color: const Color(0xFF303870),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserCard(LeaderboardUser user) {
    bool isCurrentUser = user.uid == _currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFFABA5C).withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isCurrentUser
            ? Border.all(color: const Color(0xFFFABA5C), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: user.rank <= 3
                  ? _getRankColor(user.rank).withOpacity(0.2)
                  : const Color(0xFF303870).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${user.rank}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: user.rank <= 3
                      ? _getRankColor(user.rank)
                      : const Color(0xFF303870),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrentUser ? const Color(0xFFFABA5C) : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'img/${user.avatar}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white,
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Color(0xFF303870),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                    color: const Color(0xFF303870),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCurrentUser)
                  const Text(
                    'You',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFABA5C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          // Days
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.smokeFreesDays}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFABA5C),
                ),
              ),
              Text(
                user.smokeFreesDays == 1 ? 'day' : 'days',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF303870).withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return Colors.grey[600]!; // Silver
      case 3:
        return Colors.brown[400]!; // Bronze
      default:
        return const Color(0xFF303870);
    }
  }
}

class LeaderboardUser {
  final String uid;
  final String name;
  final String avatar;
  final int smokeFreesDays;
  int rank;

  LeaderboardUser({
    required this.uid,
    required this.name,
    required this.avatar,
    required this.smokeFreesDays,
    this.rank = 0,
  });
}