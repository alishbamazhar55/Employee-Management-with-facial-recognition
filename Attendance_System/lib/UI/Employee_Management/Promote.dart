import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Define the Employee model to hold employee data

final String? Ip = dotenv.env['IP'];
final String? Port = dotenv.env['PORT'];

final List<String> designations = [
  'Manager',
  'Staff',
  'Finance Manager',
  'Chef',
  'Janitor'
];

class EmployeeManagement extends StatefulWidget {
  const EmployeeManagement({super.key});

  @override
  _EmployeeManagementState createState() => _EmployeeManagementState();
}

class _EmployeeManagementState extends State<EmployeeManagement> {
  List<Employee> employees = []; // Store the list of employees
  bool isLoading = true; // Loading state flag

  // Fetch employee data from the backend
  Future<void> _fetchEmployees() async {
    final url = 'http://$Ip:$Port/promotion'; // Replace with your backend URL
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Parse the response and update the UI
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          employees =
              data.map((employee) => Employee.fromJson(employee)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching employees: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchEmployees(); // Fetch employees when the widget is created
  }

  void _promoteEmployee(Employee employee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PromoteEmployee(employee: employee);
      },
    ).then((_) {
      setState(() {}); // Refresh the UI after promotion
    });
  }

  void _changeSalary(Employee employee) {
    TextEditingController salaryController =
        TextEditingController(text: employee.salary.toString());
    String? errorMessage; // Variable to hold error message

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Change Salary for ${employee.firstName}'),
              content: TextField(
                controller: salaryController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter new salary",
                  errorText:
                      errorMessage, // Display validation message within the box
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: errorMessage == null ? Colors.grey : Colors.red,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: errorMessage == null ? Colors.blue : Colors.red,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    // Check for non-numeric characters or invalid salary format
                    if (RegExp(r'[^0-9.]').hasMatch(value) ||
                        RegExp(r'\.\d*\.\d*').hasMatch(value)) {
                      errorMessage = "Enter a valid salary (numbers only)";
                    } else {
                      errorMessage = null;
                    }
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final inputText = salaryController.text.trim();
                    final newSalary = double.tryParse(inputText);

                    if (newSalary == null) {
                      setState(() {
                        errorMessage = "Enter a valid salary (numbers only)";
                      });
                    } else if (newSalary < 20000 || newSalary > 10000000) {
                      setState(() {
                        errorMessage =
                            "Salary must be between 20,000 & 10,000,000.";
                      });
                    } else {
                      // Update employee salary if valid and within range
                      setState(() {
                        employee.salary = newSalary;
                      });
                      await _updateEmployeeSalary(employee);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("Save"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Function to update the salary in the database
  Future<void> _updateEmployeeSalary(Employee employee) async {
    final url =
        'http://$Ip:$Port/salary_update'; // Replace with the actual endpoint URL
    final data = {
      'email': employee.email,
      'salary': employee.salary, // New Salary
    };

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Salary updated to ${employee.salary.toStringAsFixed(2)}"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error updating salary: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator while fetching
          : Container(
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
                        "Employee Management",
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
                          itemCount: employees.length,
                          itemBuilder: (context, index) {
                            final employee = employees[index];

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
                                        "Salary: ${employee.salary.toStringAsFixed(2)}"),
                                    Text("Email: ${employee.email}"),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () =>
                                              _promoteEmployee(employee),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blueGrey[600],
                                          ),
                                          child: const Text(
                                            "Promote",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              _changeSalary(employee),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blueGrey[600],
                                          ),
                                          child: const Text(
                                            "Change Salary",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
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

class PromoteEmployee extends StatefulWidget {
  final Employee employee;

  const PromoteEmployee({super.key, required this.employee});

  @override
  _PromoteEmployeeState createState() => _PromoteEmployeeState();
}

class _PromoteEmployeeState extends State<PromoteEmployee> {
  String? selectedDesignation;
  final TextEditingController salaryController = TextEditingController();
  String? errorMessage; // To hold validation message

  @override
  void initState() {
    super.initState();
    selectedDesignation = widget.employee.designation;
    salaryController.text = widget.employee.salary.toString();
  }

  @override
  void dispose() {
    salaryController.dispose();
    super.dispose();
  }

  Future<void> _updatePromotion(Employee employee) async {
    final url = 'http://$Ip:$Port/promotion_update';
    final data = {
      'email': employee.email,
      'salary': employee.salary,
      'designation': employee.designation,
    };

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${employee.firstName} has been promoted to $selectedDesignation with a salary of \$${employee.salary.toStringAsFixed(2)}"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error updating promotion: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                  "Promote Employee",
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
                    vertical: screenHeight * 0.03,
                    horizontal: screenWidth * 0.03,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Employee: ${widget.employee.firstName} ${widget.employee.lastName}",
                        style: const TextStyle(fontSize: 20),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        "Select Designation:",
                        style: const TextStyle(fontSize: 18),
                      ),
                      buildDropdown("Select Designation", designations,
                          (value) {
                        setState(() {
                          selectedDesignation = value;
                        });
                      }, selectedDesignation),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        "Enter New Salary:",
                        style: const TextStyle(fontSize: 18),
                      ),
                      TextField(
                        controller: salaryController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Enter salary in PKR",
                          errorText:
                              errorMessage, // Display error in the input box
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (RegExp(r'[^0-9.]').hasMatch(value) ||
                                RegExp(r'\.\d*\.\d*').hasMatch(value)) {
                              errorMessage =
                                  "Enter a valid salary (numbers only)";
                            } else {
                              errorMessage = null;
                            }
                          });
                        },
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      Center(
                        child: MaterialButton(
                          onPressed: () {
                            // Parse and validate the salary input
                            double newSalary =
                                double.tryParse(salaryController.text.trim()) ??
                                    widget.employee.salary;

                            if (newSalary < 20000 || newSalary > 10000000) {
                              setState(() {
                                errorMessage =
                                    "Salary must be between 20,000 & 10,000,000.";
                              });
                              return;
                            }

                            // Update employee data and call the API if valid
                            setState(() {
                              widget.employee.salary = newSalary;
                              widget.employee.designation =
                                  selectedDesignation!;
                            });

                            _updatePromotion(widget.employee);
                            Navigator.of(context).pop();
                          },
                          height: 50,
                          color: Colors.blueGrey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Center(
                            child: Text(
                              "Promote",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
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

  // Build Dropdown Menu with Validation
  Widget buildDropdown(String hintText, List<String> items,
      Function(String?) onChanged, String? selectedValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: hintText,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a $hintText';
          }
          return null;
        },
      ),
    );
  }
}

class Employee {
  final String firstName;
  final String lastName;
  String designation;
  double salary;
  final String email;

  Employee({
    required this.firstName,
    required this.lastName,
    required this.designation,
    required this.salary,
    required this.email,
  });

  // Factory method to create Employee from JSON
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
        firstName: json['first_name'],
        lastName: json['last_name'],
        salary: json['salary'],
        designation: json['designation'],
        email: json['email']);
  }
}
