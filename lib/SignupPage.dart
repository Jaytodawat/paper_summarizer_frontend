// SignupPage.dart
// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:paper_summarizer_frontend/PromptScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  SignupPageState createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> {
  final Dio _dio = Dio();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter email and password");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dio.post(
        'http://localhost:8080/api/auth/register',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 201) {
        // print(response.data);
        var data = response.data.split(":");
        final String jwtToken = data[1];

        // Save JWT token in shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwtToken', jwtToken);
        _showSnackBar("Signup successful! Please log in");

        // Navigate to Login Page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PromptScreen()),
          );
        }
      } else {
        _showSnackBar("Signup failed. Please try again.");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _signup,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Signup'),
            ),
          ],
        ),
      ),
    );
  }
}
