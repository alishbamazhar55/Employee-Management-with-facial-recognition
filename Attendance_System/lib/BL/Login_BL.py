class Login:
    def __init__(self, username, password):
        self.Username = username
        self.Password = password
        self.EmployeeID = None
        self.Position = None

    def authenticate(self, stored_password):
        return self.Password == stored_password

    def set_employee_details(self, employee_id, position):
        self.EmployeeID = employee_id
        self.Position = position

    def redirect_user(self):
        role_redirect_map = {
            'Finance Manager': '/Accountant_dashboard',
            'Manager': '/Manager_dashboard',
            'Staff': '/Employee_Dashboard'
           
            
        }
        return role_redirect_map.get(self.Position)  # Use Position for redirection
