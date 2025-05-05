from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from datetime import datetime
import hashlib

app = Flask(__name__)
CORS(app)

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="021155ys",
    database="worship_db"
)
cursor = conn.cursor(dictionary=True)

# ---------------------------------------------
# Kullanıcı Kaydı (Register)
# ---------------------------------------------
@app.route('/register', methods=['POST'])
def register():
    name = request.form.get('name')
    email = request.form.get('email')
    password = request.form.get('password')
    hashed_password = hashlib.md5(password.encode()).hexdigest()
    try:
        cursor.execute("INSERT INTO users (name, email, password) VALUES (%s, %s, %s)", (name, email, hashed_password))
        conn.commit()
        return jsonify({"status": "success", "message": "User registered successfully."})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ---------------------------------------------
# Kullanıcı Giriş (Login)
# ---------------------------------------------
@app.route('/login', methods=['POST'])
def login():
    email = request.form.get('email')
    password = request.form.get('password')
    hashed_password = hashlib.md5(password.encode()).hexdigest()

    cursor.execute("SELECT * FROM users WHERE email = %s AND password = %s", (email, hashed_password))
    user = cursor.fetchone()

    if user:
        return jsonify({"status": "success", "message": "Login successful."})
    else:
        return jsonify({"status": "error", "message": "Invalid email or password."})

# ---------------------------------------------
# Missed Prayers - GET (listele), POST (ekle)
# ---------------------------------------------
@app.route('/missed_prayers', methods=['GET', 'POST'])
def missed_prayers():
    if request.method == 'GET':
        email = request.args.get('email')
        try:
            cursor.execute("""
                SELECT prayer_name, date, completed 
                FROM missed_prayers 
                WHERE email = %s
                ORDER BY created_at DESC
            """, (email,))
            results = cursor.fetchall()
            return jsonify({"missed_prayers": results})
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)})

    elif request.method == 'POST':
        email = request.form.get('email')
        prayer_name = request.form.get('prayer_name')
        date = request.form.get('date')

        try:
            cursor.execute("""
                INSERT INTO missed_prayers (email, prayer_name, date) 
                VALUES (%s, %s, %s)
            """, (email, prayer_name, date))
            conn.commit()
            return jsonify({"status": "success", "message": "Missed prayer saved."})
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)})

# ---------------------------------------------
# Kaza Namazı Tamamlandı (complete = TRUE)
# ---------------------------------------------
@app.route('/complete_missed_prayer', methods=['POST'])
def complete_missed_prayer():
    email = request.form.get('email')
    prayer_name = request.form.get('prayer_name')
    date = request.form.get('date')

    try:
        cursor.execute("""
            UPDATE missed_prayers 
            SET completed = TRUE 
            WHERE email = %s AND prayer_name = %s AND date = %s
        """, (email, prayer_name, date))
        conn.commit()
        rows = cursor.rowcount
        return jsonify({"status": "success", "message": f"{rows} row(s) updated."})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ---------------------------------------------
if __name__ == '__main__':
    app.run(port=5000, debug=True)