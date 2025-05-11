import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for KeyEvent
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // Added focus node for keyboard handling
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _showSuggestions = true; // Flag to control suggestion visibility
  bool _isShiftPressed = false; // Track if Shift key is pressed

  // Replace with your actual API key
  static const String _apiKey = 'AIzaSyCIw-cx2kCxedSrXLQ9d-1ZDCQvOvit0aI';

  @override
  void initState() {
    super.initState();
    _initializeGemini();

    // Add welcome message with markdown formatting
    _addBotMessage("""
# Welcome to Cat Chat! 😺

I'm your **Cat Assistant** powered by *Gemini*. Ask me anything about:
- Cat health and wellness
- Breed information
- Behavior patterns
- Care and training tips

How can I help you with your feline friend today?
    """);
  }

  Future<void> _initializeGemini() async {
    try {
      // Initialize the Gemini 2.0 Flash model
      _model = GenerativeModel(
        model: 'gemini-2.0-flash', // Updated to gemini-2.0-flash
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          topK: 30,
          topP: 0.8,
          maxOutputTokens: 2048,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        ],
      );

      // Create a new chat session with Gemini, instructing it to use markdown
      _chatSession = _model?.startChat(history: [
        Content.text(
            "You are a helpful assistant specializing in cat information. "
                "You provide accurate and concise knowledge about cat breeds, behavior, health, care tips, "
                "nutrition, training, and other feline-related topics. "
                "Keep your answers short and to the point unless specifically asked for more detail. "
                "Format responses using Markdown: use **bold** for emphasis, *italics* for terms, "
                "## headings for sections, bullet points for lists, and markdown tables when appropriate. "
                "If asked about topics unrelated to cats, gently redirect the conversation back to cat-related information."
        )
      ]);
    } catch (e) {
      _addBotMessage("Sorry, I couldn't initialize the chat service. Please try again later.");
      debugPrint("Gemini initialization error: $e");
    }
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
      _showSuggestions = false; // Hide suggestions after user sends a message
    });

    _scrollToBottom();
    _textController.clear();

    // Send message to Gemini
    _sendMessageToGemini(message);
  }

  void _addBotMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  Future<void> _sendMessageToGemini(String message) async {
    if (_chatSession == null) {
      _addBotMessage("Sorry, the chat service is not available right now. Please try again later.");
      return;
    }

    try {
      // Add error handling and timeout for API request
      final response = await _chatSession!.sendMessage(Content.text(message))
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('Request timed out. Please check your internet connection.');
      });

      final responseText = response.text ?? "Sorry, I couldn't generate a response.";

      _addBotMessage(responseText);
    } catch (e) {
      debugPrint("Gemini API error: $e");
      _addBotMessage("Sorry, I couldn't process your request. Please try again.");
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    // Add a small delay to ensure the list is updated before scrolling
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

  // Function to handle message sending (for both button and Enter key)
  void _handleSendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      _addUserMessage(_textController.text);
    }
  }

  // Updated key event handler using the modern KeyEvent API instead of deprecated RawKeyEvent
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Track shift key state
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.shift) {
      _isShiftPressed = true;
    } else if (event is KeyUpEvent && event.logicalKey == LogicalKeyboardKey.shift) {
      _isShiftPressed = false;
    }

    // Handle Enter key press - send message if Enter is pressed without Shift
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !_isShiftPressed) {
      _handleSendMessage();
      return KeyEventResult.handled; // Prevent default behavior
    }

    // Let other key events be handled normally
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primary.withOpacity(0.2),
              child: Icon(Icons.smart_toy, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Cat Chat",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Powered by Gemini",
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog(context);
            },
          ),
        ],
      ),
      // Wrap with ResizeToAvoidBottomInset to handle keyboard properly
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Messages list - wrap in Expanded + Container to ensure proper rendering
            Expanded(
              child: Container(
                color: colorScheme.surface,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _messages.length + (_showSuggestions && _messages.length == 1 ? 1 : 0),
                  itemBuilder: (context, index) {
                    // If we're at the position after the first message and suggestions should be shown
                    if (_showSuggestions && index == 1 && _messages.length == 1) {
                      return SuggestionChips(
                        onSuggestionTap: (suggestion) {
                          _addUserMessage(suggestion);
                        },
                      );
                    }

                    // Normal message bubbles (accounting for suggestion position)
                    final messageIndex = _showSuggestions && _messages.length == 1 && index > 1
                        ? index - 1
                        : index;

                    if (messageIndex < _messages.length) {
                      final message = _messages[messageIndex];
                      return MessageBubble(
                        message: message,
                        colorScheme: colorScheme,
                      );
                    }

                    return const SizedBox.shrink(); // Fallback
                  },
                ),
              ),
            ),

            // Bot is typing indicator
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primary.withOpacity(0.2),
                      child: Icon(Icons.smart_toy, size: 18, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    TypingIndicator(colorScheme: colorScheme),
                  ],
                ),
              ),

            // Message input - with careful padding to avoid layout issues
            Padding(
              padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8.0 : MediaQuery.of(context).padding.bottom + 8.0,
                top: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        // Use KeyboardListener instead of RawKeyboardListener
                        child: Focus(
                          focusNode: _focusNode,
                          onKeyEvent: _handleKeyEvent,
                          child: TextField(
                            controller: _textController,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: null, // Allow multiple lines
                            minLines: 1, // Start with one line
                            keyboardType: TextInputType.multiline, // Support multiline input
                            style: TextStyle(color: colorScheme.onSurface),
                            cursorColor: colorScheme.primary,
                            decoration: InputDecoration(
                              hintText: "Ask about cats...",
                              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              filled: false,
                            ),
                            // Do not use onEditingComplete or onSubmitted since
                            // we're handling key events manually through KeyboardListener
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: colorScheme.primary,
                        ),
                        onPressed: _handleSendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4, // Slightly higher elevation for dialog
        shadowColor: colorScheme.shadow.withOpacity(0.7),
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? colorScheme.surface.brighten(15)
            : colorScheme.surface.brighten(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.help_outline, color: colorScheme.primary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Chat Help',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.2)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What you can ask:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      context,
                      icon: Icons.pets,
                      title: 'Breeds Information',
                      description: 'Ask about specific cat breeds and their characteristics',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      context,
                      icon: Icons.medical_services,
                      title: 'Health Questions',
                      description: 'Get information about common cat health issues',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      context,
                      icon: Icons.restaurant,
                      title: 'Nutrition Advice',
                      description: 'Learn about proper diet and nutrition for cats',
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      context,
                      icon: Icons.psychology,
                      title: 'Behavior Understanding',
                      description: 'Understand why cats behave certain ways',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme colorScheme;

  const MessageBubble({
    super.key,
    required this.message,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeFormat = TimeOfDay.fromDateTime(message.timestamp).format(context);

    // Get the appropriate bubble color based on theme brightness
    final bubbleColor = Theme.of(context).brightness == Brightness.light
        ? colorScheme.surface.brighten(10)
        : colorScheme.surface.brighten(15);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.2),
              child: Icon(Icons.smart_toy, size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // Use the same color for both user and bot messages
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  // Use appropriate text style based on message source
                  child: isUser
                      ? Text(
                    message.text,
                    style: TextStyle(
                      color: colorScheme.onSurface, // Changed from onPrimary to onSurface
                    ),
                  )
                      : MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: colorScheme.onSurface),
                      h1: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      h2: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      h3: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      h4: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14
                      ),
                      strong: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      em: TextStyle(
                        color: colorScheme.onSurface,
                        fontStyle: FontStyle.italic,
                      ),
                      listBullet: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      code: TextStyle(
                        color: colorScheme.onSurface,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      blockquote: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: colorScheme.primary.withOpacity(0.5),
                            width: 4,
                          ),
                        ),
                      ),
                      // Fixed table styling
                      tableHead: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      tableBody: TextStyle(
                        color: colorScheme.onSurface,
                      ),
                      tableHeadAlign: TextAlign.center,
                      tableBorder: TableBorder.all(
                        color: colorScheme.primary.withOpacity(0.5),
                        width: 1,
                      ),
                      tableColumnWidth: const FlexColumnWidth(),
                      tableCellsPadding: const EdgeInsets.all(8),
                    ),
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        // Handle link taps
                        launchUrl(Uri.parse(href));
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
                  child: Text(
                    timeFormat,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.2),
              child: Icon(Icons.person, size: 18, color: colorScheme.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  final ColorScheme colorScheme;

  const TypingIndicator({super.key, required this.colorScheme});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          children: [
            _buildDot(0),
            const SizedBox(width: 2),
            _buildDot(1),
            const SizedBox(width: 2),
            _buildDot(2),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final double delay = index * 0.2;
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, min(delay + 0.4, 1.0), curve: Curves.easeInOut),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.colorScheme.primary.withOpacity(0.5 + 0.5 * animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

// Modified SuggestionChips to be horizontally scrollable
class SuggestionChips extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const SuggestionChips({
    super.key,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final suggestions = [
      "What are signs my cat is sick?",
      "Compare Maine Coon vs Persian cats",
      "Why does my cat knead?",
      "Create a table of cat breeds",
      "How to stop scratching furniture"
    ];

    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Text(
              "Try asking about:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    backgroundColor: colorScheme.primary.withOpacity(0.1), // Restored background color
                    side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                    label: Text(
                      suggestion,
                      style: TextStyle(color: colorScheme.primary),
                    ),
                    avatar: Icon(
                      Icons.pets,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => onSuggestionTap(suggestion),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to adjust color brightness (added from user_dashboard.dart)
extension ColorBrightness on Color {
  Color brighten(int amount) {
    return Color.fromARGB(
      alpha,
      (red + amount).clamp(0, 255),
      (green + amount).clamp(0, 255),
      (blue + amount).clamp(0, 255),
    );
  }

  Color darken(int amount) {
    return Color.fromARGB(
      alpha,
      (red - amount).clamp(0, 255),
      (green - amount).clamp(0, 255),
      (blue - amount).clamp(0, 255),
    );
  }
}