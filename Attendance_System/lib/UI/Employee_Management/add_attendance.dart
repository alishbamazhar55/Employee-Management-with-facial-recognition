import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String? ip = dotenv.env['IP'];
final String? port = dotenv.env['PORT'];

class MarkAttendance extends StatefulWidget {
  const MarkAttendance({super.key});

  @override
  _MarkAttendanceState createState() => _MarkAttendanceState();
}

class _MarkAttendanceState extends State<MarkAttendance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Employee> employees = [];

  // Get today's date
  final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });

    // Fetch employees from server
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    final response =
        await http.get(Uri.parse('http://$ip:$port/employees?date=$todayDate'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        employees = data.map((json) => Employee.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load employees');
    }
  }

  Future<void> _submitAttendance() async {
    List<Map<String, dynamic>> attendanceData = employees.map((employee) {
      return {
        'employee_id': employee.id,
        'status': employee.attendanceStatus.name,
        'date': todayDate,
      };
    }).toList();

    final response = await http.post(
      Uri.parse('http://$ip:$port/mark_attendance'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(attendanceData),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance successfully marked!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to mark attendance: ${response.body}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.04),
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.03,
                  horizontal: screenWidth * 0.03,
                ),
                child: FadeTransition(
                  opacity: _controller,
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Text(
                          "Mark Employees Attendance",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          "Date: $todayDate",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Container(
                margin: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.03,
                ),
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
                      SizedBox(height: screenHeight * 0.02),
                      SizedBox(
                        height: screenHeight * 0.55,
                        child: FadeTransition(
                          opacity: _controller,
                          child: ListView.builder(
                            itemCount: employees.length,
                            itemBuilder: (context, index) {
                              final animation = Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: const Offset(0, 0),
                              ).animate(
                                CurvedAnimation(
                                  parent: _controller,
                                  curve: Interval(
                                    (index / employees.length),
                                    1.0,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              );

                              Color cardColor = Colors.white;
                              if (employees[index].attendanceStatus ==
                                  AttendanceStatus.absent) {
                                cardColor = Colors.red[100]!;
                              } else if (employees[index].attendanceStatus ==
                                  AttendanceStatus.late) {
                                cardColor = Colors.yellow[100]!;
                              }

                              return SlideTransition(
                                position: animation,
                                child: Card(
                                  color: cardColor,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: Icon(Icons.person,
                                        color: Colors.blueGrey[900]),
                                    title: Text(
                                        "${employees[index].firstName} ${employees[index].lastName}"),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Role: ${employees[index].role}"),
                                        Text(
                                            "Email: ${employees[index].email}"),
                                        Text(
                                            "Shift: ${employees[index].shift}"),
                                        Text(
                                            "Status: ${employees[index].attendanceStatus.name}"),
                                      ],
                                    ),
                                    trailing: DropdownButton<AttendanceStatus>(
                                      value: employees[index].attendanceStatus,
                                      onChanged: (AttendanceStatus? newValue) {
                                        setState(() {
                                          employees[index].attendanceStatus =
                                              newValue!;
                                        });
                                      },
                                      items: AttendanceStatus.values
                                          .map((AttendanceStatus status) {
                                        return DropdownMenuItem<
                                            AttendanceStatus>(
                                          value: status,
                                          child: Text(status.name),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      MaterialButton(
                        onPressed: _submitAttendance,
                        height: 50,
                        color: Colors.blueGrey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Center(
                          child: Text(
                            "Submit Attendance",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
  final String email;
  final String shift;
  final String role;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.attendanceStatus,
    required this.email,
    required this.shift,
    required this.role,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 'Absent') {
      return Employee(
        id: json['id'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        email: json['email'],
        shift: json['shift'],
        role: json['role'],
        attendanceStatus: AttendanceStatus.absent,
      );
    } else if (json['status'] == 'Late') {
      return Employee(
        id: json['id'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        email: json['email'],
        shift: json['shift'],
        role: json['role'],
        attendanceStatus: AttendanceStatus.late,
      );
    } else {
      return Employee(
        id: json['id'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        email: json['email'],
        shift: json['shift'],
        role: json['role'],
        attendanceStatus: AttendanceStatus.present,
      );
    }
  }
}

enum AttendanceStatus { present, absent, late }
