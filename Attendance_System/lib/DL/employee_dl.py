from flask import Blueprint, Flask, current_app, request, jsonify,current_app
import DB_config as db
import os
from dotenv import load_dotenv
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

from lib.BL.employee import Employee, User, Designation
import lib.BL.employee as employeeFunctions
from datetime import datetime

# Database configuration
config = db.Configration.get_instance()
connection = config.get_connection()
cursor = connection.cursor()

# Create blueprint
app = Blueprint('employee_dl', __name__)

def get_upload_folder():
    upload_folder = current_app.config.get('Uploaded_Pictures', os.path.join(os.getcwd(), 'images'))
    if not os.path.exists(upload_folder):
        os.makedirs(upload_folder)
    return upload_folder

@app.route('/upload', methods=['POST'])
def upload_image():
    print("hello alisba")
    if 'file' not in request.files:
        print("hello fasi")
        return jsonify({'error': 'No file provided'}), 400
    print("123")

    file = request.files['file']
     
    print("hello f")
    if file.filename == '':
        print("1")
       
        return jsonify({'error': 'No selected file'}), 400
   

    try:
        print("Hello")
        upload_folder = get_upload_folder()
        print("Hello girl")
        file_path = os.path.join(upload_folder, file.filename)
        print("h")

        file.save(file_path)
        print(file)
        print("Hello kitty")
        return jsonify({'message': f'File saved successfully at {file_path}'}), 200
    except Exception as e:
        return jsonify({'error': f'Failed to save file: {e}'}), 500



