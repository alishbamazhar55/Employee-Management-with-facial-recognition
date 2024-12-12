import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String? ip = dotenv.env['IP'];
final String? port = dotenv.env['PORT'];

class ViewAttendanceForManager extends StatefulWidget {
  const ViewAttendanceForManager({super.key});

  @override
  _ViewAttendanceForManagerState createState() =>
      _ViewAttendanceForManagerState();
}

class _ViewAttendanceForManagerState extends State<ViewAttendanceForManager> {
  DateTime selectedDate = DateTime.now();
  List<Employee> employees = [];

  // Function to select a date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _fetchAttendanceData(); // Fetch new data based on the selected date
      });
    }
  }

  Future<void> _fetchAttendanceData() async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final response = await http.get(
      Uri.parse('http://$ip:$port/attendance?date=$formattedDate'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        employees = data.map((json) => Employee.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load attendance data');
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
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
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "View Attendance",
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date: $formattedDate',
                            style: const TextStyle(fontSize: 20),
                          ),
                          ElevatedButton(
                            onPressed: () => _selectDate(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[600],
                            ),
                            child: const Text(
                              'Pick a Date',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Expanded(
                        child: ListView.builder(
                          itemCount: employees.length,
                          itemBuilder: (context, index) {
                            final employee = employees[index];
                            final attendanceStatus = employee.attendanceStatus
                                .toString()
                                .split('.')
                                .last;

                            // Card color based on attendance status
                            Color cardColor = Colors.white;
                            if (employee.attendanceStatus ==
                                AttendanceStatus.absent) {
                              cardColor = Colors.red[100]!;
                            } else if (employee.attendanceStatus ==
                                AttendanceStatus.late) {
                              cardColor = Colors.yellow[100]!;
                            }

                            return Card(
                              color: cardColor,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.person,
                                  color: Colors.blueGrey[700],
                                ),
                                title: Text(
                                    '${employee.firstName} ${employee.lastName}'),
                                subtitle: Text('Status: $attendanceStatus'),
                              ),
                            );
                          },
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
}

class Employee {
  final int id;
  final String firstName;
  final String lastName;
  AttendanceStatus attendanceStatus;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.attendanceStatus,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      attendanceStatus: AttendanceStatus.values.firstWhere(
        (status) => status.toString().split('.').last == json['status'],
        orElse: () => AttendanceStatus.present,
      ),
    );
  }
}

enum AttendanceStatus { present, absent, late }
