import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  GenerativeModel? _model;
  ChatSession? _chatSession;

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

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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
              backgroundColor: Colors.green.withOpacity(0.2),
              child: const Icon(Icons.smart_toy, color: Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(  // Make sure this column doesn't overflow
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
            // Chat suggestion chips - wrapped in a Container with fixed height
            if (_messages.length < 3)
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SuggestionChips(
                    onSuggestionTap: (suggestion) {
                      _addUserMessage(suggestion);
                    },
                  ),
                ),
              ),

            // Messages list - wrap in Expanded + Container to ensure proper rendering
            Expanded(
              child: Container(
                color: colorScheme.surface,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return MessageBubble(
                      message: message,
                      colorScheme: colorScheme,
                    );
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
                      backgroundColor: Colors.green.withOpacity(0.2),
                      child: const Icon(Icons.smart_toy, size: 18, color: Colors.green),
                    ),
                    const SizedBox(width: 8),
                    const TypingIndicator(),
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
              child: Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          textCapitalization: TextCapitalization.sentences,
                          // Add these properties for multiline support
                          maxLines: null, // Allows unlimited lines
                          minLines: 1, // Starts with one line
                          textInputAction: TextInputAction.newline, // Allows new lines with Enter/Return
                          keyboardType: TextInputType.multiline, // Enables multiline keyboard
                          decoration: const InputDecoration(
                            hintText: "Ask about cats...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          // Changed to onChanged to capture input without submission
                          onChanged: (text) {
                            // This will be called as the user types
                            setState(() {
                              // You could add additional logic here if needed
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: colorScheme.primary,
                        ),
                        onPressed: () {
                          if (_textController.text.trim().isNotEmpty) {
                            _addUserMessage(_textController.text);
                          }
                        },
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
        child: SingleChildScrollView(  // Add SingleChildScrollView here
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(  // Added Expanded to prevent overflow
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.help_outline, color: Colors.green, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(  // Added Expanded to prevent text overflow
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
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      context,
                      icon: Icons.format_bold,
                      title: 'Rich Formatting',
                      description: 'Responses include markdown formatting for better readability',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
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
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(  // Added Expanded to prevent text overflow
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green.withOpacity(0.2),
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.green),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(  // Use Flexible instead of Expanded
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primary
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  // Use Markdown widget for bot messages, regular Text for user messages
                  child: isUser ? Text(
                    message.text,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                    ),
                  ) : MarkdownBody(
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
                      listBullet: const TextStyle(
                        color: Colors.green,
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
                      // Removed invalid 'table' property
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
  const TypingIndicator({super.key});

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
            color: Colors.green.withOpacity(0.5 + 0.5 * animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class SuggestionChips extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const SuggestionChips({
    super.key,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      "What are signs my cat is sick?",
      "Compare Maine Coon vs Persian cats",
      "Why does my cat knead?",
      "Create a table of cat breeds",
      "How to stop scratching furniture"
    ];

    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,  // Keep the column as small as possible
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                "Try asking about:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            SingleChildScrollView(  // Add horizontal scrolling capability
              scrollDirection: Axis.horizontal,
              child: Row(  // Change Wrap to Row with SingleChildScrollView
                children: suggestions.map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(suggestion),
                      avatar: Icon(
                        Icons.pets,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => onSuggestionTap(suggestion),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}