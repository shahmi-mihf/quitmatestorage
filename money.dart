import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Money extends StatefulWidget {
  const Money({super.key});

  @override
  State<Money> createState() => _MoneyState();
}

class _MoneyState extends State<Money> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final TextEditingController _cigarettesController = TextEditingController();
  final TextEditingController _costController = TextEditingController(text: '15.45');
  final TextEditingController _daysController = TextEditingController();
  
  double _totalSaved = 0.0;
  bool _hasCalculated = false;
  int _currentCigaretteCount = 0;

  @override
  void initState() {
    super.initState();
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
          
          // Calculate days smoke-free from registration date
          if (userData?['createdAt'] != null) {
            Timestamp createdAt = userData!['createdAt'];
            DateTime createdDate = createdAt.toDate();
            DateTime now = DateTime.now();
            int daysSmokeRee = now.difference(createdDate).inDays;
            
            setState(() {
              _daysController.text = daysSmokeRee.toString();
            });
          }
          
          // Load cigarette count from database
          int cigaretteCount = userData?['cigaretteCount'] ?? 0;
          setState(() {
            _currentCigaretteCount = cigaretteCount;
          });
          
          // Load cigarettes per day if available (this is what they USED TO smoke)
          String? cigarettesPerDay = userData?['cigarettesPerDay'];
          if (cigarettesPerDay != null) {
            // Extract number from string like "1-10", "11-20", "20+"
            if (cigarettesPerDay == '1-10') {
              _cigarettesController.text = '5';
            } else if (cigarettesPerDay == '11-20') {
              _cigarettesController.text = '15';
            } else if (cigarettesPerDay == '20+') {
              _cigarettesController.text = '25';
            }
          }
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _calculateAndSaveSavings() async {
    if (_cigarettesController.text.isEmpty || 
        _costController.text.isEmpty || 
        _daysController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // This is how many cigarettes they USED TO smoke per day (before quitting)
      int cigarettesUsedToSmokePerDay = int.parse(_cigarettesController.text);
      double costPerPack = double.parse(_costController.text);
      int daysSmokeRee = int.parse(_daysController.text);
      
      // Calculate total cigarettes AVOIDED (not smoked because they quit)
      int totalCigarettesAvoided = cigarettesUsedToSmokePerDay * daysSmokeRee;
      
      // Calculate money saved (packs they would have bought if still smoking)
      double packsAvoided = totalCigarettesAvoided / 20.0; // 20 cigarettes per pack
      double totalSaved = packsAvoided * costPerPack;
      
      setState(() {
        _totalSaved = totalSaved;
        _hasCalculated = true;
      });

      // Update cigarette count in database (total cigarettes AVOIDED/NOT SMOKED)
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'cigaretteCount': totalCigarettesAvoided,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Savings calculated and saved successfully!'),
              backgroundColor: Color(0xFFFABA5C),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _cigarettesController.dispose();
    _costController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EDE2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF303870),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Money Saved Calculator',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Total Amount Saved Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFABA5C), Color(0xFFFF9800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFABA5C).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.attach_money,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _hasCalculated 
                          ? '\$${_totalSaved.toStringAsFixed(2)}'
                          : '\$0.00',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Total Amount Saved',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Input Fields Container
              Container(
                padding: const EdgeInsets.all(25),
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
                child: Column(
                  children: [
                    // Cigarettes USED TO smoke per day (before quitting)
                    _buildInputRow(
                      icon: Icons.smoking_rooms,
                      label: 'Cigarettes used to smoke per day',
                      controller: _cigarettesController,
                      keyboardType: TextInputType.number,
                      suffix: '20/pack',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Cost per pack (read-only, auto-filled)
                    _buildInputRow(
                      icon: Icons.monetization_on,
                      label: 'Cost per pack',
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefix: '\$',
                      readOnly: true,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Days smoke-free (read-only, from database)
                    _buildInputRow(
                      icon: Icons.calendar_today,
                      label: 'Days smoke-free',
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      readOnly: true,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Calculate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _calculateAndSaveSavings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFABA5C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFFFABA5C).withOpacity(0.5),
                  ),
                  child: const Text(
                    'Calculate Savings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Info text
              if (_hasCalculated)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF303870).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF303870),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Amazing! You\'ve saved \$${_totalSaved.toStringAsFixed(2)} by not smoking for ${_daysController.text} days!',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF303870),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 15),
              
              // Cigarette count display
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF303870).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.block,
                            color: Color(0xFF303870),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Text(
                          'Cigarettes Avoided',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF303870),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _hasCalculated 
                          ? '${(int.parse(_cigarettesController.text) * int.parse(_daysController.text))}'
                          : '$_currentCigaretteCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFABA5C),
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

  Widget _buildInputRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    String? prefix,
    String? suffix,
    bool readOnly = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: readOnly 
                ? const Color(0xFF303870).withOpacity(0.1)
                : const Color(0xFFFABA5C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: readOnly 
                ? const Color(0xFF303870)
                : const Color(0xFFFABA5C),
            size: 24,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF303870).withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  if (prefix != null) ...[
                    Text(
                      prefix,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF303870),
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      readOnly: readOnly,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: readOnly 
                            ? const Color(0xFF303870).withOpacity(0.6)
                            : const Color(0xFF303870),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                        ),
                        suffixText: suffix,
                        suffixStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF303870).withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}