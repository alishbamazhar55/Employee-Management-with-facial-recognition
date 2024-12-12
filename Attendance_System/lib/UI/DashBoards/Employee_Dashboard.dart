import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:hotel_management_system/UI/Employee_Management/View_Attendane_Employee.dart'
    as attendance;
import 'package:hotel_management_system/UI/Employee_Management/View_salary_Employee.dart '
    as salary;

import 'package:hotel_management_system/UI/main.dart';

// import 'package:hotel_management_system/DL/login.py';
class EmployeeHomePage extends StatelessWidget {
  final String managerName;

  const EmployeeHomePage({super.key, required this.managerName});

  @override
  Widget build(BuildContext context) {
    double screenheight = MediaQuery.of(context).size.height;
    double screenwidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, colors: [
            Colors.blueGrey[900] ?? Colors.blueGrey,
            Colors.blueGrey[700] ?? Colors.blueGrey,
            Colors.blueGrey[400] ?? Colors.blueGrey,
          ]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: screenheight * 0.03,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: screenheight * 0.01,
                  horizontal: screenwidth * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: const Text(
                      "Welcome Back",
                      style: TextStyle(color: Colors.white, fontSize: 40),
                    ),
                  ),
                  SizedBox(
                    height: screenheight * 0.01,
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1300),
                    child: Text(
                      managerName,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  SizedBox(
                    height: screenheight * 0.01,
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1300),
                    child: const Center(
                      child: Text(
                        "Employee's Dashboard",
                        style: TextStyle(color: Colors.white, fontSize: 30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenheight * 0.02),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(
                    vertical: screenheight * 0.00,
                    horizontal: screenwidth * 0.00),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: screenheight * 0.02,
                        horizontal: screenwidth * 0.05),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double childAspectRatio;
                        if (constraints.maxWidth < 600) {
                          childAspectRatio = 6.5;
                        } else {
                          childAspectRatio = 15; // Smaller ratio for desktops
                        }
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 1,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: childAspectRatio, // Adjusted ratio
                          children: <Widget>[
                            _buildFunctionalityBox(
                              context,
                              'View Attendance',
                              Icons.assignment,
                              attendance.ViewAttendanceForEmployee(),
                            ),
                            _buildFunctionalityBox(
                              context,
                              'View Salary',
                              Icons.money,
                              salary
                                  .ViewSalaryForEmployee(), // No employeeId passed here
                            ),
                            _buildFunctionalityBox(
                              context,
                              'LogOut',
                              Icons.logout,
                              HomePage(),
                              // MarkAttendance(),
                            ),
                          ],
                        );
                      },
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

  Widget _buildFunctionalityBox(
    BuildContext context,
    String title,
    IconData icon,
    Widget destinationPage,
  ) {
    return FadeInUp(
      duration: const Duration(milliseconds: 1000),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destinationPage),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey[300] ?? Colors.blueGrey,
                blurRadius: 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                color: Colors.blueGrey[700],
                size: 25, // Reduced icon size
              ),
              const SizedBox(height: 5), // Reduced gap
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey[700],
                  fontSize: 14, // Reduced text size
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
