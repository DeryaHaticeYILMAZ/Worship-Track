from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from datetime import datetime

app = Flask(__name__)
CORS(app)

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="021155ys",
    database="worship_db"
)
cursor = conn.cursor()

@app.route('/add_missed_prayer', methods=['POST'])
def add_missed_prayer():
    email = request.form.get('email')
    prayer_name = request.form.get('prayer_name')
    date = request.form.get('date')

    try:
        cursor.execute("INSERT INTO missed_prayers (email, prayer_name, date) VALUES (%s, %s, %s)",
                       (email, prayer_name, date))
        conn.commit()
        return jsonify({"status": "success", "message": "Missed prayer saved."})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

if __name__ == '__main__':
    app.run(port=5000, debug=True)
