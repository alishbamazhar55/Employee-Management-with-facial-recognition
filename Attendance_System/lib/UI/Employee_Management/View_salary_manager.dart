import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String? Ip = dotenv.env['IP'];
final String? Port = dotenv.env['PORT'];

class ViewSalaryForManager extends StatefulWidget {
  const ViewSalaryForManager({super.key});

  @override
  _ViewSalaryForManagerState createState() => _ViewSalaryForManagerState();
}

class _ViewSalaryForManagerState extends State<ViewSalaryForManager> {
  DateTime? selectedDate;
  List<Employee> employees = [];
  bool isLoading = false; // To show loading indicator

  @override
  void initState() {
    super.initState();
    _fetchEmployeesForSelectedDate(); // Fetch data when the screen loads
  }

  // Function to fetch employees for the selected month and year, or all data if no date is selected
  Future<List<Employee>> fetchEmployees(String? month, String? year) async {
    String url = 'http://$Ip:$Port/employee_Salary_forManager';
    if (month != null && year != null) {
      url += '?month=$month&year=$year';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Employee.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load employee data');
    }
  }

  // Function to select a date and fetch employees
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      _fetchEmployeesForSelectedDate();
    }
  }

  // Fetch employees based on selected month and year, or all if no date selected
  void _fetchEmployeesForSelectedDate() async {
    String? month;
    String? year;

    if (selectedDate != null) {
      month = DateFormat('MM').format(selectedDate!);
      year = DateFormat('yyyy').format(selectedDate!);
    }

    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      List<Employee> fetchedEmployees = await fetchEmployees(month, year);
      setState(() {
        employees = fetchedEmployees;
      });
    } catch (e) {
      print('Error fetching employee data: $e');
      // Optionally show a Snackbar or AlertDialog for errors
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = selectedDate != null
        ? DateFormat('yyyy-MM').format(selectedDate!)
        : 'All Salary History'; // Show 'All Salary History' when no date is selected
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
                  "Manage Salaries",
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
                            child: const Text('Pick a Date',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // If loading, show a CircularProgressIndicator
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (employees.isEmpty)
                        const Center(
                            child: Text(
                                'No employees found for the selected date'))
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: employees.length,
                            itemBuilder: (context, index) {
                              final employee = employees[index];
                              final salary =
                                  employee.salary?.toStringAsFixed(2);
                              final incentive =
                                  employee.incentive?.toStringAsFixed(2);
                              final payDate = employee.payDate;

                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
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
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Salary: \$ $salary'),
                                      Text('Contact: ${employee.contact}'),
                                      Text('Incentive: \$ $incentive'),
                                      Text(
                                          'Designation: ${employee.designation}'),
                                      Text('Pay Date: $payDate'),
                                    ],
                                  ),
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
