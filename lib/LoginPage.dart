// LoginPage.dart
// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:paper_summarizer_frontend/PromptScreen.dart';
import 'package:paper_summarizer_frontend/SignupPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import your Home Page

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final Dio _dio = Dio();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter email and password", Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dio.post(
        'http://localhost:8080/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        var data = response.data.split(":");
        final String jwtToken = data[1];

        // Save JWT token in shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwtToken', jwtToken);

        _showSnackBar("Login successful", Colors.green);

        // Navigate to Home Page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PromptScreen()),
          );
        }
      } else {
        _showSnackBar(
            "Login failed. Please check your credentials.", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
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
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupPage()),
                );
              },
              child: const Text("Don't have an account? Signup"),
            ),
          ],
        ),
      ),
    );
  }
}
