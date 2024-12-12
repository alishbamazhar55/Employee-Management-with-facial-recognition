from datetime import datetime
import re

class Employee:
    def __init__(self, first_name, last_name, email, cnic, phone_number, salary, username, password, designation, shift, dob, addedBy,profilePicture, isActive=23,  updatedBy=None,  isPaid=24, promotionId=None, promotionDate=None):
        self.first_name = self.validate_name(first_name, 'FirstName')
        self.last_name = self.validate_name(last_name, 'LastName', allow_null=True)
        self.email = self.validate_email(email)
        self.cnic = self.validate_cnic(cnic)
        self.phone_number = self.validate_contact(phone_number)
        self.salary = self.validate_salary(float(salary))
        self.username = username
        self.password = password
        self.designation = designation
        self.shift = self.validate_shift(shift)
        self.dob = self.validate_dob(dob)  # Pass dob as a string in 'YYYY-MM-DD' format
        self.isActive = self.validate_isActive(isActive)
        self.addedBy = addedBy
        self.updatedBy = updatedBy
        self.profilePicture = profilePicture
        self.isPaid = self.validate_isPaid(isPaid)
        self.promotionId = promotionId
        self.promotionDate = promotionDate

    def validate_name(self, name, field_name, allow_null=False):
        if allow_null and name is None:
            return None
        if not re.match("^[a-zA-Z]+$", name):
            raise ValueError(f"{field_name} must contain alphabetic characters only.")
        return name

    def validate_email(self, email):
        if not re.match(r"^[\w\.-]+@[\w\.-]+\.\w+$", email):
            raise ValueError("Invalid email format.")
        return email

    def validate_cnic(self, cnic):
        if not (cnic.isdigit() and len(cnic) == 13):
            raise ValueError("CNIC must contain exactly 13 digits.")
        return cnic

    def validate_contact(self, contact):
        if not (contact.isdigit() and len(contact) == 11):
            raise ValueError("ContactNo must contain exactly 11 digits.")
        return contact

    def validate_salary(self, salary):
        if not (20000 <= salary <= 10000000):
            raise ValueError("SalaryAmount must be between 20,000 and 10,000,000.")
        return salary

    def validate_shift(self, shift):
        shift_code = ShiftCode(shift)
        if shift_code == 0:
            raise ValueError("Invalid shift. Choose from 'Morning', 'Afternoon', or 'Night'.")
        return shift_code

    def validate_dob(self, dob):
        try:
            # Handle ISO format with timestamp
            dob = datetime.fromisoformat(dob)  # Converts ISO format date to datetime
            if dob >= datetime.now():
                raise ValueError("DOB cannot be in the future.")
        except ValueError:
            raise ValueError("DOB must be in a valid date format and cannot be in the future.")
        return dob

    def validate_isActive(self, isActive):
        if isActive not in [23, 24]:  # Assuming these IDs map to active statuses in Lookup table
            raise ValueError("Invalid isActive value.")
        return isActive

    def validate_isPaid(self, isPaid):
        if isPaid not in [23, 24]:  # Assuming these IDs map to payment statuses in Lookup table
            raise ValueError("Invalid isPaid value.")
        return isPaid


def ShiftCode(shift):
    if shift == 'Morning':
        return 20
    elif shift == 'Afternoon':
        return 21
    elif shift == 'Night':
        return 22
    else:
        return 0

class User:
    def __init__(self, employeeId, username, password):
        self.employeeId = employeeId
        self.username = username
        self.password = password

class Designation:
    def __init__(self, employeeId, position, promotionId=None, promotionDate=None):
        self.employeeId = employeeId
        self.promotionId = promotionId
        self.promotionDate = promotionDate
        self.position = getPositionCode(position)
    
def getPositionCode(position):
    if position == 'Manager':
        return 16
    elif position == 'Staff':
        return 15
    elif position == 'Finance Manager':
        return 17
    elif position == 'Janitor':
        return 19
    elif position == 'Chef':
        return 18
    else:
        return 0
    
def getAttendanceCode(attendance):
    if attendance.lower() == 'present':
        return 25
    elif attendance.lower() == 'absent':
        return 26
    elif attendance.lower() == 'late':
        return 27
    else:
        return 0
