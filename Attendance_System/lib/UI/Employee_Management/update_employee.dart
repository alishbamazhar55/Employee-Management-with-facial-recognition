import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String? Ip = dotenv.env['IP'];
final String? Port = dotenv.env['PORT'];

class EmployeeUpdate extends StatefulWidget {
  const EmployeeUpdate({super.key});

  @override
  EmployeeUpdateState createState() => EmployeeUpdateState();
}

class EmployeeUpdateState extends State<EmployeeUpdate> {
  List<Map<String, dynamic>> employees = [];

  @override
  void initState() {
    super.initState();
    fetchEmployees(); // Fetch employee data when the widget is initialized
  }

  // Fetch employee data from the API
  Future<void> fetchEmployees() async {
    try {
      final response = await http.get(
          Uri.parse('http://$Ip:$Port/employees')); // Update with your API URL

      if (response.statusCode == 200) {
        final List<dynamic> employeeData = json.decode(response.body);
        setState(() {
          employees = employeeData
              .map((emp) => {
                    'id': emp['id'],
                    'name':
                        '${emp['first_name']} ${emp['last_name'] ?? ''}', // Combine first and last names
                    'shift': emp['shift'],
                    'role': emp['role'],
                    'email': emp['email'],
                  })
              .toList();
        });
      } else {
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      // Handle the error
      print('Error fetching employees: $e');
    }
  }

  // Function to delete employee
  Future<void> deleteEmployee(int index) async {
    // Show a confirmation dialog before deletion
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: Text(
            "Are you sure you want to delete '${employees[index]['name']}'?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User canceled deletion
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed deletion
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    // Proceed with deletion if user confirmed
    if (confirmDelete == true) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int? employeeId = prefs.getInt('employeeId');

        if (employeeId != null) {
          final employeeId = employees[index]['id'];

          final response = await http.delete(
            Uri.parse('http://$Ip:$Port/employee/$employeeId'),
            headers: {"Content-Type": "application/json"},
          );

          if (response.statusCode == 200) {
            setState(() {
              employees.removeAt(index); // Remove employee from the UI
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Employee deleted successfully!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to delete employee: ${response.body}')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to delete employee: User ID not found')),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting employee: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting employee: $e')),
        );
      }
    }
  }

  Future<void> updateEmployee(int index) async {
    TextEditingController nameController =
        TextEditingController(text: employees[index]['name']);
    TextEditingController emailController =
        TextEditingController(text: employees[index]['email']);
    TextEditingController usernameController =
        TextEditingController(text: employees[index]['username'] ?? '');
    TextEditingController passwordController = TextEditingController();

    String? selectedRole = employees[index]['role'];
    String? selectedShift = employees[index]['shift'];

    String? nameError;
    String? emailError;
    String? passwordError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Update Employee"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Name",
                        errorText: nameError,
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty ||
                              RegExp(r'[^a-zA-Z\s]')
                                  .hasMatch(value.split(' ')[0]) ||
                              RegExp(r'[^a-zA-Z\s]')
                                  .hasMatch(value.split(' ')[1])) {
                            nameError = "Enter a valid name (letters only)";
                          } else {
                            nameError = null;
                          }
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedShift,
                      items: <String>['Morning', 'Afternoon', 'Night']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      decoration: const InputDecoration(labelText: "Shift"),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedShift = newValue;
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      items: <String>[
                        'Manager',
                        'Staff',
                        'Finance Manager',
                        'Chef',
                        'Janitor'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      decoration: const InputDecoration(labelText: "Role"),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRole = newValue;
                        });
                      },
                    ),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        errorText: emailError,
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty ||
                              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                            emailError = "Enter a valid email (abc@xyz.com)";
                          } else {
                            emailError = null;
                          }
                        });
                      },
                    ),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: "Username"),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: "Password",
                        errorText: passwordError,
                      ),
                      obscureText: true,
                      onChanged: (value) {
                        setState(() {
                          if (value.length < 6) {
                            passwordError =
                                'Password must be at least 6 characters';
                          }
                          if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                            passwordError = 'Add at least one uppercase letter';
                          }
                          if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                            passwordError = 'Add least one lowercase letter';
                          }
                          if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
                            passwordError = 'Add at least one number';
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (nameError == null &&
                        emailError == null &&
                        passwordError == null) {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      int? employeeId = prefs.getInt('employeeId');

                      if (employeeId != null) {
                        final response = await http.put(
                          Uri.parse(
                              'http://$Ip:$Port/employee/${employees[index]['id']}'),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            'first_name': nameController.text.split(' ')[0],
                            'last_name': nameController.text
                                .split(' ')
                                .sublist(1)
                                .join(' '),
                            'email': emailController.text,
                            'shift': selectedShift,
                            'role': selectedRole,
                            'username': usernameController.text,
                            'password': passwordController.text,
                            'updatedBy': employeeId,
                          }),
                        );

                        if (response.statusCode == 200) {
                          // Update the local list after a successful response
                          setState(() {
                            employees[index] = {
                              'id': employees[index]['id'],
                              'name': nameController.text,
                              'shift': selectedShift,
                              'role': selectedRole,
                              'email': emailController.text,
                              'username': usernameController.text,
                            };
                          });
                          // Close the dialog
                          Navigator.of(context).pop();

                          // Refresh the UI outside the dialog
                          this.setState(() {});

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Employee updated successfully!',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight
                                        .bold), // Apply TextStyle here
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Failed to update employee: ${response.body}')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text("Update"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

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
          children: [
            SizedBox(height: screenHeight * 0.07),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.01,
                horizontal: screenWidth * 0.03,
              ),
              child: FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Manage Employee Data",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Center(
              child: Container(
                width: screenWidth * 0.9,
                height: screenHeight * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(40)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.03,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.03),
                        FadeInUp(
                          duration: const Duration(milliseconds: 1200),
                          child: Column(
                            children: List.generate(employees.length, (index) {
                              return Card(
                                margin: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.015),
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(screenHeight * 0.02),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Name: ${employees[index]['name']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                          'Shift: ${employees[index]['shift']}'),
                                      Text('Role: ${employees[index]['role']}'),
                                      Text(
                                          'Email: ${employees[index]['email']}'),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () {
                                              updateEmployee(index);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () {
                                              deleteEmployee(index);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
