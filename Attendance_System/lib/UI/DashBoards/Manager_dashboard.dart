import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:hotel_management_system/UI/Employee_Management/Promote.dart'
    as promote;
import 'package:hotel_management_system/UI/Employee_Management/PromotionHistory.dart'
    as PromotionHistory;
import 'package:hotel_management_system/UI/Employee_Management/View_salary_manager.dart';
import 'package:hotel_management_system/UI/Employee_Management/add_attendance.dart';
import 'package:hotel_management_system/UI/Employee_Management/View_Attendance_manager.dart';

import 'package:hotel_management_system/UI/Employee_Management/add_employee.dart';
import 'package:hotel_management_system/UI/Employee_Management/emolyee_shift.dart';
import 'package:hotel_management_system/UI/Employee_Management/update_employee.dart';


import 'package:hotel_management_system/UI/main.dart';

class ManagerHomePage extends StatelessWidget {
  final String Name;

  const ManagerHomePage({super.key, required this.Name});

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
                  // Row to place text on the left and image on the right
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: const Row(
                      children: [
                        Text(
                          "Welcome Back",
                          style: TextStyle(color: Colors.white, fontSize: 40),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: screenheight * 0.01,
                  ),
                  FadeInUp(
                    duration: const Duration(milliseconds: 1300),
                    child: Text(
                      Name,
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
                        "Manager's Dashboard",
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
                          childAspectRatio = 15;
                        }
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 1,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: childAspectRatio,
                          children: <Widget>[
                            _buildFunctionalityBox(
                              context,
                              'Add Employee',
                              Icons.person_add,
                              AddEmployeeScreen(),
                            ),
                            _buildFunctionalityBox(
                              context,
                              'Update Employee',
                              Icons.person_search,
                              EmployeeUpdate(),
                            ),
                            _buildFunctionalityBox(
                                context,
                                'Manage Employees Shift',
                                Icons.person_search,
                                const EmployeeShift()),
                            _buildFunctionalityBox(context, 'Mark Attendance',
                                Icons.check_box, const MarkAttendance()
                                // MarkAttendance(),
                                ),
                            _buildFunctionalityBox(
                                context,
                                'View Attendance',
                                Icons.check_box,
                                const ViewAttendanceForManager()
                                // MarkAttendance(),
                                ),
                            
                            _buildFunctionalityBox(
                              context,
                              'Employees Promotion',
                              Icons.trending_up,
                              promote.EmployeeManagement(),
                            ),
                            _buildFunctionalityBox(
                              context,
                              'View Promotion History',
                              Icons.history,
                              PromotionHistory.EmployeeManagementHistory(),

                              // MarkAttendance(),
                            ),
                           
                            _buildFunctionalityBox(context, 'View Salary',
                                Icons.money, const ViewSalaryForManager()),
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
                size: 25,
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey[700],
                  fontSize: 14,
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




//  promotion history