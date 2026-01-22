import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _showOptions = true;
  String _userName = 'there';
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Predefined conversation flows
  Map<String, ConversationNode> get _conversationTree => {
    'craving': ConversationNode(
      botResponse: "I understand you're having a craving right now. That's completely normal. Here are some things you can do to cope:",
      suggestions: [
        Suggestion(
          icon: Icons.air,
          title: 'Focus on Your Breathing',
          description: 'Take slow, deep breaths for a few minutes to help calm your mind and body.',
          nextKey: 'breathing',
        ),
        Suggestion(
          icon: Icons.directions_walk,
          title: 'Distract Yourself',
          description: 'Go for a brisk walk, drink a glass of water, or engage in something interesting.',
          nextKey: 'distract',
        ),
        Suggestion(
          icon: Icons.psychology,
          title: 'Positive Affirmation',
          description: 'Tell yourself, "I am in control. I am getting stronger every day."',
          nextKey: 'affirmation',
        ),
      ],
    ),
    'breathing': ConversationNode(
      botResponse: "Great choice! Let's do a quick breathing exercise together.\n\n1. Breathe in slowly through your nose for 4 counts\n2. Hold for 4 counts\n3. Breathe out through your mouth for 4 counts\n\nRepeat this 3-5 times. How do you feel now?",
      options: [
        'I feel calmer now',
        'I still need more help',
        'This really helped!',
      ],
      responses: {
        'I feel calmer now': "That's wonderful! You're doing great, $_userName. Every craving you resist makes you stronger. Remember, cravings typically pass within 10-15 minutes.",
        'I still need more help': "That's okay. Recovery is a journey. Let me suggest some additional strategies.",
        'This really helped!': "I'm so glad! You're building healthy coping mechanisms. Keep up the great work!",
      },
      nextKey: 'encouragement',
    ),
    'distract': ConversationNode(
      botResponse: "Distraction is a powerful tool! Here are some quick activities that can help take your mind off the craving:",
      suggestions: [
        Suggestion(
          icon: Icons.water_drop,
          title: 'Drink Cold Water',
          description: 'The sensation can help reset your urge.',
          nextKey: 'water',
        ),
        Suggestion(
          icon: Icons.phone_android,
          title: 'Call a Friend',
          description: 'Talk to someone supportive about how you\'re feeling.',
          nextKey: 'support',
        ),
        Suggestion(
          icon: Icons.sports_esports,
          title: 'Play a Quick Game',
          description: 'Engage your mind with a puzzle or mobile game.',
          nextKey: 'game',
        ),
      ],
    ),
    'affirmation': ConversationNode(
      botResponse: "Positive self-talk is incredibly powerful! Repeat after me:\n\n\"I am in control.\nI am getting stronger every day.\nI choose health over temporary pleasure.\nI am proud of my progress.\"\n\nHow does that make you feel?",
      options: [
        'More confident!',
        'I need more motivation',
        'Ready to keep going',
      ],
      responses: {
        'More confident!': "That's the spirit! Confidence is key to your success. You've got this!",
        'I need more motivation': "Let me remind you why you started this journey. What was your main motivation to quit?",
        'Ready to keep going': "Excellent! That positive mindset will carry you through. I believe in you!",
      },
      nextKey: 'encouragement',
    ),
    'water': ConversationNode(
      botResponse: "Perfect! Drinking cold water can:\n• Occupy your hands and mouth\n• Provide a refreshing sensation\n• Help flush toxins from your system\n• Keep you hydrated\n\nMany people find the physical act of drinking helps replace the hand-to-mouth habit.",
      options: [
        'That makes sense',
        'What else can I do?',
        'Thanks, I feel better',
      ],
      responses: {
        'That makes sense': "Glad I could help explain! Small changes make a big difference.",
        'What else can I do?': "There are many strategies we can explore together. Would you like more suggestions?",
        'Thanks, I feel better': "You're very welcome! I'm here whenever you need support.",
      },
      nextKey: 'encouragement',
    ),
    'support': ConversationNode(
      botResponse: "Reaching out for support is a sign of strength, not weakness. Talking to someone who understands can:\n• Provide accountability\n• Offer encouragement\n• Distract you from the craving\n• Remind you you're not alone",
      options: [
        'I\'ll call someone now',
        'I don\'t have anyone to call',
        'Good idea',
      ],
      responses: {
        'I\'ll call someone now': "That's wonderful! I'm proud of you for taking action. You've got this!",
        'I don\'t have anyone to call': "I'm here for you right now. And remember, there are support hotlines available 24/7 if you need them.",
        'Good idea': "Absolutely! Building a support network is crucial for long-term success.",
      },
      nextKey: 'encouragement',
    ),
    'game': ConversationNode(
      botResponse: "Great choice! Engaging activities can effectively redirect your thoughts. Games that require focus work best:\n• Puzzle games\n• Word games\n• Strategy games\n\nThe craving will pass while you're occupied!",
      options: [
        'I\'ll try that',
        'What if it doesn\'t work?',
        'Thanks for the tip',
      ],
      responses: {
        'I\'ll try that': "Excellent! Give it 10-15 minutes and the craving intensity should decrease significantly.",
        'What if it doesn\'t work?': "If one strategy doesn't work, try another! Everyone is different. The important thing is you're trying.",
        'Thanks for the tip': "You're welcome! Remember, I'm always here when you need me.",
      },
      nextKey: 'encouragement',
    ),
    'motivation': ConversationNode(
      botResponse: "What motivates you most about quitting?",
      options: [
        'My health',
        'My family',
        'Saving money',
        'All of the above',
      ],
      responses: {
        'My health': "Your health is invaluable! Every day smoke-free, your body heals more. Your lungs are getting stronger, your heart healthier.",
        'My family': "What a beautiful motivation! You're not just doing this for yourself, but for those who love you. They're proud of you!",
        'Saving money': "That's a smart reason! Think of all the money you're saving and what you can do with it instead.",
        'All of the above': "You have such strong reasons to succeed! Hold onto these motivations when things get tough.",
      },
      nextKey: 'encouragement',
    ),
    'encouragement': ConversationNode(
      botResponse: "You're doing great, $_userName! Every craving you resist makes you stronger and brings you closer to your goal. I'm proud of your progress! 💪",
      options: [
        'Tell me my progress',
        'I need more help',
        'Thanks, ChatBot!',
      ],
      responses: {
        'Tell me my progress': "Let me show you how far you've come! Check your statistics page to see your smoke-free days and money saved.",
        'I need more help': "I'm always here for you. What would help you most right now?",
        'Thanks, ChatBot!': "You're very welcome! Remember, I'm here 24/7 whenever you need support. You've got this! 🌟",
      },
      nextKey: null,
    ),
    'feeling': ConversationNode(
      botResponse: "How are you feeling today?",
      options: [
        'I\'m struggling',
        'Doing okay',
        'Feeling great!',
        'Having doubts',
      ],
      responses: {
        'I\'m struggling': "I hear you. Some days are harder than others, and that's completely normal. You're not alone in this.",
        'Doing okay': "That's good to hear! Even 'okay' days are victories when you're on this journey.",
        'Feeling great!': "That's fantastic! I'm so happy for you. Celebrate these positive moments!",
        'Having doubts': "Doubts are natural, but don't let them derail your progress. Remember why you started.",
      },
      nextKey: 'encouragement',
    ),
    'tips': ConversationNode(
      botResponse: "Here are some helpful tips for managing cravings:",
      suggestions: [
        Suggestion(
          icon: Icons.schedule,
          title: 'Delay Technique',
          description: 'Wait 10 minutes. Most cravings pass in that time.',
          nextKey: 'delay',
        ),
        Suggestion(
          icon: Icons.delete,
          title: 'Remove Triggers',
          description: 'Get rid of cigarettes, lighters, and ashtrays.',
          nextKey: 'triggers',
        ),
        Suggestion(
          icon: Icons.psychology_alt,
          title: 'Stay Positive',
          description: 'Focus on the benefits, not what you\'re giving up.',
          nextKey: 'positive',
        ),
      ],
    ),
    'delay': ConversationNode(
      botResponse: "The delay technique is simple but powerful:\n\n1. When a craving hits, look at the clock\n2. Tell yourself you'll wait 10 minutes\n3. Distract yourself during that time\n4. After 10 minutes, reassess how you feel\n\nMost cravings peak and pass within this window!",
      options: [
        'I\'ll try this',
        'What if 10 minutes isn\'t enough?',
        'This is helpful',
      ],
      responses: {
        'I\'ll try this': "Excellent! This technique gets easier with practice. You're building a powerful skill.",
        'What if 10 minutes isn\'t enough?': "Then delay another 10 minutes! Each delay weakens the craving and strengthens your resolve.",
        'This is helpful': "I'm glad! Small strategies like this can make a huge difference.",
      },
      nextKey: 'encouragement',
    ),
    'triggers': ConversationNode(
      botResponse: "Removing triggers from your environment is crucial! Common triggers include:\n• Physical items (cigarettes, lighters)\n• Certain places or situations\n• Stress or emotions\n• Social situations\n\nIdentifying and managing your triggers is key to success.",
      options: [
        'How do I handle social triggers?',
        'Stress is my biggest trigger',
        'I\'ve removed physical triggers',
      ],
      responses: {
        'How do I handle social triggers?': "Great question! You can excuse yourself, bring a supportive friend, or practice saying 'no thanks, I quit.'",
        'Stress is my biggest trigger': "Stress management is crucial. Try deep breathing, exercise, or talking to someone when stressed.",
        'I\'ve removed physical triggers': "Excellent first step! That shows real commitment to your quit journey.",
      },
      nextKey: 'encouragement',
    ),
    'positive': ConversationNode(
      botResponse: "Maintaining a positive mindset is so important! Focus on:\n\n✅ Better health and energy\n✅ Money saved\n✅ Freedom from addiction\n✅ Pride in your achievement\n✅ Being a role model\n\nYou're gaining so much more than you're giving up!",
      options: [
        'You\'re right!',
        'It\'s hard to stay positive',
        'I feel motivated now',
      ],
      responses: {
        'You\'re right!': "I'm glad this resonates with you! Keep focusing on these positives every day.",
        'It\'s hard to stay positive': "I understand. On tough days, remember even small progress is still progress. Be kind to yourself.",
        'I feel motivated now': "That's wonderful! Harness that motivation and carry it with you today!",
      },
      nextKey: 'encouragement',
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            _userName = userData?['name'] ?? 'there';
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }
    
    // Initial greeting with user's name
    _addBotMessage(
      "Hi $_userName! I'm your QuitMate ChatBot. I'm here to support you on your journey to quit smoking. How can I help you today?",
    );
  }

  void _addBotMessage(String message, {List<String>? options, List<Suggestion>? suggestions}) {
    // Replace placeholder with actual username in responses
    String personalizedMessage = message.replaceAll('\$_userName', _userName);
    
    setState(() {
      _messages.add(ChatMessage(
        text: personalizedMessage,
        isUser: false,
        timestamp: DateTime.now(),
        options: options,
        suggestions: suggestions,
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _showOptions = false;
    });
    _scrollToBottom();
  }

  void _handleQuickOption(String key) {
    _addUserMessage(_getQuickOptionText(key));
    
    Future.delayed(const Duration(milliseconds: 500), () {
      final node = _conversationTree[key];
      if (node != null) {
        _addBotMessage(
          node.botResponse,
          options: node.options,
          suggestions: node.suggestions,
        );
      }
    });
  }

  void _handleResponse(String response, String? nextKey, Map<String, String>? responses) {
    _addUserMessage(response);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (responses != null && responses.containsKey(response)) {
        _addBotMessage(responses[response]!);
      }
      
      if (nextKey != null) {
        Future.delayed(const Duration(milliseconds: 800), () {
          final node = _conversationTree[nextKey];
          if (node != null) {
            _addBotMessage(
              node.botResponse,
              options: node.options,
              suggestions: node.suggestions,
            );
          }
        });
      } else {
        // Show main options again
        Future.delayed(const Duration(milliseconds: 800), () {
          setState(() {
            _showOptions = true;
          });
        });
      }
    });
  }

  String _getQuickOptionText(String key) {
    switch (key) {
      case 'craving':
        return "I'm having a strong craving right now. I really want a cigarette...";
      case 'motivation':
        return "I need some motivation to keep going.";
      case 'feeling':
        return "I want to talk about how I'm feeling.";
      case 'tips':
        return "Can you give me some tips?";
      default:
        return key;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EDE2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF303870),
        title: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: const BoxDecoration(
                color: Color(0xFFFABA5C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('ChatBot', style: TextStyle(color: Colors.white)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message);
              },
            ),
          ),
          
          // Quick Options
          if (_showOptions)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Options:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF303870).withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickOptionButton('I need help with a craving', 'craving'),
                      _buildQuickOptionButton('Give me motivation', 'motivation'),
                      _buildQuickOptionButton('How am I feeling?', 'feeling'),
                      _buildQuickOptionButton('Share some tips', 'tips'),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFABA5C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          message.text,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF303870),
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (message.suggestions != null && message.suggestions!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...message.suggestions!.map((suggestion) => _buildSuggestionCard(suggestion)),
                      ],
                      if (message.options != null && message.options!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: message.options!.map((option) {
                            return _buildOptionButton(option, message);
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF303870),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF303870).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF303870), size: 16),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Suggestion suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _handleQuickOption(suggestion.nextKey),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFABA5C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFABA5C).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFABA5C),
                  shape: BoxShape.circle,
                ),
                child: Icon(suggestion.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF303870),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF303870).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFFABA5C)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option, ChatMessage message) {
    // Find the conversation node to get responses and nextKey
    String? nextKey;
    Map<String, String>? responses;
    
    for (var node in _conversationTree.values) {
      if (node.options?.contains(option) == true) {
        nextKey = node.nextKey;
        responses = node.responses;
        break;
      }
    }

    return InkWell(
      onTap: () => _handleResponse(option, nextKey, responses),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFABA5C)),
        ),
        child: Text(
          option,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF303870),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickOptionButton(String label, String key) {
    return InkWell(
      onTap: () => _handleQuickOption(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFABA5C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? options;
  final List<Suggestion>? suggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.options,
    this.suggestions,
  });
}

class ConversationNode {
  final String botResponse;
  final List<String>? options;
  final Map<String, String>? responses;
  final List<Suggestion>? suggestions;
  final String? nextKey;

  ConversationNode({
    required this.botResponse,
    this.options,
    this.responses,
    this.suggestions,
    this.nextKey,
  });
}

class Suggestion {
  final IconData icon;
  final String title;
  final String description;
  final String nextKey;

  Suggestion({
    required this.icon,
    required this.title,
    required this.description,
    required this.nextKey,
  });
}