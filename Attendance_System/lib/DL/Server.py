# server.py
from flask import Flask
from flask_cors import CORS
import DB_config as db
import os
from dotenv import load_dotenv

from Login import app as login_app
from employee_dl import app as employee_app

from Salary_dl import app as salary_app

from promotion_dl import app as promotion_app



# Initialize the main Flask app
app = Flask(__name__)
UPLOAD_FOLDER = os.path.join(os.getcwd(), 'images/Uploaded_Pictures')
app.config['Uploaded_Pictures'] = UPLOAD_FOLDER

CORS(app)
# Database configuration
config = db.Configration.get_instance()
connection = config.get_connection()

app.register_blueprint(login_app, url_prefix='/')
app.register_blueprint(employee_app, url_prefix='/')
app.register_blueprint(salary_app, url_prefix='/')
app.register_blueprint(promotion_app, url_prefix='/')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=os.getenv('PORT'))
