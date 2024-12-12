import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String? Ip = dotenv.env['IP'];
final String? Port = dotenv.env['PORT'];

class EmployeeManagementHistory extends StatefulWidget {
  const EmployeeManagementHistory({super.key});

  @override
  _EmployeeManagementState createState() => _EmployeeManagementState();
}

class _EmployeeManagementState extends State<EmployeeManagementHistory> {
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  // Fetch employee data from the API
  Future<void> _fetchEmployees() async {
    try {
      final response = await http.get(Uri.parse('http://$Ip:$Port/promotion'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _employees = data
              .map((employeeData) => Employee.fromJson(employeeData))
              .toList();
        });
      } else {
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      print("Error fetching employees: $e");
    }
  }

  void _viewPromotionHistory(Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromotionHistoryPage(employee: employee),
      ),
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Promotion History",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Expanded(
              child: Container(
                width: screenWidth * 0.9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.03,
                  ),
                  child: _employees.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _employees.length,
                          itemBuilder: (context, index) {
                            final employee = _employees[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${employee.firstName} ${employee.lastName}",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                        "Designation: ${employee.designation}"),
                                    Text(
                                        "Salary: \$${employee.salary.toStringAsFixed(2)}"),
                                    Text("Email: ${employee.email}"),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _viewPromotionHistory(employee),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueGrey[600],
                                      ),
                                      child: const Text(
                                        "View Promotion History",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

class PromotionHistoryPage extends StatelessWidget {
  final Employee employee;

  const PromotionHistoryPage({super.key, required this.employee});

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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Promotion History",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Expanded(
              child: Container(
                width: screenWidth * 0.9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.03,
                  ),
                  child: ListView.builder(
                    itemCount: employee.promotionHistory.length,
                    itemBuilder: (context, index) {
                      final promotion = employee.promotionHistory[index];
                      return ListTile(
                        title: Text(
                          "Promotion to ${promotion.newDesignation}",
                          style: const TextStyle(fontSize: 18),
                        ),
                        subtitle: Text(
                          "On ${DateFormat.yMMMd().format(promotion.date)} \n"
                          "Previous Designation: ${promotion.oldDesignation}\n"
                          "New Salary: \$${promotion.newSalary.toStringAsFixed(2)}",
                        ),
                        isThreeLine: true,
                      );
                    },
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

class Employee {
  String firstName;
  String lastName;
  String designation;
  double salary;
  String email;
  List<Promotion> promotionHistory;

  Employee({
    required this.firstName,
    required this.lastName,
    required this.designation,
    required this.salary,
    required this.email,
    List<Promotion>? promotionHistory,
  }) : promotionHistory = promotionHistory ?? [];

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      firstName: json['first_name'],
      lastName: json['last_name'],
      designation: json['designation'],
      salary: json['salary'],
      email: json['email'],
      promotionHistory: [], // Empty for now, you can fetch it later if needed
    );
  }
}

class Promotion {
  DateTime date;
  String oldDesignation;
  String newDesignation;
  double newSalary;

  Promotion({
    required this.date,
    required this.oldDesignation,
    required this.newDesignation,
    required this.newSalary,
  });
}
