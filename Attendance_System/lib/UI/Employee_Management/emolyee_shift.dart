import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String? ip = dotenv.env['IP'];
final String? port = dotenv.env['PORT'];

class EmployeeShift extends StatefulWidget {
  const EmployeeShift({super.key});

  @override
  EmployeeShiftState createState() => EmployeeShiftState();
}

class EmployeeShiftState extends State<EmployeeShift> {
  String selectedShift = 'Morning'; // Default shift selection
  List<Map<String, dynamic>> employees = [];

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  // Method to fetch employees from the backend based on selected shift
  Future<void> fetchEmployees({String? shift}) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://$ip:$port/employee/shift?shift=${shift ?? ""}'), // Send shift or all employees
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          employees = List<Map<String, dynamic>>.from(data.map((e) {
            return {
              'name': e['first_name'] + ' ' + e['last_name'],
              'shift': e['shift'],
              'role': e['role'],
              'email': e['email'],
            };
          }));
        });
      } else {
        if (kDebugMode) {
          print('Failed to load employees');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  // Method to filter employees based on selected shift
  List<Map<String, dynamic>> getFilteredEmployees() {
    return employees.where((employee) {
      return employee['shift'] == selectedShift;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 800;

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
                    "Manage Employee Shifts",
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
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.03,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.03,
                  ),
                  child: Column(
                    children: [
                      FadeInUp(
                        duration: const Duration(milliseconds: 1200),
                        child: buildShiftDropdown(screenHeight),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Expanded(
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 1400),
                          child: SingleChildScrollView(
                            child: isWeb
                                ? Wrap(
                                    spacing: screenWidth * 0.02,
                                    runSpacing: screenHeight * 0.02,
                                    children:
                                        getFilteredEmployees().map((employee) {
                                      return buildEmployeeCard(employee,
                                          screenHeight, screenWidth * 0.3);
                                    }).toList(),
                                  )
                                : Column(
                                    children:
                                        getFilteredEmployees().map((employee) {
                                      return buildEmployeeCard(
                                          employee, screenHeight, screenWidth);
                                    }).toList(),
                                  ),
                          ),
                        ),
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

  // Build Shift Dropdown Widget
  Widget buildShiftDropdown(double screenHeight) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey[200] ?? Colors.blueGrey,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        value: selectedShift,
        hint: const Text("Select Shift", style: TextStyle(color: Colors.grey)),
        items: ['Morning', 'Afternoon', 'Night'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            selectedShift = newValue!;
            fetchEmployees(
                shift: selectedShift); // Fetch employees based on shift
          });
        },
      ),
    );
  }

  // Build Employee Card
  Widget buildEmployeeCard(
      Map<String, dynamic> employee, double screenHeight, double cardWidth) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: cardWidth,
        padding: EdgeInsets.all(screenHeight * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${employee['name']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Shift: ${employee['shift']}'),
            Text('Role: ${employee['role']}'),
            Text('Email: ${employee['email']}'),
          ],
        ),
      ),
    );
  }
}
