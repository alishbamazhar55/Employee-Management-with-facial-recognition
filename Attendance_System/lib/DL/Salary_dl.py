from flask import Blueprint, request, jsonify
import DB_config as db
from datetime import datetime
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))
import lib.BL.employee as employeeFunctions 
# from Login import session

# Create a Flask blueprint for salary operations
app = Blueprint('salary', __name__)

# Database configuration
config = db.Configration.get_instance()
connection = config.get_connection()
cursor = connection.cursor()

# Route to fetch all employees with their details (for display in the Flutter UI)
@app.route('/employee_data', methods=['GET'])
def get_employees():
    try:
        selected_date = request.args.get('date')
        print("Value for date is: ", selected_date)
        if selected_date:
            selected_date = datetime.strptime(selected_date, '%Y-%m-%d')
            year = selected_date.year
            month = selected_date.month
            print("Year:", year, "Month:", month)
        else:
            return jsonify({'error': 'Unable to get Date'}), 400
        cursor.execute("""
            SELECT e.Id, e.FirstName, e.LastName, e.SalaryAmount, e.ContactNo, e.IsPaid, l.value, S.PayDate, Incentive, IncentiveDescription
            FROM Employee e
            JOIN EmployeeDesignation d ON e.Id = d.EmployeeId
            JOIN Lookup l ON d.Position = l.Id
            LEFT JOIN Salary S ON S.EmployeeID = e.Id AND MONTH(S.PayDate) = ? AND YEAR(S.PayDate) = ?
            WHERE e.isActive != 24;

        """, (month, year))
        
        employees = cursor.fetchall()
        employee_list = []
        # for emp in employees:
        #    if emp[7] is None:
        #         print("Employee not paid")
        #         cursor.execute('''
        #             UPDATE Employee 
        #             SET IsPaid = 24
        #             WHERE Id = ?
        #         ''', (emp[0]))
        print(employees)
        for emp in employees:
            employee_list.append({
                'id': emp[0],
                'first_name': emp[1],
                'last_name': emp[2],
                'salary': float(emp[3]),
                'contact': emp[4],
                'is_paid': emp[5] if emp[7] is not None else 24,
                'Position': emp[6],
                'pay_date': emp[7],
                'incentive': emp[8],
                'incentiveDescription': emp[9]

            })
        print(employee_list)
        
        return jsonify(employee_list), 200
    
    except Exception as e:
        print(f"Error fetching employees: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/pay_salary', methods=['POST'])
def pay_salary():
    data = request.get_json()

    try:
        # Extract data from the request
        employee_id = data['employee_id']
        salary = data['salary']
        incentive = data.get('incentive', None)
        incentive_description = data.get('incentive_description', None)
        pay_date = data['pay_date']
        paid_by = data['paidBy']  # Or fetch dynamically
        increment_date = datetime.now() if incentive else None

        # Convert pay_date to datetime object
        pay_date = datetime.strptime(pay_date, '%Y-%m-%d').date()

        # Update Employee table to set is_paid to 23
        cursor.execute("""
        UPDATE Employee
        SET IsPaid = 23
        WHERE Id = ?
        """, (employee_id,))

        # Insert salary record into the Salary table
        cursor.execute("""
        INSERT INTO Salary (EmployeeId, PayDate, Incentive, IncentiveDescription, IncrementDate, Paidby)
        VALUES (?, ?, ?, ?, ?, ?)
        """, (employee_id, pay_date, incentive, incentive_description, increment_date, paid_by))

       

        return jsonify({'message': 'Salary paid successfully!'}), 201

    except Exception as e:
        print(f"Error paying salary: {e}")
        connection.rollback()  # Rollback in case of error
        return jsonify({'error': str(e)}), 500






@app.route('/employee_salar', methods=['GET'])
def get_salary_for_employee():
    try:
        employee_id = request.args.get('employeeId')
        
        query = """
            SELECT e.Id, e.FirstName, e.LastName, e.SalaryAmount, e.ContactNo, e.IsPaid, l.value, s.PayDate, s.Incentive
            FROM Employee e
            INNER JOIN EmployeeDesignation d ON e.Id = d.EmployeeId
            JOIN Lookup l ON d.Position = l.Id
            JOIN Salary s ON e.Id = s.EmployeeId
            WHERE s.EmployeeId = ?
        """
        cursor.execute(query, (employee_id,))
        result = cursor.fetchall()

        salary_data = []
        for row in result:
            salary_data.append({
                'id': row[0],
                'first_name': row[1],
                'last_name': row[2],
                'salary': float(row[3]),
                'contact': row[4],
                'is_paid': row[5],
                'Position': row[6],
                'pay_date': row[7],
                'incentive': float(row[8]),
            })

        return jsonify(salary_data), 200

    except Exception as e:
        print(f"Error fetching employees: {e}")
        return jsonify({'error': 'An error occurred fetching salary data.'}), 500




@app.route('/employee_Salary_forManager', methods=['GET'])
def get_employees_Salary_for_manager():
    try:
        # Get month and year from request arguments
        month = request.args.get('month', default=None, type=int)
        year = request.args.get('year', default=None, type=int)

        if month is None or year is None:
            # Fetch all employees and salary data if no month and year are provided
            cursor.execute("""
            SELECT e.Id, e.FirstName, e.LastName, e.SalaryAmount, e.ContactNo, e.IsPaid, l.value, s.PayDate, s.Incentive
            FROM Employee e
            INNER JOIN EmployeeDesignation d ON e.Id = d.EmployeeId
            JOIN Lookup l ON d.Position = l.Id
            JOIN Salary s ON e.Id = s.EmployeeId
            """)
        else:
            # Fetch data for a specific month and year
            cursor.execute("""
            SELECT e.Id, e.FirstName, e.LastName, e.SalaryAmount, e.ContactNo, e.IsPaid, l.value, s.PayDate, s.Incentive
            FROM Employee e
            INNER JOIN EmployeeDesignation d ON e.Id = d.EmployeeId
            JOIN Lookup l ON d.Position = l.Id
            JOIN Salary s ON e.Id = s.EmployeeId
            WHERE MONTH(s.PayDate) = ? AND YEAR(s.PayDate) = ?
            """, (month, year))

        employees = cursor.fetchall()
        employee_list = []

        for emp in employees:
            employee_list.append({
                'id': emp[0],
                'first_name': emp[1],
                'last_name': emp[2],
                'salary': float(emp[3]),
                'contact': emp[4],
                'is_paid': emp[5],
                'Position': emp[6],
                'pay_date': emp[7],
                'incentive': float(emp[8]) if emp[8] is not None else emp[8],
            })

        return jsonify(employee_list), 200

    except Exception as e:
        print(f"Error fetching employees: {e}")
        return jsonify({'error': str(e)}), 500