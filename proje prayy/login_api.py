from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
import hashlib

app = Flask(__name__)
CORS(app)

# MySQL bağlantısı
conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="021155ys",
    database="worship_db"
)
cursor = conn.cursor()

@app.route('/login', methods=['POST'])
def login():
    email = request.form.get('email')
    password = request.form.get('password')

    hashed_password = hashlib.md5(password.encode()).hexdigest()

    cursor.execute("SELECT * FROM users WHERE email=%s AND password=%s", (email, hashed_password))
    user = cursor.fetchone()

    if user:
        return jsonify({"status": "success", "message": "Login successful."})
    else:
        return jsonify({"status": "error", "message": "Invalid email or password."})

if __name__ == '__main__':
    app.run(port=5000, debug=True)
