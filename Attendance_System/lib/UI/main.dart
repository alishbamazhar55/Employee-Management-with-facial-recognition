import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'DashBoards/Manager_dashboard.dart' as manager;
import 'DashBoards/Employee_Dashboard.dart' as employee;
import 'DashBoards/Accountant_dashboard.dart' as accountant;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String? apiUrl = dotenv.env['IP'];
final String? apiPort = dotenv.env['PORT'];

void main() async {
  await dotenv.load(fileName: 'environment.env');
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage()
    ),
  );
}

class User {
  final String email;
  final String role;

  User({required this.email, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['Username'],
      role: json['Position'],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  User? currentUser;

  String emailError = '';
  String passwordError = '';

  void _validateUsername(String username) {
    setState(() {
      if (username.isEmpty) {
        emailError = 'Username cannot be empty.';
      } else if (username.length < 3) {
        // Check if the username length is less than 3
        if (RegExp(r'\d').hasMatch(username) ||
            !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(username)) {
          emailError =
              'Username must be at least 3 characters long and cannot start with digits.';
        } else {
          emailError = 'Username must be at least 3 characters long.';
        }
      } else if (username.length > 20) {
        emailError = 'Username must not exceed 20 characters.';
      } else if (RegExp(r'^[0-9]').hasMatch(username)) {
        emailError = 'Username cannot start with a digit.';
      } else if (username[0] != username[0].toUpperCase()) {
        // Check if first character is capital
        emailError = 'The first character of the username must be uppercase.';
      } else {
        emailError = '';
      }
    });
  }

  void _validatePassword(String password) {
    setState(() {
      if (password.isEmpty) {
        passwordError = 'Password cannot be empty.';
      } else if (password.length < 6) {
        passwordError = 'Password must be at least 6 characters long.';
      } else if (password.length > 20) {
        passwordError = 'Password must not exceed 20 characters.';
      } else if (!RegExp(r'^(?=.*[!@#$%^&*])[A-Za-z\d!@#$%^&*]+$')
          .hasMatch(password)) {
        passwordError = 'Password must contain at least one special character.';
      } else {
        passwordError = '';
      }
    });
  }

  Future<void> _login() async {
    final String username = emailController.text;
    final String password = passwordController.text;

    // Validate fields
    _validateUsername(username);
    _validatePassword(password);

    if (emailError.isNotEmpty || passwordError.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Please choose correct username and password for logging.")),
      );
      return;
    }

    if (kDebugMode) {
      print("Loging In");
    }
    final response = await http.post(
      Uri.parse('http://$apiUrl:$apiPort/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'Username': username, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      String redirectUrl = jsonResponse['redirect_url'];
      int employeeId = jsonResponse['EmployeeID'];

      // Store EmployeeID in SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('employeeId', employeeId);

      currentUser = User.fromJson(jsonResponse);

      Widget nextPage;
      switch (redirectUrl) {
        case '/Manager_dashboard':
          nextPage = manager.ManagerHomePage(Name: currentUser!.email);
          break;
        case '/Employee_Dashboard':
          nextPage = employee.EmployeeHomePage(managerName: currentUser!.email);
          break;
        case '/Accountant_dashboard':
          nextPage = accountant.AccountantHomePage(Name: currentUser!.email);
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid user role")),
          );
          return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => nextPage,
        ),
      );
    } else if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect password")),
      );
    } else if (response.statusCode == 404) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${response.body}")),
      );
    }
  }

  void _navigateToResetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ResetPasswordPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenheight = MediaQuery.of(context).size.height;
    double screenwidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.blueGrey[900] ?? Colors.blueGrey,
              Colors.blueGrey[700] ?? Colors.blueGrey,
              Colors.blueGrey[400] ?? Colors.blueGrey,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: screenheight * 0.07),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenheight * 0.01,
                horizontal: screenwidth * 0.03,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    "Login to the Account",
                    style: TextStyle(color: Colors.white, fontSize: 40),
                  ),
                  SizedBox(height: screenheight * 0.01),
                  const Text(
                    "Welcome Back",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenheight * 0.07),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenheight * 0.01,
                    horizontal: screenwidth * 0.03,
                  ),
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: screenheight * 0.08),
                      Container(
                        decoration: BoxDecoration(
                          color: emailError.isNotEmpty
                              ? Colors.red[100]
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: " Username (e.g: Name123)",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            errorText:
                                emailError.isNotEmpty ? emailError : null,
                          ),
                          onChanged: _validateUsername,
                        ),
                      ),
                      SizedBox(height: screenheight * 0.02),
                      Container(
                        decoration: BoxDecoration(
                          color: passwordError.isNotEmpty
                              ? Colors.red[100]
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Password (e.g: xyz@123)",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            errorText:
                                passwordError.isNotEmpty ? passwordError : null,
                          ),
                          onChanged: _validatePassword,
                        ),
                      ),
                      SizedBox(height: screenheight * 0.05),
                      SizedBox(
                        width: screenwidth * 0.9,
                        height: screenheight * 0.06,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _login,
                          child: const Text(
                            "Login",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: screenheight * 0.03),
                      TextButton(
                        onPressed: _navigateToResetPassword,
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  String emailError = '';
  String passwordError = '';
  bool isPasswordUnique = true; // Flag to track password uniqueness

  // Validate email input
  void _validateEmail(String email) {
    setState(() {
      if (email.isEmpty) {
        emailError = 'Username cannot be empty.';
      } else if (email.length < 3) {
        if (RegExp(r'\d').hasMatch(email) ||
            !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(email) ||
            email[0] != email[0].toUpperCase()) {
          emailError =
              'Username must be at least 3 characters long and cannot contain digits or special characters with upper case first letter.';
        } else {
          emailError = 'Username must be at least 3 characters long.';
        }
      } else if (email.length > 20) {
        emailError = 'Username must not exceed 20 characters.';
      } else if (RegExp(r'^[0-9]').hasMatch(email)) {
        emailError = 'Username cannot start with a digit.';
      } else {
        emailError = '';
      }
    });
  }

  // Validate password input
  void _validatePassword(String password) {
    setState(() {
      if (password.isEmpty) {
        passwordError = 'New Password cannot be empty.';
      } else if (password.length < 6) {
        passwordError = 'Password must be at least 6 characters long.';
      } else if (password.length > 20) {
        passwordError = 'Password must not exceed 20 characters.';
      } else if (!RegExp(r'^(?=.[!@#$%^&])[A-Za-z\d!@#$%^&*]+$')
          .hasMatch(password)) {
        passwordError = 'Password must contain at least one special character.';
      } else {
        passwordError = '';
      }
    });
  }

  // Handle reset password request
  Future<void> _resetPassword() async {
    final String email = emailController.text;
    final String newPassword = newPasswordController.text;

    // Validate email and password before making the request
    _validateEmail(email);
    _validatePassword(newPassword);

    if (emailError.isNotEmpty || passwordError.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fix the errors before resetting password.")),
      );
      return;
    }

    // API request to reset the password
    final response = await http.post(
      Uri.parse('http://$apiUrl:$apiPort/reset_password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'new_password': newPassword}),
    );

    // Check if password is unique
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset successful")),
      );
    } else if (response.statusCode == 404) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found")),
      );
    } else if (response.statusCode == 400) {
      var errorMessage = json.decode(response.body)['error'];

      if (errorMessage.contains('Password must be unique')) {
        setState(() {
          passwordError =
              'The password must be unique. Please choose a different password.';
          isPasswordUnique =
              false; // Set to false if the password is not unique
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenheight = MediaQuery.of(context).size.height;
    double screenwidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical: screenheight * 0.01,
          horizontal: screenwidth * 0.03,
        ),
        child: Column(
          children: <Widget>[
            SizedBox(height: screenheight * 0.05),
            // Email TextField
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email or Username',
                border: const OutlineInputBorder(),
                errorText: emailError.isNotEmpty ? emailError : null,
              ),
              onChanged: _validateEmail,
            ),
            SizedBox(height: screenheight * 0.02),
            // Password TextField
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isPasswordUnique
                        ? Colors.grey
                        : Colors
                            .red, // Set red border if password is not unique
                    width: 2,
                  ),
                ),
                errorText: passwordError.isNotEmpty ? passwordError : null,
              ),
              onChanged: _validatePassword,
            ),
            SizedBox(height: screenheight * 0.04),
            // Reset Password Button
            SizedBox(
              width: screenwidth * 0.9,
              height: screenheight * 0.06,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _resetPassword,
                child: const Text(
                  "Reset Password",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
