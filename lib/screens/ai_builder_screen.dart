import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/server_provider.dart';

/// AI Builder — user describes a structure in natural language,
/// the system (later a real plugin + LLM) places blocks in the world.
class AiBuilderScreen extends StatefulWidget {
  final String serverId;

  const AiBuilderScreen({super.key, required this.serverId});

  @override
  State<AiBuilderScreen> createState() => _AiBuilderScreenState();
}

class _AiBuilderScreenState extends State<AiBuilderScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMsg> _messages = [
    _ChatMsg(
      isAi: true,
      text:
          'Namaste! Main tumhara AI Builder hoon.\n\nBol do kya banana hai, jaise:\n• "Ek bada medieval castle banao"\n• "Spawn pe modern house with pool"\n• "Pyramid of glass near the lake"\n\nMain blocks place kar dunga (simulated for now).',
    ),
  ];
  bool _building = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _building) return;

    setState(() {
      _messages.add(_ChatMsg(isAi: false, text: text));
      _controller.clear();
      _building = true;
    });
    _scrollToBottom();

    final provider = Provider.of<ServerProvider>(context, listen: false);

    // Simulate thinking + building steps
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _messages.add(_ChatMsg(
        isAi: true,
        text: 'Samajh gaya: "$text"\nPlan bana raha hoon...',
      ));
    });
    _scrollToBottom();

    provider.sendCommand(widget.serverId, 'say [AI Builder] Starting build: $text');

    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      _messages.add(_ChatMsg(
        isAi: true,
        text: 'Foundation place kar raha hoon...',
      ));
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _messages.add(_ChatMsg(
        isAi: true,
        text: 'Walls aur structure bana raha hoon...',
      ));
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      _messages.add(_ChatMsg(
        isAi: true,
        text:
            '✅ Build complete (simulated)!\n\nReal version me yeh ek in-game bot/plugin hoga jo LLM se instructions lega aur blocks place karega.\n\nAur kuch banana hai?',
      ));
      _building = false;
    });
    _scrollToBottom();

    provider.sendCommand(widget.serverId, 'say [AI Builder] Build finished!');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'AI Builder',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Describe any build in Hindi or English. AI will place blocks in the world when server is online.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                  ),
                ),
              ],
            ),
          ),

          // Chat
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: m.isAi ? AppTheme.card : AppTheme.primaryGreen.withOpacity(0.18),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(m.isAi ? 4 : 14),
                        bottomRight: Radius.circular(m.isAi ? 14 : 4),
                      ),
                      border: m.isAi
                          ? Border.all(color: AppTheme.surfaceLight)
                          : null,
                    ),
                    child: Text(
                      m.text,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.surfaceLight)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Batao kya banana hai...',
                        filled: true,
                        fillColor: AppTheme.card,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: _building ? AppTheme.surfaceLight : AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _building ? null : _send,
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: _building
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryGreen,
                                ),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMsg {
  final bool isAi;
  final String text;
  _ChatMsg({required this.isAi, required this.text});
}
