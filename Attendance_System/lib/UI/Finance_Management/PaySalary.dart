import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String? Ip = dotenv.env['IP'];
final String? Port = dotenv.env['PORT'];

class PaySalaryForManager extends StatefulWidget {
  const PaySalaryForManager({super.key});

  @override
  _PaySalaryForManagerState createState() => _PaySalaryForManagerState();
}

class _PaySalaryForManagerState extends State<PaySalaryForManager> {
  DateTime selectedDate = DateTime.now();
  List<Employee> employees = [];

  @override
  void initState() {
    super.initState();
    _fetchEmployeesForSelectedDate();
  }

  // Fetch employee data for the selected date
  Future<void> _fetchEmployeesForSelectedDate() async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    List<Employee> employeeList = await fetchEmployees(formattedDate);
    setState(() {
      employees = employeeList;
    });
  }

  // Fetch employee data from the API according to date
  Future<List<Employee>> fetchEmployees(String date) async {
    final response =
        await http.get(Uri.parse('http://$Ip:$Port/employee_data?date=$date'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data
          .map((employeeJson) => Employee.fromJson(employeeJson))
          .toList();
    } else {
      throw Exception('Failed to load employee data');
    }
  }

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
      });
      _fetchEmployeesForSelectedDate(); // Fetch employees for the new date
    }
  }

  void _showBonusDialog(BuildContext context, int index) {
    final TextEditingController bonusController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? bonusErrorText;
    String? descriptionErrorText;
    double maxBonus = employees[index].salary;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Real-time validation function for bonus input
            void validateBonus(String value) {
              final double? bonus = double.tryParse(value);
              if (value.isEmpty || bonus == null || bonus <= 0) {
                bonusErrorText = 'Please enter a valid bonus amount';
              } else if (bonus > maxBonus) {
                bonusErrorText = 'Bonus cannot exceed the salary amount';
              } else {
                bonusErrorText = null; // No error
              }
            }

            // Real-time validation function for description input
            void validateDescription(String value) {
              if (value.isEmpty) {
                descriptionErrorText = 'Description is required';
              } else {
                descriptionErrorText = null; // No error
              }
            }

            return AlertDialog(
              title: const Text('Enter Bonus Amount and Description'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: bonusController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        validateBonus(value);
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Bonus Amount',
                      errorText: bonusErrorText,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              bonusErrorText == null ? Colors.grey : Colors.red,
                          width: 0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              bonusErrorText == null ? Colors.blue : Colors.red,
                          width: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    onChanged: (value) {
                      setState(() {
                        validateDescription(value);
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Incentive Description',
                      errorText: descriptionErrorText,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: descriptionErrorText == null
                              ? Colors.grey
                              : Colors.red,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: descriptionErrorText == null
                              ? Colors.blue
                              : Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final double? bonus = double.tryParse(bonusController.text);
                    final String description = descriptionController.text;
                    setState(() {
                      // Final validation before adding bonus
                      if (bonusErrorText == null &&
                          descriptionErrorText == null) {
                        employees[index].addBonus(bonus!, description);
                        Navigator.of(context).pop(); // Close the dialog
                      }
                    });
                  },
                  child: const Text('Add Bonus'),
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
    String formattedDate = DateFormat('yyyy-MM').format(selectedDate);
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
                            child: const Text('Pick a Date',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Expanded(
                        child: employees.isEmpty
                            ? Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                itemCount: employees.length,
                                itemBuilder: (context, index) {
                                  final employee = employees[index];
                                  final salary =
                                      employee.salary.toStringAsFixed(2);

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    color: employee.paid == 23
                                        ? Colors.green[100]
                                        : Colors.white,
                                    child: ListTile(
                                      leading: Icon(Icons.person,
                                          color: Colors.blueGrey[700]),
                                      title: Text(
                                          '${employee.firstName} ${employee.lastName}'),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Salary: \$ $salary'),
                                          Text(
                                              'Designation: ${employee.position}'),
                                           if (employee.incentive != null)
                                            Text(
                                                'Incentive: ${employee.incentive}',
                                                style: TextStyle(
                                                    color: Colors.green)),
                                          if (employee.incentiveDescription !=
                                              null)
                                            Text(
                                                'Incentive Note: ${employee.incentiveDescription}',
                                                style: TextStyle(
                                                    color: Colors.green)),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton(
                                            onPressed: employee.paid == 23
                                                ? null
                                                : () async {
                                                    SharedPreferences prefs =
                                                        await SharedPreferences
                                                            .getInstance();
                                                    int? employeeId = prefs
                                                        .getInt('employeeId');

                                                    if (employeeId != null) {
                                                      final response =
                                                          await http.post(
                                                        Uri.parse(
                                                            'http://$Ip:$Port/pay_salary'),
                                                        headers: <String,
                                                            String>{
                                                          'Content-Type':
                                                              'application/json; charset=UTF-8',
                                                        },
                                                        body:
                                                            jsonEncode(<String,
                                                                dynamic>{
                                                          'employee_id':
                                                              employee.id,
                                                          'salary':
                                                              employee.salary,
                                                          'incentive': employee
                                                                      .incentiveDescription !=
                                                                  null
                                                              ? employee
                                                                      .salary -
                                                                  employee
                                                                      .baseSalary
                                                              : null,
                                                          'incentive_description':
                                                              employee
                                                                  .incentiveDescription,
                                                          'pay_date': DateFormat(
                                                                  'yyyy-MM-dd')
                                                              .format(
                                                                  selectedDate),
                                                          'paidBy': employeeId,
                                                        }),
                                                      );

                                                      if (response.statusCode ==
                                                          201) {
                                                        setState(() {
                                                          employee.paid = 23;
                                                        });
                                                      } else {
                                                        print(
                                                            'Failed to pay salary: ${response.body}');
                                                      }
                                                    }
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  employee.paid == 23
                                                      ? Colors.green[200]
                                                      : Colors.blueGrey[600],
                                            ),
                                            child: Text(
                                                employee.paid == 23
                                                    ? 'Paid'
                                                    : 'Pay',
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: employee.paid == 23
                                                ? null
                                                : () => _showBonusDialog(
                                                    context, index),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blueGrey[600],
                                            ),
                                            child: const Text('Bonus',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
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

// Employee class with factory constructor for API data
class Employee {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? contact;

  final String? position; // Assuming this is the designation
  double salary;
  int? paid; // Keep it as an integer
  String? incentiveDescription; // Add this field for incentive description
  double baseSalary; // field for the base salary
  int? paidBy;
  double? incentive;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.contact,
    required this.position,
    required this.salary,
    required this.paid,
    required this.baseSalary,
    this.incentiveDescription,
    required this.paidBy,
    this.incentive,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      contact: json['contact'],
      position: json['Position'],
      salary: json['salary'],
      paid: json['is_paid'],
      baseSalary: json['salary'],
      paidBy: json['paidBy'], // Assuming base salary is in the API
      incentiveDescription: json['incentiveDescription'],
      incentive: json['incentive'] != null
          ? double.parse(json['incentive'].toString())
          : null,
    );
  }

  // Function to add bonus to the employee's salary
  void addBonus(double bonus, String description) {
    salary += bonus;
    incentiveDescription = description;
  }
}