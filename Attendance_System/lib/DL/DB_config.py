import pyodbc
class Configration:
    _instance = None
    def __init__(self):
        self.connect_str = (
            'DRIVER={ODBC Driver 17 for SQL Server};'
            'SERVER=localhost;'
            'DATABASE=Attendance_System;'
            'Trusted_Connection=yes;'
        )
        self.connection = pyodbc.connect(self.connect_str)
    @classmethod 
    # Returns a singleton instance of the class.

    # This class method ensures that only one instance of the class is created.
    # If an instance already exists, it returns the existing instance; otherwise,
    # it creates a new instance and returns it.

    # Returns:
    #     cls: The singleton instance of the class.

    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance
    
    def get_connection(self):
        return self.connection
    
