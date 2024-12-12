import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String? Ip = dotenv.env['IP'];
final String? Port = dotenv.env['PORT'];

class ViewSalaryForEmployee extends StatefulWidget {
  const ViewSalaryForEmployee({super.key});

  @override
  _ViewSalaryForEmployeeState createState() => _ViewSalaryForEmployeeState();
}

class _ViewSalaryForEmployeeState extends State<ViewSalaryForEmployee> {
  List<Map<String, dynamic>> salaryRecords = [];

  @override
  void initState() {
    super.initState();
    fetchSalaryData();
  }

  Future<void> fetchSalaryData() async {
    try {
      // Retrieve the employeeId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? employeeId = prefs.getInt('employeeId');

      // Call the backend API with the employeeId
      final response = await http.get(
        Uri.parse('http://$Ip:$Port/employee_salar?employeeId=$employeeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // If the request is successful, update the UI with the salary data
        List<dynamic> data = json.decode(response.body);
        setState(() {
          salaryRecords = List<Map<String, dynamic>>.from(data);
        });
      } else {
        // Handle the case where the request fails
        print('Failed to load salary data');
      }
    } catch (e) {
      print('Error: $e');
    }
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
                  "Your Salary",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // White box with Card layout
            Expanded(
              child: Container(
                width: screenWidth * 0.9, // 90% of screen width
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
                    itemCount: salaryRecords.length,
                    itemBuilder: (context, index) {
                      final record = salaryRecords[index];
                      final firstName = record['first_name'];
                      final lastName = record['last_name'];
                      final date = record['pay_date'];
                      final amount = record['salary'];
                      final incentive = record['incentive'];
                      final position = record['Position'];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.money,
                            color: Colors.green[700],
                          ),
                          title: Text("Employee: $firstName $lastName"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Pay Date: $date"),
                              Text("Position: $position"),
                              Text("Salary: \$ $amount"),
                              Text("Incentive: \$ $incentive"),
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

class Employee {
  final int id;
  final String firstName;
  final String lastName;
  final String designation;
  final double? salary;
  final double? incentive;
  final String payDate;
  final String contact;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.designation,
    required this.salary,
    required this.incentive,
    required this.payDate,
    required this.contact,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      firstName: json['first_name'],
      lastName: json['last_name'],
      designation: json['Position'],
      salary: json['salary'],
      incentive: json['incentive'],
      payDate: json['pay_date'],
      contact: json['contact'],
    );
  }
}