@app.route('/employee', methods=['POST'])
def add_employee():
    try:
        data = request.json
        print(f"Received data: {data}")  # Log incoming data

        # Check if all required fields are present
        required_fields = ['first_name',  'email', 'cnic', 'phone_number','dob' ,'salary','shift' ,'username', 'password', 'designation', 'shift']
        if not all(key in data for key in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400

        # Extract the employee data
        first_name = data['first_name']
        last_name = data['last_name']
        email = data['email']
        cnic = data['cnic']
        phone_number = data['phone_number']
        salary = data['salary']
        username = data['username']
        password = data['password']
        designation = data['designation']
        shift = data['shift']
        dob = data.get('dob')
        addedBy = data.get('addedBy')
        profilePicture = data.get('ProfilePhoto')


        # Create Employee object
        employee = Employee(first_name, last_name, email, cnic, phone_number, salary, username, password, designation, shift, dob, addedBy,profilePicture)
        # Insert employee into the database
        cursor.execute(
            """INSERT INTO Employee (FirstName, LastName, CNIC,  ContactNo, Email, ProfilePhoto, DOB, Shift, IsActive, SalaryAmount, Ispaid, Addedby, Updatedby) 
            OUTPUT INSERTED.Id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?, ?)""",
            (employee.first_name, employee.last_name,employee.cnic , employee.phone_number,employee.email, employee.profilePicture, employee.dob, employee.shift, employee.isActive, employee.salary, employee.isPaid, employee.addedBy, employee.updatedBy)
        
        )
        employeeId = cursor.fetchone()[0]

        user = User(employeeId, username, password)
        cursor.execute("""
        INSERT INTO Users
        (EmployeeID, Username, Password) 
        VALUES (?, ?, ?)
        """, 
        (employeeId, user.username, user.password)
        )

        designationObj = Designation(employeeId, designation)
        cursor.execute("""
        INSERT INTO EmployeeDesignation
        (EmployeeId, Position,  PromotionDate) 
        VALUES (?, ?, ?)
        """, 
        (designationObj.employeeId, designationObj.position, designationObj.promotionDate)
        )

        connection.commit()


        return jsonify({'message': 'Employee added successfully!'}), 201
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500
    

@app.route('/employees', methods=['GET'])
def get_employees():
    try:
        cursor.execute('''SELECT E.Id, FirstName, LastName, Email, l.Value as Shift, l2.Value as Role 
                       FROM Employee E 
                       JOIN Lookup l ON l.Id = E.Shift 
                       JOIN EmployeeDesignation ED ON ED.EmployeeId = E.Id 
                       JOIN Lookup l2 ON ED.Position = l2.Id 
                       WHERE isActive != 24''')
        employees = cursor.fetchall()

        employee_list = []
        for emp in employees:
            employee_list.append({
                'id': emp[0],
                'first_name': emp[1],
                'last_name': emp[2],
                'email': emp[3],
                'shift': emp[4],
                'role': emp[5]
            })

        return jsonify(employee_list), 200
    except Exception as e:
        print(f"Error fetching employees: {e}")
        return jsonify({'error': str(e)}), 500



@app.route('/employee/<int:employee_id>', methods=['PUT'])
def update_employee(employee_id):
    try:
        data = request.json
        print(f"Updating employee {employee_id} with data: {data}")

        # Check if all required fields are present
        required_fields = ['first_name', 'last_name', 'email', 'shift', 'role']
        if not all(key in data for key in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400

        # Extract the updated employee data
        first_name = data['first_name']
        last_name = data['last_name']
        email = data['email']
        shift = employeeFunctions.ShiftCode(data['shift'])
        print(f"Role: {data['role']}")
        role = employeeFunctions.getPositionCode(data['role'])
        username = data['username']
        password = data['password']
        updatedBy = data.get('updatedBy')
        updatedDate = datetime.now()
        # Update employee information in the Employee table
        cursor.execute(
            """UPDATE Employee 
               SET FirstName=?, LastName=?, Email=?, Shift=?, Updatedby=? 
               WHERE Id=?""",
            (first_name, last_name, email, shift, updatedBy ,employee_id)
        )

        if role != 0:
            # Update employee role in the EmployeeDesignation table
            cursor.execute(
                """UPDATE EmployeeDesignation 
                SET Position=? 
                WHERE EmployeeId=?""",
                (role, employee_id)
            )

        # Update user credentials in the Users table
        if username and password:
            cursor.execute(
                """UPDATE Users 
                SET Username=?, Password=?, UpdateDate=?
                WHERE EmployeeID=?""",
                (username, password,updatedDate ,employee_id)
            )

        # Commit the changes to the database
        connection.commit()

        return jsonify({'message': 'Employee updated successfully!'}), 200
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500
    

@app.route('/employee/<int:employee_id>', methods=['DELETE'])
def delete_employee(employee_id):
    try:
        # Set isActive to 24 to mark employee as deleted
        cursor.execute(
            """UPDATE Employee 
               SET IsActive=? 
               WHERE Id=?""",
            (24, employee_id)
        )

        # Commit the changes to the database
        connection.commit()

        return jsonify({'message': 'Employee deleted (soft delete) successfully!'}), 200
    except Exception as e:
        print(f"Error deleting employee: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/mark_attendance', methods=['POST'])
def mark_attendance():
    try:
        # Get data from the request
        data = request.json
        print(f"Received attendance data: {data}")  # Log incoming data

        # Loop through each attendance record in the list
        for record in data:
            # Extract data from the record
            employee_id = record['employee_id']
            status = employeeFunctions.getAttendanceCode(record['status'])  # Expected values: 'present', 'absent', 'late'
            date = record['date']      # Date format expected as 'yyyy-mm-dd'
            
            try:
                # Parse the date string into a date object
                date = datetime.strptime(date, '%Y-%m-%d')
                attendance_date = date.date()
            except ValueError:
                return jsonify({'error': 'Invalid date format. Use yyyy-mm-dd'}), 400

            # Check if an attendance record already exists for the employee on the specified date
            cursor.execute(
                """SELECT COUNT(*) FROM Attendance 
                   WHERE EmployeeID = ? AND Date = ?""",
                (employee_id, attendance_date)
            )
            record_exists = cursor.fetchone()[0] > 0

            # Insert or update attendance
            if record_exists:
                # Update existing record
                cursor.execute(
                    """UPDATE Attendance 
                        SET AttendanceStatus = ?
                        WHERE EmployeeId = ? AND Date = ?""",
                    (status, employee_id, attendance_date)
                )
            else:
                # Insert new attendance record
                cursor.execute(
                    """INSERT INTO Attendance (EmployeeId, Date, AttendanceStatus, CheckInTime, CheckOutTime) 
                       VALUES (?, ?, ?, ?, ?)""",
                    (employee_id, attendance_date, status, datetime.now(), None)
                )
            # Commit transaction for each record
            connection.commit()

    except Exception as e:
        print(f"Error in marking attendance: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/employees', methods=['GET'])
def get_employees_attendance():
    try:
        selected_date = request.args.get('date')
        if selected_date:
            selected_date = datetime.strptime(selected_date, '%Y-%m-%d')
        else:
            return jsonify({'error': 'Unable to get Date'}), 400
        cursor.execute('''
            SELECT E.Id, FirstName, LastName, Email, l.Value as Shift, l2.Value as Role, l3.Value as AttendanceStatus 
            FROM Employee E 
            JOIN Lookup l ON l.Id = E.Shift 
            JOIN EmployeeDesignation ED ON ED.EmployeeId = E.Id 
            JOIN Lookup l2 ON ED.Position = l2.Id 
            JOIN Attendance att ON att.EmployeeID = E.Id
            JOIN Lookup l3 ON att.AttendanceStatus = l3.Id
            WHERE isActive != 24 and att.Date = ?
        ''', (selected_date,))
        employees = cursor.fetchall()

        if employees is None:
            cursor.execute('''SELECT E.Id, FirstName, LastName, Email, l.Value as Shift, l2.Value as Role 
                       FROM Employee E 
                       JOIN Lookup l ON l.Id = E.Shift 
                       JOIN EmployeeDesignation ED ON ED.EmployeeId = E.Id 
                       JOIN Lookup l2 ON ED.Position = l2.Id 
                       WHERE isActive != 24''')
            employees = cursor.fetchall()


        employee_list = []
        for emp in employees:
            employee_list.append({
                'id': emp[0],
                'first_name': emp[1],
                'last_name': emp[2],
                'email': emp[3],
                'shift': emp[4],
                'role': emp[5],
                'attendance_status': emp[6] if len(emp) > 6 else 'Absent'
            })


        return jsonify(employee_list), 200
    except Exception as e:
        print(f"Error fetching employees: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/attendance', methods=['GET'])
def get_attendance_forManager():
    try:
        selected_date = request.args.get('date')
        print(f"Selected Date: {selected_date}")
        if selected_date:
            selected_date = datetime.strptime(selected_date, '%Y-%m-%d')
        else:
            return jsonify({'error': 'Unable to get Date'}), 400
        cursor.execute('''
            SELECT E.Id, FirstName, LastName, Email, l.Value as Shift, l2.Value as Role, l3.Value as AttendanceStatus 
            FROM Employee E 
            JOIN Lookup l ON l.Id = E.Shift 
            JOIN EmployeeDesignation ED ON ED.EmployeeId = E.Id 
            JOIN Lookup l2 ON ED.Position = l2.Id 
            JOIN Attendance att ON att.EmployeeID = E.Id
            JOIN Lookup l3 ON att.AttendanceStatus = l3.Id
            WHERE isActive != 24 and att.Date = ?
        ''', (selected_date,))
        employees = cursor.fetchall()

        if employees is None:
            return jsonify({'error': 'No attendance records found'}), 404

        employee_list = []
        for emp in employees:
            employee_list.append({
                'id': emp[0],
                'first_name': emp[1],
                'last_name': emp[2],
                'email': emp[3],
                'shift': emp[4],
                'role': emp[5],
                'attendance_status': emp[6] if len(emp) > 6 else 'Absent'
            })


        return jsonify(employee_list), 200
    except Exception as e:
        print(f"Error fetching employees: {e}")
        return jsonify({'error': str(e)}), 500
    

@app.route('/employee/attendance', methods=['GET'])
def get_attendance_forEmployee():
    print("Getting attendance for employee")
    try:
        id = request.args.get('employeeId')
        print(f"Employee ID: {id}")
        if id is None:
            return jsonify({'error': 'Unable to get Id'}), 400
        cursor.execute('''
            SELECT E.Id, FirstName, LastName, Email, l.Value as Shift, l2.Value as Role, l3.Value as AttendanceStatus, att.Date
            FROM Employee E 
            JOIN Lookup l ON l.Id = E.Shift 
            JOIN EmployeeDesignation ED ON ED.EmployeeId = E.Id 
            JOIN Lookup l2 ON ED.Position = l2.Id 
            JOIN Attendance att ON att.EmployeeID = E.Id
            JOIN Lookup l3 ON att.AttendanceStatus = l3.Id
            WHERE isActive != 24 and E.Id = ? 
        ''', (id))
        employees = cursor.fetchall()

        if employees is None:
            return jsonify({'error': 'No attendance records found'}), 404

        employee_list = []
        for emp in employees:
            employee_list.append({
                'id': emp[0],
                'first_name': emp[1],
                'last_name': emp[2],
                'email': emp[3],
                'shift': emp[4],
                'role': emp[5],
                'attendance_status': emp[6] if len(emp) > 6 else 'Absent',
                'date': emp[7].strftime('%Y-%m-%d')
            })


        return jsonify(employee_list), 200
    except Exception as e:
        print(f"Error fetching employees: {e}")
        return jsonify({'error': str(e)}), 500
    
@app.route('/employee/shift', methods=['GET'])
def get_employee_shift():
    try:
        shift = request.args.get('shift')
        print(f"Shift: {shift}")

        if shift is "":
            cursor.execute('''   
                select FirstName, LastName, Email, l1.Value as role, l2.Value as shift
                from Employee E
                JOIN EmployeeDesignation ED ON ED.EmployeeID = E.Id
                JOIN Lookup l1 ON ED.Position = L1.Id
                JOIN Lookup l2 ON E.Shift = l2.Id
                WHERE IsActive != 24

                            ''')
            employees = cursor.fetchall()
            print(f"Employees: {employees}")
        else:
            cursor.execute('''   
                select FirstName, LastName, Email, l1.Value as role, l2.Value as shift
                from Employee E
                JOIN EmployeeDesignation ED ON ED.EmployeeID = E.Id
                JOIN Lookup l1 ON ED.Position = L1.Id
                JOIN Lookup l2 ON E.Shift = l2.Id
                WHERE IsActive != 24 AND E.Shift = ?
                        ''', (employeeFunctions.ShiftCode(shift),))
            employees = cursor.fetchall()
        
        employee_list = []
        for emp in employees:
            employee_list.append({

                'first_name': emp[0],
                'last_name': emp[1],
                'email': emp[2],
                'role': emp[3],
                'shift': emp[4],
            })
        return jsonify(employee_list), 200
    except Exception as e:
        print(f"Error fetching employees: {e}")
        return jsonify({'error': str(e)}), 500