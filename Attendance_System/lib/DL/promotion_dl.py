from flask import Blueprint, jsonify, request
import DB_config as db
import os
from dotenv import load_dotenv
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

# Create a Flask blueprint
app = Blueprint('Promotion', __name__)

# Database configuration
config = db.Configration.get_instance()
connection = config.get_connection()
cursor = connection.cursor()

@app.route('/promotion', methods=['GET'])
def get_employees():
    try:
        # Execute the SQL query to get the employee data
        cursor.execute("""
            select e.FirstName, e.LastName,e.SalaryAmount,l.Value as Position,e.Email
            from Employee e 
            join EmployeeDesignation ed on e.Id=ed.EmployeeId
            join Lookup l on l.Id=ed.Position
            WHERE e.isActive = 23
        """)
        
        # Fetch all the results
        employees = cursor.fetchall()

        # Prepare the response data
        employee_list = []
        for emp in employees:
            employee_list.append({
                'first_name': emp[0],
                'last_name': emp[1],
                'salary': float(emp[2]),
                'designation': emp[3],
                'email': emp[4],
            })

        # Return the employee data as JSON
        return jsonify(employee_list), 200
    except Exception as e:
        print(f"Error fetching employees: {e}")
        return jsonify({'error': str(e)}), 500
    
@app.route('/promotion_update', methods=['PUT'])
def update_promotion():
    try:
        # Get the data from the request
        data = request.get_json()
        
        # Ensure all required fields are present
        if not all(key in data for key in ['email', 'salary', 'designation']):
            return jsonify({'error': 'Missing required fields'}), 400

        employee_email = data['email']
        new_salary = data['salary']
        new_designation = data['designation']

        # Print the received data for debugging
        print(f"Updating promotion for employee {employee_email} with new salary: {new_salary} and new designation: {new_designation}")

        # Execute the SQL query to update the employee's salary in the Employee table
        cursor.execute("""
            UPDATE Employee 
            SET SalaryAmount = ? 
            WHERE Email = ?
        """, (new_salary, employee_email))

        # Retrieve the employee's ID based on the email
        cursor.execute("""
            SELECT Id FROM Employee WHERE Email = ?
        """, (employee_email,))
        employee_id = cursor.fetchone()

        # Check if employee ID was found
        if not employee_id:
            return jsonify({'error': 'Employee not found'}), 404

        # Extract the actual ID from the result tuple
        employee_id = employee_id[0]

        # Execute the SQL query to update the employee's designation in the EmployeeDesignation table
        cursor.execute("""
                UPDATE EmployeeDesignation
                SET Position = (SELECT Id FROM Lookup WHERE Value = ?),
                    PromotionDate = GETDATE()  -- This updates the datetime column with the current date and time
                WHERE EmployeeId = ?
            """, (new_designation, employee_id))




        # Commit the transaction
        connection.commit()

        return jsonify({'message': 'Employee promotion updated successfully'}), 200

    except Exception as e:
        print(f"Error updating employee promotion: {e}")
        return jsonify({'error': str(e)}), 500





@app.route('/salary_update', methods=['PUT'])
def update_salary():
    try:
        # Get the data from the request
        data = request.get_json()
        
        # Ensure all required fields are present
        if not all(key in data for key in ['email', 'salary']):
            return jsonify({'error': 'Missing required fields'}), 400

        employee_email = data['email']
        new_salary = data['salary']
     

        # Print the received data for debugging
        print(f"Updating promotion for employee {employee_email} with new salary: {new_salary}")

        # Execute the SQL query to update the employee's salary in the Employee table
        cursor.execute("""
            UPDATE Employee 
            SET SalaryAmount = ? 
            WHERE Email = ?
        """, (new_salary, employee_email))

        # Commit the transaction
        connection.commit()

        return jsonify({'message': 'Employee promotion updated successfully'}), 200

    except Exception as e:
        print(f"Error updating employee promotion: {e}")
        return jsonify({'error': str(e)}), 500
