import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:paper_summarizer_frontend/LoginPage.dart';
import 'package:paper_summarizer_frontend/PromptProvider.dart';
import 'package:paper_summarizer_frontend/ThemeProvider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  PromptScreenState createState() => PromptScreenState();
}

class PromptScreenState extends State<PromptScreen> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    bool isTokenValid = await _checkTokenValidity();
    if (!isTokenValid) {
      _redirectToLoginPage();
    }
  }

  Future<bool> _checkTokenValidity() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwtToken');

    if (token == null) return false;

    final decodedToken = _decodeJwt(token);
    if (decodedToken == null || decodedToken['exp'] == null) return false;

    int expiryTimestamp = decodedToken['exp'] * 1000;
    return DateTime.now().millisecondsSinceEpoch < expiryTimestamp;
  }

  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> _redirectToLoginPage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session has expired. Please login again.'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _sendPrompt() async {
    final responseProvider =
        Provider.of<ResponseProvider>(context, listen: false);
    responseProvider.clearResponse();
    responseProvider.setLoading(true);

    final promptText = _promptController.text;
    if (promptText.isEmpty) return;

    final pref = await SharedPreferences.getInstance();
    String? token = pref.getString('jwtToken');
    if (token == null) {
      _redirectToLoginPage();
      return;
    }

    const url = 'http://localhost:8080/api/paper_summarizer/prompt';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': token,
      'Accept': 'text/event-stream',
    };

    final bodyData = {'prompt': promptText};
    try {
      SSEClient.subscribeToSSE(
              method: SSERequestType.POST,
              url: url,
              header: headers,
              body: bodyData)
          .listen((event) {
        if (event.data != null) {
          responseProvider.addResponse(event.data!.replaceAll('\n', ''));
        }

        responseProvider.setLoading(false);
      });
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
      responseProvider.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper Summarizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              prefs.remove('jwtToken');
              _redirectToLoginPage();
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Consumer<ResponseProvider>(
              builder: (context, responseProvider, child) {
                if (responseProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (responseProvider.responseText.isEmpty) {
                  return const Center(child: Text('No response yet.'));
                } else {
                  return Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[850], // Less contrast color
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          responseProvider.responseText
                              .replaceAll(RegExp(r'\*\$\#'), '\n'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'Enter your prompt',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Consumer<ResponseProvider>(
              builder: (context, responseProvider, child) => ElevatedButton(
                onPressed: responseProvider.isLoading ? null : _sendPrompt,
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
