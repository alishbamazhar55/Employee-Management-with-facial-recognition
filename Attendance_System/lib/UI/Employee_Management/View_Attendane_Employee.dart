import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String? ip = dotenv.env['IP'];
final String? port = dotenv.env['PORT'];

class ViewAttendanceForEmployee extends StatefulWidget {
  const ViewAttendanceForEmployee({super.key});

  @override
  _ViewAttendanceForEmployeeState createState() =>
      _ViewAttendanceForEmployeeState();
}

class _ViewAttendanceForEmployeeState extends State<ViewAttendanceForEmployee> {
  List<Map<String, dynamic>> attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    try {
      // Retrieve the employeeId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? employeeId = prefs.getInt('employeeId');

      // Call the backend API with the employeeId
      final response = await http.get(
        Uri.parse(
            'http://$ip:$port/employee/attendance?employeeId=$employeeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // If the request is successful, update the UI with the attendance data
        List<dynamic> data = json.decode(response.body);
        setState(() {
          attendanceRecords = List<Map<String, dynamic>>.from(data);
        });
      } else {
        // Handle the case where the request fails
        print('Failed to load attendance data');
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
                  "Your Attendance",
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
                  child: ListView.builder(
                    itemCount: attendanceRecords.length,
                    itemBuilder: (context, index) {
                      final record = attendanceRecords[index];
                      final date = record['date'];
                      final status = record['attendance_status'];
                      final shift = record['shift'];
                      final position = record['role'];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.date_range,
                            color: Colors.blueGrey[700],
                          ),
                          title: Text("Date: $date"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Shift: $shift"),
                              Text("Role: $position"),
                              Text("Status: $status"),
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
